resource "aws_s3_bucket" "bronze_bucket" {
  bucket = var.bronze_bucket_name
  versioning {
    enabled = true
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

resource "aws-iam-role" "weather_raw_lambda_role" {
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


resource "aws-iam-policy" "weather_raw_lambda_policy" {
  name = "weather-raw-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:PutObject"
        Effect = "Allow"
        Resource = "arn:aws:s3:::${var.bronze_bucket_name}/*"
      }
    ]
  })
}

resource "aws-iam-role-policy-attachment" "weather_raw_lambda_role_policy_attachment" {
  role = aws_iam_role.weather_raw_lambda_role.name
  policy_arn = aws-iam-policy.weather_raw_lambda_policy.arn
}

resource "aws-lambda-function" "weather_raw_lambda" {
  function_name = "weather-raw-lambda"
  filename = "weather_raw_lambda.zip"
  handler = "weather_raw_lambda.lambda_handler"
  runtime = "python3.12"
  role = aws_iam_role.weather_raw_lambda_role.arn
  timeout = 300
  memory_size = 128
  environment {
    variables = {
      BUCKET_NAME = var.bronze_bucket_name
    }
  }
}