# main.tf

provider "aws" {
  region = "sa-east-1"
}

resource "random_id" "suffix" {
  byte_length = 2
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "validador_cluster" {
  name = "validador-cluster"
}

# --- IAM Role for ECS Task Execution ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-${random_id.suffix.hex}"

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

# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "validador_logs" {
  name              = "/ecs/validador-${random_id.suffix.hex}"
  retention_in_days = 7
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "validador_task" {
  family                   = "validador-task-${random_id.suffix.hex}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  # Importante: Para produção, use AWS Secrets Manager ou AWS Systems Manager Parameter Store
  # para gerenciar segredos como CLIENT_ID, CLIENT_SECRET e JWT_SECRET.
  # Exemplo com Secrets Manager (não implementado aqui, apenas para referência):
  # secrets = [
  #   {
  #     name      = "CLIENT_ID"
  #     valueFrom = "arn:aws:secretsmanager:sa-east-1:123456789012:secret:my-app-client-id"
  #   },
  #   # ... outros segredos
  # ]
  container_definitions = jsonencode([
    {
      name      = "validador",
      image     = var.image_url,
      essential = true,
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "CLIENT_ID"
          value = "frontend-itau" # Substitua por referência ao Secrets Manager em produção
        },
        {
          name  = "CLIENT_SECRET"
          value = "segredo123" # Substitua por referência ao Secrets Manager em produção
        },
        {
          name  = "JWT_SECRET"
          value = "itau-secret-itau-secret-itau-secret" # Substitua por referência ao Secrets Manager em produção
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.validador_logs.name
          awslogs-region        = "sa-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# --- Application Load Balancer (ALB) ---
resource "aws_lb" "validador_lb" {
  name               = "validador-lb-${random_id.suffix.hex}"
  internal           = false # Set to true if you want an internal load balancer
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "validador-lb"
  }
}

# --- Security Group for ALB ---
resource "aws_security_group" "lb_sg" {
  name        = "validador-lb-sg-${random_id.suffix.hex}"
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Be more restrictive in production, e.g., your office IP or CloudFront
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "validador-lb-sg"
  }
}

# --- Security Group for ECS Fargate Tasks ---
resource "aws_security_group" "ecs_fargate_sg" {
  name        = "validador-ecs-fargate-sg-${random_id.suffix.hex}"
  description = "Allow inbound traffic from ALB to ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080 # Porta da sua aplicação dentro do container
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id] # Permite tráfego apenas do ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permite que o container acesse a internet (para puxar imagem, etc.)
  }

  tags = {
    Name = "validador-ecs-fargate-sg"
  }
}


# --- ALB Target Group ---
resource "aws_lb_target_group" "validador_tg" {
  name        = "validador-tg-${random_id.suffix.hex}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/oauth/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "validador-tg"
  }
}

# --- ALB Listener ---
resource "aws_lb_listener" "validador_listener" {
  load_balancer_arn = aws_lb.validador_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.validador_tg.arn
  }
}

# --- ECS Service ---
resource "aws_ecs_service" "validador_service" {
  name            = "validador-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.validador_cluster.id
  task_definition = aws_ecs_task_definition.validador_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_fargate_sg.id] # Usar o SG dedicado ao Fargate
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.validador_tg.arn
    container_name   = "validador"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.validador_listener]

  tags = {
    Name = "validador-ecs-service"
  }
}

# ------------------------------
# API Gateway - Validador de Senha
# ------------------------------

resource "aws_api_gateway_rest_api" "validador_api" {
  name        = "validador-senha-api"
  description = "API Gateway para o validador de senha integrando com Load Balancer"
}

# --- /oauth resource ---
resource "aws_api_gateway_resource" "oauth" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  parent_id   = aws_api_gateway_rest_api.validador_api.root_resource_id
  path_part   = "oauth"
}

# --- /oauth/token resource ---
resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  parent_id   = aws_api_gateway_resource.oauth.id
  path_part   = "token"
}

# POST method for /oauth/token
resource "aws_api_gateway_method" "post_token" {
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "POST"
  authorization = "NONE"
}

# OPTIONS method for /oauth/token (CORS preflight)
resource "aws_api_gateway_method" "options_token" {
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


# Integration for POST /oauth/token
resource "aws_api_gateway_integration" "token_integration" {
  rest_api_id             = aws_api_gateway_rest_api.validador_api.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.post_token.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  # Considere usar VPC Link para integração privada e mais segura
  # Ex: type = "HTTP_PROXY"
  #     connection_type = "VPC_LINK"
  #     connection_id = aws_api_gateway_vpc_link.validador_vpc_link.id
  uri                     = "http://${aws_lb.validador_lb.dns_name}/oauth/token"
  passthrough_behavior    = "when_no_match" # Permite que o corpo da requisição seja passado
}

# Integration for OPTIONS /oauth/token (CORS preflight)
resource "aws_api_gateway_integration" "options_token_integration" {
  rest_api_id             = aws_api_gateway_rest_api.validador_api.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.options_token.http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

# --- /api resource ---
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  parent_id   = aws_api_gateway_rest_api.validador_api.root_resource_id
  path_part   = "api"
}

# --- /api/validar resource ---
resource "aws_api_gateway_resource" "validar" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "validar"
}

