resource "aws_route53_zone" "primary" {
  name  = var.domain
}

data "aws_route53_zone" "primary" {
  name  = var.domain
}

locals {
  dns_zone_id = data.aws_route53_zone.primary[0].zone_id
}

resource "aws_route53_record" "root" {
  zone_id = local.dns_zone_id
  name    = "${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}
