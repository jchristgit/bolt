import logging


def create_logger(name, filemode='a', level=logging.INFO):
    logger = logging.getLogger(name)
    if not len(logger.handlers):
        logger.setLevel(level)
        logger_file = logging.FileHandler(filename=f'logs/{name}.log', mode=filemode)
        logger_file.setFormatter(logging.Formatter('[%(levelname)s] %(asctime)s (%(name)s): %(message)s'))
        logger.addHandler(logger_file)
    return logger
