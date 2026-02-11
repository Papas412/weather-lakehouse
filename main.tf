resource "aws_s3_bucket" "bronze_bucket" {
  bucket = var.bronze_bucket_name
}

resource "aws_s3_bucket_versioning" "bronze_bucket_versioning" {
  bucket = aws_s3_bucket.bronze_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bronze_bucket_lifecycle" {
  bucket = aws_s3_bucket.bronze_bucket.id

  rule {
    id     = "raw"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_iam_role" "weather_raw_lambda_role" {
  name = "weather-raw-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_policy" "weather_raw_lambda_policy" {
  name = "weather-raw-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.bronze_bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "weather_raw_lambda_role_policy_attachment" {
  role       = aws_iam_role.weather_raw_lambda_role.name
  policy_arn = aws_iam_policy.weather_raw_lambda_policy.arn
}

data "archive_file" "weather_raw_lambda" {
  type        = "zip"
  source_dir  = "./weather_raw_lambda"
  output_path = "weather_raw_lambda.zip"
}

resource "aws_lambda_function" "weather_raw_lambda" {
  function_name = "weather-raw-lambda"
  filename      = data.archive_file.weather_raw_lambda.output_path
  handler       = "weather_raw_lambda.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.weather_raw_lambda_role.arn
  timeout       = 300
  memory_size   = 128
  environment {
    variables = {
      BUCKET_NAME = var.bronze_bucket_name
    }
  }
}

resource "aws_cloudwatch_event_rule" "weather_raw_lambda_event_rule" {
  name        = "weather-raw-lambda-event-rule"
  description = "Event rule for weather raw lambda"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "weather_raw_lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.weather_raw_lambda_event_rule.name
  arn       = aws_lambda_function.weather_raw_lambda.arn
  target_id = "weather-raw-lambda-event-target"
}

resource "aws_lambda_permission" "weather_raw_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_raw_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weather_raw_lambda_event_rule.arn
}