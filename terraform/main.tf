provider "aws" {
  region = "sa-east-1"
}

resource "random_id" "suffix" {
  byte_length = 2
}

resource "aws_ecs_cluster" "validador_cluster" {
  name = "validador-cluster"
}

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

resource "aws_cloudwatch_log_group" "validador_logs" {
  name              = "/ecs/validador-${random_id.suffix.hex}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "validador_task" {
  family                   = "validador-task-${random_id.suffix.hex}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name        = "validador",
      image       = var.image_url,
      essential   = true,
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080,
          protocol      = "tcp"
        }
      ],
      environment = [
        { name = "CLIENT_ID",       value = "frontend-itau" },
        { name = "CLIENT_SECRET", value = "segredo123" },
        { name = "JWT_SECRET",      value = "itau-secret-itau-secret-itau-secret" }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/validador-${random_id.suffix.hex}",
          awslogs-region        = "sa-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_lb" "validador_lb" {
  name               = "validador-lb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids
}

resource "aws_security_group" "lb_sg" {
  name        = "validador-lb-sg-${random_id.suffix.hex}"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
  name            = "validador-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.validador_cluster.id
  task_definition = aws_ecs_task_definition.validador_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.lb_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.validador_tg.arn
    container_name   = "validador"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.validador_listener]
}

resource "aws_api_gateway_rest_api" "validador_api" {
  name        = "validador-senha-api"
  description = "API Gateway para o validador de senha integrando com Load Balancer"
}

resource "aws_api_gateway_resource" "oauth" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  parent_id   = aws_api_gateway_rest_api.validador_api.root_resource_id
  path_part   = "oauth"
}

resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  parent_id   = aws_api_gateway_resource.oauth.id
  path_part   = "token"
}

resource "aws_api_gateway_method" "post_token" {
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "token_integration" {
  rest_api_id             = aws_api_gateway_rest_api.validador_api.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.post_token.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "http://${aws_lb.validador_lb.dns_name}/oauth/token"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"

  request_parameters = {
    "integration.request.header.Accept" = "'application/json'"
  }
}

# --- Adição para o método OPTIONS em /oauth/token ---
resource "aws_api_gateway_method" "options_token" {
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_token_integration" {
  rest_api_id             = aws_api_gateway_rest_api.validador_api.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.options_token.http_method
  type                    = "MOCK"
  passthrough_behavior    = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  # A integração mock não precisa de depends_on do método OPTIONS,
  # mas a resposta da integração mock pode depender do método.
  depends_on = [
    aws_api_gateway_method.options_token # Garante que o método OPTIONS seja criado primeiro
  ]
}

resource "aws_api_gateway_method_response" "options_token_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
  depends_on = [
    aws_api_gateway_method.options_token # Garante que o método OPTIONS seja criado primeiro
  ]
}

resource "aws_api_gateway_integration_response" "options_token_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
  }
  depends_on = [
    aws_api_gateway_integration.options_token_integration # Garante que a integração OPTIONS esteja criada
  ]
}
# --- Fim da adição para /oauth/token ---

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  parent_id   = aws_api_gateway_rest_api.validador_api.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "validar" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "validar"
}

resource "aws_api_gateway_method" "post_validar" {
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  resource_id   = aws_api_gateway_resource.validar.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "validar_integration" {
  rest_api_id             = aws_api_gateway_rest_api.validador_api.id
  resource_id             = aws_api_gateway_resource.validar.id
  http_method             = aws_api_gateway_method.post_validar.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "http://${aws_lb.validador_lb.dns_name}/api/validar"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"

  request_parameters = {
    "integration.request.header.Accept" = "'application/json'"
  }
}

resource "aws_api_gateway_deployment" "validador_deploy" {
  depends_on = [
    aws_api_gateway_integration.token_integration,
    aws_api_gateway_method_response.token_response,
    aws_api_gateway_integration_response.token_integration_response,

    aws_api_gateway_method.options_token,
    aws_api_gateway_integration.options_token_integration,
    aws_api_gateway_method_response.options_token_response,
    aws_api_gateway_integration_response.options_token_integration_response,

    aws_api_gateway_integration.validar_integration,
    aws_api_gateway_method_response.validar_response,
    aws_api_gateway_integration_response.validar_integration_response,

    aws_api_gateway_method.options_validar,
    aws_api_gateway_integration.options_validar_integration,
    aws_api_gateway_method_response.options_validar_response,
    aws_api_gateway_integration_response.options_validar_integration_response
  ]
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  triggers = {
    redeployment = timestamp()
  }
}

resource "aws_api_gateway_stage" "validador_stage" {
  deployment_id = aws_api_gateway_deployment.validador_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  stage_name    = "dev"
}

resource "aws_api_gateway_method" "options_validar" {
  rest_api_id   = aws_api_gateway_rest_api.validador_api.id
  resource_id   = aws_api_gateway_resource.validar.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_validar_integration" {
  rest_api_id             = aws_api_gateway_rest_api.validador_api.id
  resource_id             = aws_api_gateway_resource.validar.id
  http_method             = aws_api_gateway_method.options_validar.http_method
  type                    = "MOCK"
  passthrough_behavior    = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  depends_on = [
    aws_api_gateway_method.options_validar # Garante que o método OPTIONS seja criado primeiro
  ]
}

resource "aws_api_gateway_method_response" "options_validar_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.validar.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
  depends_on = [
    aws_api_gateway_method.options_validar # Garante que o método OPTIONS seja criado primeiro
  ]
}

resource "aws_api_gateway_integration_response" "options_validar_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.validar.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
  }
  depends_on = [
    aws_api_gateway_integration.options_validar_integration # Garante que a integração OPTIONS esteja criada
  ]
}

# ======= BLOCO ADICIONADO: Resposta do método /oauth/token (original, sem alterações aqui) =======
resource "aws_api_gateway_method_response" "token_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.post_token.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true
  }
  # Adicionando dependência para garantir que o método POST_TOKEN exista
  depends_on = [
    aws_api_gateway_method.post_token
  ]
}

resource "aws_api_gateway_integration_response" "token_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.post_token.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Headers" = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST'"
  }

  depends_on = [
    aws_api_gateway_integration.token_integration # Já existia
  ]
}

# ======= BLOCO ADICIONADO: Resposta do método /api/validar (original, sem alterações aqui) =======
resource "aws_api_gateway_method_response" "validar_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.validar.id
  http_method = aws_api_gateway_method.post_validar.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true
  }
  # Adicionando dependência para garantir que o método POST_VALIDAR exista
  depends_on = [
    aws_api_gateway_method.post_validar
  ]
}

resource "aws_api_gateway_integration_response" "validar_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.validador_api.id
  resource_id = aws_api_gateway_resource.validar.id
  http_method = aws_api_gateway_method.post_validar.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Headers" = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST'"
  }

  depends_on = [
    aws_api_gateway_integration.validar_integration # Já existia
  ]
}