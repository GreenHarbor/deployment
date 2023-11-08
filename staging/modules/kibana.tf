resource "aws_ecs_task_definition" "kb" {
  family                   = "kibana"
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
    name  = "kibana"
    image = "docker.elastic.co/kibana/kibana:8.10.2"
    portMappings = [{
      containerPort = 5601
      hostPort      = 5601
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
        name = "ELASTICSEARCH_URL"
        value = "http://elasticsearch-795535539.ap-southeast-1.elb.amazonaws.com/"
      },
      {
        name= "ELASTICSEARCH_HOSTS",
        value = "http://elasticsearch-795535539.ap-southeast-1.elb.amazonaws.com/"
      }
    ]
  }])
}

resource "aws_ecs_service" "kb_service" {
  name            = "kibana"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.kb.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [aws_subnet.default_subnet.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.kb_tg.arn
    container_name   = "kibana"
    container_port   = 5601
  }
}

resource "aws_lb" "kb_alb" {
  name               = "kibana"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.default_subnet.id, aws_subnet.backup_subnet.id]
  
  // ... other configuration ...
}

resource "aws_lb_target_group" "kb_tg" {
  name     = "kibana"
  port     = 5601
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

resource "aws_lb_listener" "kb_listener" {
  load_balancer_arn = aws_lb.kb_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kb_tg.arn
  }
}
