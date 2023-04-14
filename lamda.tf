# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Sid = ""
      }
    ]
  })
}

# Attach a policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

# Create a Lambda function that triggers the AWS CodePipeline
resource "aws_lambda_function" "codepipeline_trigger_lambda" {
  filename      = "codepipeline_trigger_lambda.zip"
  function_name = "codepipeline-trigger-lambda"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      PIPELINE_NAME = aws_codepipeline.cicd_pipeline.name
    }
  }

  source_code_hash = filebase64sha256("codepipeline_trigger_lambda.zip")
}

# Create a CloudWatch Events rule that triggers the Lambda function
resource "aws_cloudwatch_event_rule" "github_event_rule" {
  name = "github-event-rule"

  description = "Trigger Lambda function when changes are pushed to a GitHub repository"

  event_pattern = jsonencode({
    source      = ["aws.events"]
    detail_type = ["CodePipeline Pipeline Execution State Change"]
    detail      = {
      event   = ["referenceUpdated"]
      referenceName = ["refs/heads/main"]
    #   pipeline = "aws_codepipeline.cicd_pipeline.name"
    #   state    = ["SUCCEEDED"]
      repositoryName = ["Yashgit2000/demo-aws-terraform-cicd"]
    }
  })

  # Associate the CloudWatch Events rule with the Lambda function
  target_id = "github-event-rule-target"
  arn       = aws_lambda_function.codepipeline_trigger_lambda.arn
}
