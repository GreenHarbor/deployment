variable "profile" {
  description = "The profile for AWS CLI"
  type        = string
  default     = "default"
}

variable "domain" {
  description = "The url for the application"
  type        = string
  default = "greenharbor.org"
}

variable "password" {
  description = "The password for the RabbitMQ broker"
  type        = string
}