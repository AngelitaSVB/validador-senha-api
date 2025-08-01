from diagrams import Diagram, Cluster
from diagrams.aws.network import APIGateway, ELB
from diagrams.aws.compute import ECS
from diagrams.aws.management import Cloudwatch
from diagrams.custom import Custom

with Diagram("Arquitetura Backend - Validador de Senha", 
             filename="infraestrutura_validador_de_senha", 
             direction="TB"):

    usuario = Custom("Usuário Final\n(Cliente Angular)", "./user.png")  

    with Cluster("Provisionamento com Terraform"):
        terraform = Custom("Terraform\n(IaC)", "./terraform.png") 

    with Cluster("Infra AWS"):
        api_gw = APIGateway("API Gateway\nExposição segura dos endpoints")
        alb = ELB("Load Balancer (ALB)\nvalidador-lb")
        cloudwatch = Cloudwatch("CloudWatch Logs\nMonitoramento")

        with Cluster("ECS Fargate\nvalidador-cluster"):
            ecs_service = ECS("validador-service")
            spring_app = Custom("Spring Boot App\nAuthController + PasswordController", "./springboot.png")

            ecs_service >> spring_app
            spring_app >> cloudwatch

        alb >> ecs_service
        api_gw >> alb

    usuario >> api_gw
    terraform >> api_gw
    terraform >> ecs_service
