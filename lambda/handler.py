import json
import logging
import os
from urllib.parse import unquote_plus

import boto3

log = logging.getLogger()
log.setLevel(logging.INFO)
s3 = boto3.client("s3")
sns = boto3.client("sns")
TOPIC_ARN = os.environ["TOPIC_ARN"]
MAX_BYTES = int(os.environ.get("MAX_BYTES", "5242880"))
ALLOWED_EXTENSIONS = (".pdf", ".jpg", ".png")


def lambda_handler(event, context):
    # Batch size is 1, so an unhandled exception retries this SQS message.
    for sqs_record in event["Records"]:
        envelope = json.loads(sqs_record["body"])
        for s3_record in envelope.get("Records", []):
            bucket = s3_record["s3"]["bucket"]["name"]
            key = unquote_plus(s3_record["s3"]["object"]["key"])

            # Ignore any unexpected event outside our upload prefix.
            if not key.startswith("uploads/"):
                continue

            # HEAD returns metadata without downloading the document.
            metadata = s3.head_object(Bucket=bucket, Key=key)
            size = metadata["ContentLength"]
            valid_type = key.lower().endswith(ALLOWED_EXTENSIONS)
            status = "SUCCESS" if valid_type and 0 < size <= MAX_BYTES else "REJECTED"

            message = (
                f"File: {key}\n"
                f"Bucket: {bucket}\n"
                f"Size: {size} bytes\n"
                f"Status: {status}\n"
                "Validation: extension is PDF/JPG/PNG and size is 1 byte to 5 MiB"
            )
            sns.publish(
                TopicArn=TOPIC_ARN,
                Subject=f"Document validation: {status}",
                Message=message,
            )
            log.info("Processed bucket=%s key=%s status=%s", bucket, key, status)

    return {"statusCode": 200, "message": "SQS batch completed"}
