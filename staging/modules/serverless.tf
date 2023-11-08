resource "aws_lambda_function" "custom_authorizer" {
  filename      = "../cognito.zip"
  function_name = "customAuthorizerFunction"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"  
  runtime       = "nodejs14.x"    
}

resource "aws_api_gateway_authorizer" "custom_authorizer" {
  name                   = "customAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.api_g.id
  authorizer_uri         = "arn:aws:apigateway:ap-southeast-1:lambda:path/2015-03-31/functions/${aws_lambda_function.custom_authorizer.arn}/invocations"
  authorizer_credentials = aws_iam_role.lambda_exec.arn
  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"

  # ... other configurations ...
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
}
