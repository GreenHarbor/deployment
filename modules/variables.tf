variable "domain" {
  description = "The url for the application"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "ap-southeast-1"
}