resource "aws_ecs_task_definition" "es" {
  family                   = "elasticsearch"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" # or "ARM64" if you are using Graviton processors
  }

  container_definitions = jsonencode([{
    name  = "elasticsearch"
    image = "docker.elastic.co/elasticsearch/elasticsearch:8.10.2"
    portMappings = [{
      containerPort = 9200
      hostPort      = 9200
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
        "awslogs-region"        = "ap-southeast-1" # Replace with your AWS region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    environment = [
      {
        name = "discovery.type"
        value = "single-node"
      },
      {
        name= "ES_JAVA_OPTS",
        value = "-Xms256m -Xmx256m"
      },
      {
        name = "xpack.security.enabled"
        value = "false"
      },
      {
        name = "xpack.security.enrollment.enabled"
        value = "false"
      }
    ]
  }])
}

resource "aws_ecs_service" "es_service" {
  name            = "elasticsearch"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.es.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [aws_subnet.default_subnet.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.es_tg.arn
    container_name   = "elasticsearch"
    container_port   = 9200
  }
}

resource "aws_lb" "es_alb" {
  name               = "elasticsearch"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.default_subnet.id, aws_subnet.backup_subnet.id]
  
  // ... other configuration ...
}

resource "aws_lb_target_group" "es_tg" {
  name     = "elasticsearch"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = aws_vpc.default_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 120
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 300
  }

  // ... other configuration ...
}

resource "aws_lb_listener" "es_listener" {
  load_balancer_arn = aws_lb.es_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.es_tg.arn
  }
}