# POST method for /api/validar
resource "aws_api_gateway_method" "post_validar" {
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  resource_id   = aws_api_gateway_resource.validar.id
  http_method   = "POST"
  authorization = "NONE"
}

# OPTIONS method for /api/validar (CORS preflight)
resource "aws_api_gateway_method" "options_validar" {
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  resource_id   = aws_api_gateway_resource.validar.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}


# Integration for POST /api/validar
resource "aws_api_gateway_integration" "validar_integration" {
  rest_api_id             = aws_api_gateway_rest_api.validador_api.id
  resource_id             = aws_api_gateway_resource.validar.id
  http_method             = aws_api_gateway_method.post_validar.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "http://${aws_lb.validador_lb.dns_name}/api/validar"
  passthrough_behavior    = "when_no_match" # Permite que o corpo da requisição seja passado
}

# Integration for OPTIONS /api/validar (CORS preflight)
resource "aws_api_gateway_integration" "options_validar_integration" {
  rest_api_id             = aws_api_gateway_rest_api.validador_api.id
  resource_id             = aws_api_gateway_resource.validar.id
  http_method             = aws_api_gateway_method.options_validar.http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

# --- API Gateway Deployment ---
resource "aws_api_gateway_deployment" "validador_deploy" {
  depends_on = [
    aws_api_gateway_integration.token_integration,
    aws_api_gateway_integration.options_token_integration, # Adicionado
    aws_api_gateway_integration.validar_integration,
    aws_api_gateway_integration.options_validar_integration # Adicionado
  ]
  rest_api_id = aws_api_gateway_rest_api.validador_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.token_integration.id,
      aws_api_gateway_integration.options_token_integration.id,
      aws_api_gateway_integration.validar_integration.id,
      aws_api_gateway_integration.options_validar_integration.id,
      aws_api_gateway_method.post_token.id,
      aws_api_gateway_method.options_token.id,
      aws_api_gateway_method.post_validar.id,
      aws_api_gateway_method.options_validar.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

# --- API Gateway Stage ---
resource "aws_api_gateway_stage" "validador_stage" {
  deployment_id = aws_api_gateway_deployment.validador_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  stage_name    = "dev"
}

# --- Method Responses and Integration Responses for /oauth/token ---

# POST /oauth/token Method Response
resource "aws_api_gateway_method_response" "token_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.post_token.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty" # Pode ser removido se não houver modelos de esquema
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# POST /oauth/token Integration Response
resource "aws_api_gateway_integration_response" "token_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.post_token.http_method
  status_code = aws_api_gateway_method_response.token_post_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }

  # Correção: Mapeia o corpo da resposta da integração para a resposta do método
  response_templates = {
    "application/json" = "$input.body"
  }

  depends_on = [aws_api_gateway_integration.token_integration]
}

# OPTIONS /oauth/token Method Response (CORS preflight)
resource "aws_api_gateway_method_response" "token_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.options_token.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# OPTIONS /oauth/token Integration Response (CORS preflight)
resource "aws_api_gateway_integration_response" "token_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.options_token.http_method
  status_code = aws_api_gateway_method_response.token_options_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }

  depends_on = [aws_api_gateway_integration.options_token_integration]
}

# --- Method Responses and Integration Responses for /api/validar ---

# POST /api/validar Method Response
resource "aws_api_gateway_method_response" "validar_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.validar.id
  http_method = aws_api_gateway_method.post_validar.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty" # Pode ser removido se não houver modelos de esquema
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# POST /api/validar Integration Response
resource "aws_api_gateway_integration_response" "validar_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.validar.id
  http_method = aws_api_gateway_method.post_validar.http_method
  status_code = aws_api_gateway_method_response.validar_post_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }

  # Correção: Mapeia o corpo da resposta da integração para a resposta do método
  response_templates = {
    "application/json" = "$input.body"
  }

  depends_on = [aws_api_gateway_integration.validar_integration]
}

# OPTIONS /api/validar Method Response (CORS preflight)
resource "aws_api_gateway_method_response" "validar_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.validar.id
  http_method = aws_api_gateway_method.options_validar.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# OPTIONS /api/validar Integration Response (CORS preflight)
resource "aws_api_gateway_integration_response" "validar_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.validar.id
  http_method = aws_api_gateway_method.options_validar.http_method
  status_code = aws_api_gateway_method_response.validar_options_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }

  depends_on = [aws_api_gateway_integration.options_validar_integration]
}