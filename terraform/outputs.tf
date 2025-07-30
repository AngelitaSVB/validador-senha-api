output "alb_dns_name" {
  description = "DNS público do Load Balancer"
  value       = aws_lb.validador_lb.dns_name
}

output "ecs_service_name" {
  description = "Nome do serviço ECS"
  value       = aws_ecs_service.validador_service.name
}

output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.validador_cluster.name
}

output "log_group_name" {
  description = "Grupo de logs no CloudWatch"
  value       = aws_cloudwatch_log_group.validador_logs.name
}
