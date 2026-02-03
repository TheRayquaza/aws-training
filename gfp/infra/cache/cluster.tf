resource "aws_elasticache_cluster" "gfp_cache" {
  cluster_id           = "gfp-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 6379
  security_group_ids   = [aws_security_group.cache_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet.name
}
