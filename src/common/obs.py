import json
import logging


def log_json(logger: logging.Logger, event: str, **fields: object) -> None:
    """Emit a single structured (JSON) log line for CloudWatch Logs Insights.

    Each line carries an ``event`` name plus arbitrary fields (e.g. a run/request
    correlation id and per-run counts), so logs are queryable instead of free text.
    """
    logger.info(json.dumps({"event": event, **fields}, default=str))
