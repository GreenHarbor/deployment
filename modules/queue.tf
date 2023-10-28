resource "aws_mq_broker" "rabbitmq_broker" {
  broker_name = "my-rabbitmq-broker"
  engine_type = "RabbitMQ"
  engine_version = "3.8.6"

  configuration {
    id       = aws_mq_configuration.rabbitmq_configuration.id
    revision = aws_mq_configuration.rabbitmq_configuration.latest_revision
  }

  host_instance_type = "mq.m5.large"
  publicly_accessible = true

  user {
    username = "admin"
    password = var.password
  }
}

resource "aws_mq_configuration" "rabbitmq_configuration" {
  engine_type        = "RabbitMQ"
  engine_version     = "3.8.6" # Use the desired version
  name               = "my-rabbitmq-configuration"
  description        = "My RabbitMQ configuration"
    data = <<DATA
# Default RabbitMQ delivery acknowledgement timeout is 30 minutes in milliseconds
consumer_timeout = 1800000
DATA
}
