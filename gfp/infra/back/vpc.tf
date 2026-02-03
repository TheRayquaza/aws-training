# GW

resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id
  tags   = { Name = "main-igw" }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_backend_subnet_a.id
  tags          = { Name = "main-nat-gw" }

  depends_on = [aws_internet_gateway.igw]
}

# Public
resource "aws_subnet" "public_backend_subnet_a" {
  vpc_id = var.vpc_id
  cidr_block = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "GFP-Backend-Subnet-A"
  }
}

resource "aws_subnet" "public_backend_subnet_b" {
  vpc_id = var.vpc_id
  cidr_block = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "GFP-Backend-Subnet-B"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_backend_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_backend_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Private

resource "aws_subnet" "private_backend_subnet_a" {
  vpc_id = var.vpc_id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "GFP-Backend-Subnet-A"
  }
}

resource "aws_subnet" "private_backend_subnet_b" {
  vpc_id = var.vpc_id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "GFP-Backend-Subnet-B"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "private-rt" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_backend_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_backend_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}
