
output "alb_dns_name" {
  description = "DNS público do Load Balancer"
  value       = aws_lb.validador_lb.dns_name
}
