variable "domain" {
  description = "The url for the application"
  type        = string
  default = "greenharbor.org"
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
      name = "food_rescue"
    },
    task2 = {
      name = "authentication"
    },
    task3 ={
      name = "workshop"
    },
    task4 ={
      name = "notification"
    },
    task5 ={
      name = "logging"
    }
  }
}