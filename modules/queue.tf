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
  data               = file("path_to_configuration_file.xml") # If you have a custom configuration file
}
