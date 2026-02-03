resource "aws_subnet" "cache_subnet_a" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "Cache-Subnet-A"
  }
}

resource "aws_subnet" "cache_subnet_b" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "${var.region}b"
  tags = {
    Name = "Cache-Subnet-B"
  }
}

resource "aws_elasticache_subnet_group" "cache_subnet" {
  name       = "cache-subnet-group"
  subnet_ids = [aws_subnet.cache_subnet_a.id, aws_subnet.cache_subnet_b.id]

  tags = {
    Name = "Cache Subnet Group"
  }
}
