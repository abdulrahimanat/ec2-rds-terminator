# Cloudwatch event rule
resource "aws_cloudwatch_event_rule" "ec2-rds-terminate-event" {
  name                = "${var.resource_name_prefix}ec2-rds-terminate-event"
  description         = "ec2-rds-terminate-event"
  schedule_expression = var.schedule_terminate_expression
  depends_on          = [aws_lambda_function.scheduler_terminate_lambda]
}

# Cloudwatch event target
resource "aws_cloudwatch_event_target" "ec2-rds-terminate-event-lambda-target" {
  target_id = "ec2-rds-terminate-event-lambda-target"
  rule      = aws_cloudwatch_event_rule.ec2-rds-terminate-event.name
  arn       = aws_lambda_function.scheduler_terminate_lambda.arn
}

# IAM Role for Lambda function
resource "aws_iam_role" "scheduler_terminate_lambda" {
  name               = "${var.resource_name_prefix}scheduler_terminate_lambda"
  permissions_boundary = var.permissions_boundary != "" ? var.permissions_boundary : ""
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "ec2-rds-scheduler" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:CreateTags",
      "ec2:TerminateInstances",
      "rds:DescribeDBInstances",
      "rds:DeleteDBInstance",
      "rds:DescribeDBClusters",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:ListTagsForResource",
      "rds:AddTagsToResource",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ec2-rds-scheduler" {
  name   = "${var.resource_name_prefix}ec2-rds-scheduler"
  path   = "/"
  policy = data.aws_iam_policy_document.ec2-rds-scheduler.json
}

resource "aws_iam_role_policy_attachment" "ec2-rds-scheduler" {
  role       = aws_iam_role.scheduler_terminate_lambda.name
  policy_arn = aws_iam_policy.ec2-rds-scheduler.arn
}

## create custom role

resource "aws_iam_policy" "scheduler_aws_lambda_basic_execution_role" {
  name        = "${var.resource_name_prefix}ec2_rds_terminator_aws_lambda__execution_role"
  path        = "/"
  description = "AWSLambdaBasicExecutionRole"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "basic-exec-role" {
  role       = aws_iam_role.scheduler_terminate_lambda.name
  policy_arn = aws_iam_policy.scheduler_aws_lambda_basic_execution_role.arn
}

# AWS Lambda need a zip file
data "archive_file" "aws-scheduler" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/aws-scheduler.zip"
}

# AWS Lambda function
resource "aws_lambda_function" "scheduler_terminate_lambda" {
  filename         = data.archive_file.aws-scheduler.output_path
  function_name    = "${var.resource_name_prefix}ec2-rds-terminator"
  role             = aws_iam_role.scheduler_terminate_lambda.arn
  handler          = "ec2-rds-terminate.handler"
  runtime          = "python3.7"
  timeout          = 300
  source_code_hash = data.archive_file.aws-scheduler.output_base64sha256
  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler_terminate_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2-rds-terminate-event.arn
}
