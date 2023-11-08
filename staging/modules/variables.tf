variable "domain" {
  description = "The url for the application"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "ecs_tasks" {
  description = "Map of ECS tasks"
  default = {
    task1 = {
      name = "food_rescue",
      port = 5000
    },
    task2 = {
      name = "authentication",
      port = 3001
    },
    task3 ={
      name = "workshop",
      port = 8080
    },
    task4 ={
      name = "notification",
      port = 3000
    },
    task5 ={
      name = "logging",
      port = 3000
    },
    task6 ={
      name = "food_rescue_subscription",
      port = 80
    },
    task7 ={
      name = "workshop_participation",
      port = 5000
    }
  }
}

variable "password" {
  description = "The password for the RabbitMQ broker"
  type        = string
}