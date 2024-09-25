# Configure the AWS provider
# provider "aws" {
#   region = "ap-southeast-1"
# }

locals {
  common_tags = { Name = "tsanghan-ce6" }
}
# Define variables
variable "stage" {
  type    = string
  default = "dev"
}

resource "random_id" "id" {
  keepers = {
    timestamp = timestamp() # force change on every execution
  }
  byte_length = 8
}

resource "aws_secretsmanager_secret" "tsanghan-ce6-secret" {
  name                    = "dev/tsanghan-ce6/secrets-${random_id.id.dec}"
  description             = "tsanghan-ce6 Secrets ${random_id.id.dec}"
  recovery_window_in_days = 0
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "tsanghan-ce6-secret" {
  secret_id     = aws_secretsmanager_secret.tsanghan-ce6-secret.id
  secret_string = jsonencode({ tsanghan-ce6-secrets = "staff-koala-${random_id.id.dec}" })
}


# IAM Role for Lambda
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role_${var.stage}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# IAM Policy for DynamoDB and SQS access
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.tsanghan-ce6-secret.id
    ]
  }

  # Basic Lambda execution permissions
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

# Attach IAM Policy to the Role
resource "aws_iam_role_policy" "lambda_policy_attachment" {
  name   = "lambda_policy_${var.stage}"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

data "archive_file" "lambda_zip" {
  type = "zip"

  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function-${random_id.id.dec}.zip"
}

# AWS Lambda Function
resource "aws_lambda_function" "lambda_function" {
  function_name = "tsanghan-ce6-secrets-lambda-tofu-${var.stage}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  # Package your Python code as a zip file named 'lambda_function.zip'
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      SECRET_ID = aws_secretsmanager_secret.tsanghan-ce6-secret.id
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy_attachment
  ]
}

# # API Gateway (HTTP API)
# resource "aws_apigatewayv2_api" "http_api" {
#   name          = "tsanghan-ce6-http-api-${var.stage}"
#   protocol_type = "HTTP"
# }

# # Lambda Integration with API Gateway
# resource "aws_apigatewayv2_integration" "lambda_integration" {
#   api_id                 = aws_apigatewayv2_api.http_api.id
#   integration_type       = "AWS_PROXY"
#   integration_uri        = aws_lambda_function.lambda_function.invoke_arn
#   integration_method     = "POST"
#   payload_format_version = "2.0"
# }

# # API Gateway Route
# resource "aws_apigatewayv2_route" "lambda_route" {
#   api_id    = aws_apigatewayv2_api.http_api.id
#   route_key = "POST /"

#   target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
# }

# # API Gateway Stage
# resource "aws_apigatewayv2_stage" "default_stage" {
#   api_id      = aws_apigatewayv2_api.http_api.id
#   name        = "$default"
#   auto_deploy = true
# }

# # Permission for API Gateway to Invoke Lambda
# resource "aws_lambda_permission" "apigw_lambda_permission" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda_function.function_name
#   principal     = "apigateway.amazonaws.com"

#   source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
# }
