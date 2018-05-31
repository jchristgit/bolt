from functools import wraps


def async_cache():
    """
    Cache implementation for use with coroutines.
    Assigns a `cache` attribute to the decorated function to allow clearing from the outside.
    """

    def decorator(function):
        # Assign the cache to decorated function so we can clear it from outside if necessary.
        function.cache = {}

        @wraps(function)
        async def wrapper(*args):
            try:
                return function.cache[args]
            except KeyError:
                function.cache[args] = await function(*args)
                return function.cache[args]
        return wrapper
    return decorator
