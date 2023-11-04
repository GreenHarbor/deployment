provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  profile = "cs302"
}


resource "aws_ecrpublic_repository" "my_repo" {
  for_each = var.ecs_tasks

  provider = aws.us_east_1

  repository_name = each.value.name
}

resource "aws_ecs_task_definition" "tasks" {
  for_each = var.ecs_tasks

  family                   = each.value.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64" # or "ARM64" if you are using Graviton processors
  }

  container_definitions = jsonencode([{
    name  = each.value.name
    image = "${aws_ecrpublic_repository.my_repo[each.key].repository_uri}:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])

  tags = {
    key = each.key
  }
}

resource "aws_ecs_service" "my_service" {
  for_each = aws_ecs_task_definition.tasks

  name            = each.value.family
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = each.value.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [aws_subnet.default_subnet.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_tg[each.key].arn
    container_name   = each.value.family
    container_port   = 80
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "greenharbor"
}