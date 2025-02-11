def benchmark(logger):
    def actual_decorator(func):
        def wrapper(*args, **kwargs):
            start = time.time()
            return_value = func(*args, **kwargs)
            end = time.time()
            logger.info(
                f"Execution time {func.__name__!r} is {end - start:2.2f} sec",
                extra=getattr(args[0], "extra_log_data", None),
            )
            return return_value

        return wrapper

    return actual_decorator
