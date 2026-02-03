resource "aws_elasticache_cluster" "stats_cache" {
  cluster_id           = "city-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 6379
  security_group_ids   = [aws_security_group.cache_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet.name
}

resource "aws_elasticache_subnet_group" "cache_subnet" {
  name       = "cache-subnet-group"
  subnet_ids = [aws_subnet.main.id]

  tags = {
    Name = "Cache Subnet Group"
  }
}

resource "aws_security_group" "cache_sg" {
  name        = "cache_sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
    security_groups = [aws_security_group.lambda_sg.id]
  }
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.stats_cache.cluster_address
}
