data "archive_file" "edge" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/edge-headers"
  output_path = "${path.module}/edge-headers.zip"
}

resource "aws_iam_role" "edge" {
  name = "${var.project}-edge-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "edge" {
  function_name    = "${var.project}-sec-headers-${var.environment}"
  role             = aws_iam_role.edge.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.edge.output_path
  source_code_hash = data.archive_file.edge.output_base64sha256
  publish          = true
}
