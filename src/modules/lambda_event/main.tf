###########################################################################
# main.tf – Lambda function + IAM
###########################################################################

data "aws_region" "current" {}

#########################
# IAM role (one per fn)
#########################
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  for_each           = local.valid_functions
  name               = "${var.app_key}-${each.key}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

###########################################################################
# Attach provided policy ARNs
###########################################################################
resource "aws_iam_role_policy_attachment" "lambda_policies" {
  for_each = {
    for item in local.flattened_lambda_policies :
    item.key => item
  }

  role       = aws_iam_role.lambda_exec[each.value.name].name
  policy_arn = each.value.policy

  depends_on = [aws_iam_role.lambda_exec]
}

#########################
# Lambda functions
#########################
resource "aws_lambda_function" "main" {
  for_each = local.valid_functions

  function_name = "${var.app_key}-${each.key}"
  role          = aws_iam_role.lambda_exec[each.key].arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size

  filename         = local.artifact_path[each.key]
  source_code_hash = filesha256(local.artifact_path[each.key])

  environment {
    variables = try(each.value.env_vars, {})
  }
}

# Function URLs for HTTP-triggered lambdas
resource "aws_lambda_function_url" "lambda_url" {
  for_each = local.http_functions

  function_name      = aws_lambda_function.main[each.key].function_name
  authorization_type = "NONE" # change to AWS_IAM if you need signed invocations

  cors {
    allow_methods = ["GET", "POST"]
    allow_origins = ["*"]
  }
}
