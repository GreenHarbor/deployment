resource "aws_waf_web_acl" "waf" {
  name        = "greenharbor-waf"
  metric_name = "greenharbor-waf"

  default_action {
    type = "ALLOW"
  }

}

resource "aws_waf_web_acl_association" "wafrule" {
  resource_arn = aws_cloudfront_distribution.cloudfront.arn
  web_acl_id   = aws_waf_web_acl.waf.id
}
