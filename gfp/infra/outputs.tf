# Redis outputs

output "redis_endpoint" {
  description = "The endpoint of the Redis cluster"
  value       = module.cache-service.redis_endpoint
}

## Backend outputs

output "backend_ecr_repository_url" {

  value = module.backend-service.backend_ecr_repository_url
}

output "backend_lb_dns" {
  description = "The DNS name of the backend load balancer"
  value       = module.backend-service.backend_lb_dns
}

## Frontend outputs

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = module.front-service.cloudfront_domain_name
}
