import boto3
import datetime
import urllib.request
import json
import os

BUCKET_NAME = os.environ["BUCKET_NAME"]

s3 = boto3.client("s3")

def lambda_handler(event, context):
    """
    Lambda function to fetch weather data from OpenWeatherMap API and save to S3
    """
    url = "https://api.open-meteo.com/v1/forecast?latitude=37.9838,51.5085,40.7143,-33.9258&longitude=23.7278,-0.1257,-74.006,18.4232&current=temperature_2m,precipitation,wind_speed_10m,relative_humidity_2m"

    with urllib.request.urlopen(url) as response:
        raw_data = json.loads(response.read().decode())

    raw_data["extraction_timestamp"] = datetime.datetime.now().isoformat()

    filename = f"weather_raw_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=f"raw/{filename}",
        Body=json.dumps(raw_data).encode(),
        ContentType="application/json"
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Weather data fetched and saved to S3",
            "filename": filename
        })
    }