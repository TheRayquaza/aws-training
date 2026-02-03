output "backend_lb_dns" {
  value = aws_lb.backend_lb.dns_name
}

output "backend_cluster_name" {
  value = aws_ecs_cluster.backend_cluster.name
}

output "backend_service_name" {
  value = aws_ecs_service.backend_service.name
}

output "backend_security_group_id" {
  value = aws_security_group.backend_sg.id
}

output "lb_security_group_id" {
  value = aws_security_group.lb_sg.id
}

output "backend_ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}
