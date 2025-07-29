provider "aws" {
  region = "sa-east-1"
}

resource "aws_ecs_cluster" "validador_cluster" {
  name = "validador-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# NOVO: grupo de log para CloudWatch
resource "aws_cloudwatch_log_group" "validador_logs" {
  name              = "/ecs/validador"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "validador_task" {
  family                   = "validador-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "validador"
      image     = var.image_url
      essential = true
      portMappings = [{
        containerPort = 8080,
        hostPort      = 8080,
        protocol      = "tcp"
      }],
      environment = [
        { name = "CLIENT_ID", value = var.client_id },
        { name = "CLIENT_SECRET", value = var.client_secret }
      ],
      # NOVO: Configuração dos logs
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/validador",
          awslogs-region        = "sa-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_lb" "validador_lb" {
  name               = "validador-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids
}

resource "aws_security_group" "lb_sg" {
  name        = "validador-lb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "validador_tg" {
  name         = "validador-tg"
  port         = 8080
  protocol     = "HTTP"
  vpc_id       = var.vpc_id
  target_type  = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "validador_listener" {
  load_balancer_arn = aws_lb.validador_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.validador_tg.arn
  }
}

resource "aws_ecs_service" "validador_service" {
  name            = "validador-service"
  cluster         = aws_ecs_cluster.validador_cluster.id
  task_definition = aws_ecs_task_definition.validador_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.lb_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.validador_tg.arn
    container_name   = "validador"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.validador_listener]
}
