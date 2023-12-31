resource "aws_wafv2_web_acl" "waf" {
  name        = "greenharbor-waf"
  scope       = "REGIONAL"
  description = "Description for your WebACL"
  
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "greenharbor-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "wafrule" {
  resource_arn = "${aws_api_gateway_rest_api.api_g.arn}/stages/${aws_api_gateway_stage.example.stage_name}"  # ARN of the resource to associate with, e.g., an Application Load Balancer
  web_acl_arn  = aws_wafv2_web_acl.waf.arn   # ARN of the WAFv2 WebACL
}
