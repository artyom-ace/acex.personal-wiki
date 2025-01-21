from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from redis.asyncio import Redis, from_url

from app.core.settings import settings


@asynccontextmanager
async def client() -> AsyncIterator[Redis]:  # type: ignore
    client_ = from_url(settings.REDIS_URL)
    yield client_
    await client_.close()
