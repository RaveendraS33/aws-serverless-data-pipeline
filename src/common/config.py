import os

PROJECT_NAME = "aws-serverless-data-pipeline"
USGS_QUERY_URL = "https://earthquake.usgs.gov/fdsnws/event/1/query"


def required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value
