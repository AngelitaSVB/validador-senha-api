
provider "aws" {
  region = "sa-east-1"
}

module "validador_api" {
  source  = "terraform-aws-modules/ecs/aws"

  name = "validador-api"

  container_definitions = jsonencode([
    {
      name      = "validador"
      image     = var.image_url
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ],
      environment = [
        { name = "CLIENT_ID", value = var.client_id },
        { name = "CLIENT_SECRET", value = var.client_secret }
      ]
    }
  ])

  capacity_provider_strategies = [{
    capacity_provider = "FARGATE"
    weight            = 1
  }]

  create_task_exec_role  = true
  create_task_definition = true

  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids
  assign_public_ip  = true
  desired_count     = 1
  launch_type       = "FARGATE"
  cpu               = 256
  memory            = 512
  enable_alb        = true
  alb_listener_port = 80
}
