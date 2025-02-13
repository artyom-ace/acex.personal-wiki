### https://loguru.readthedocs.io/en/stable/overview.html
### https://opentelemetry-python.readthedocs.io/en/stable/examples/

# ----------------------------------------------------------------------------------------------------------------------
# loguru + opentelemetry
# ----------------------------------------------------------------------------------------------------------------------

# logger.py ------------------------------------------------------------------------------------------------------------

from loguru import logger

SERVICE_NAME: str = "app"
LOGGER_FILENAME: str = f"/var/tmp/app.{SERVICE_NAME}.log"
LOGGER_FORMAT: str = "{time:YYYY-MM-DD HH:mm:ss.SSS} | {level: <8} | {name}:{function}:{line} - {message} {extra}"

# default loguru logger
logger.remove()
logger.add(sys.stdout, format=LOGGER_FORMAT, enqueue=True)
logger.add(LOGGER_FILENAME, format=LOGGER_FORMAT, enqueue=True)

# otel loguru logger
otel_logger = logger.patch(lambda record: record.update(otel=True))
# record["extra"] is a logger.bind(x= , y= , z= ) parameters
init_otel_logger(SERVICE_NAME, otel_logger, async_=True, filter=lambda record: "otel" in record)


# loguru_otel.py -------------------------------------------------------------------------------------------------------

import time
from collections.abc import Callable, Coroutine
from typing import Any, Union

from opentelemetry import _logs, trace
from opentelemetry._logs import std_to_otel
from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter
from opentelemetry.sdk._logs import LoggerProvider
from opentelemetry.sdk._logs._internal import LogRecord
from opentelemetry.sdk._logs.export import SimpleLogRecordProcessor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.trace import TraceFlags


def _otel_sink(
    logger_provider: LoggerProvider,
    resource: Resource,
) -> Callable[["LoguruMessage"], Coroutine[None, None, None]]:
    async def wrapped(msg: "LoguruMessage") -> None:
        if log_extra := msg.record["extra"]:
            log_extra = log_extra if isinstance(log_extra, dict) else {"extra": str(msg.record["extra"])}

        otel_record = LogRecord(
            timestamp=time.time_ns(),
            trace_id=trace.get_current_span().get_span_context().trace_id,
            span_id=trace.get_current_span().get_span_context().span_id,
            trace_flags=TraceFlags.DEFAULT,
            severity_number=std_to_otel(msg.record["level"].no),
            severity_text=msg.record["level"].name,
            body=msg.strip(),
            attributes=log_extra,
            resource=resource,
        )
        logger_provider.get_logger(f"{msg.record['file'].path}:{msg.record['function']}").emit(otel_record)

    return wrapped


def _otel_sink_sync(
    logger_provider: LoggerProvider,
    resource: Resource,
) -> Callable[["LoguruMessage"], None]:
    def wrapped(msg: "LoguruMessage") -> None:
        if log_extra := msg.record["extra"]:
            log_extra = log_extra if isinstance(log_extra, dict) else {"extra": str(msg.record["extra"])}

        otel_record = LogRecord(
            timestamp=time.time_ns(),
            trace_id=trace.get_current_span().get_span_context().trace_id,
            span_id=trace.get_current_span().get_span_context().span_id,
            trace_flags=TraceFlags.DEFAULT,
            severity_number=std_to_otel(msg.record["level"].no),
            severity_text=msg.record["level"].name,
            body=msg.strip(),
            attributes=log_extra,
            resource=resource,
        )
        logger_provider.get_logger(f"{msg.record['file'].path}:{msg.record['function']}").emit(otel_record)

    return wrapped


def init_otel_logger(
    service_name: str,
    logger: "LoguruLogger",
    *,
    resource: Resource | None = None,
    level: str | None = None,
    format_: Union[str, "LoguruFormatFunction"] | None = None,
    async_: bool = True,
    **kwargs: Any,
) -> None:
    """
    Uses standard OpenTelemetry environment variables discribed in `OTLPLogExporter` to configure OTLP exporter.
    """
    _resource = Resource(attributes={SERVICE_NAME: service_name}) if resource is None else resource
    trace_provider = TracerProvider(resource=_resource)
    trace.set_tracer_provider(trace_provider)

    logger_provider = LoggerProvider(resource=_resource)
    logger_provider.add_log_record_processor(SimpleLogRecordProcessor(OTLPLogExporter()))
    _logs.set_logger_provider(logger_provider)

    if format_ is None:
        format_ = "{message}"

    if level is None:
        level = "INFO"

    if async_:
        logger.add(_otel_sink(logger_provider, _resource), format=format_, level=level, **kwargs)
    else:
        logger.add(_otel_sink_sync(logger_provider, _resource), format=format_, level=level, **kwargs)
