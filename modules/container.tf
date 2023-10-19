resource "aws_ecr_repository" "my_repo" {
  for_each = var.ecs_tasks

  name = each.value.name
}

resource "aws_ecs_task_definition" "tasks" {
  for_each = var.ecs_tasks

  family                   = each.value.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = each.value.name
    image = "${aws_ecr_repository.my_repo[each.value.name].repository_url}:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

resource "aws_ecs_service" "my_service" {
  for_each = aws_ecs_task_definition.tasks

  name            = each.value.name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = each.value.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "greenharbor"
}