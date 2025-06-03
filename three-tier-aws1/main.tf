provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "three tier vpc"
  }
}

# Public Subnet 1 (us-east-1e)
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1e"
  tags = {
    Name = "public-subnet-1"
  }
}

# Public Subnet 2 (us-east-1a)
resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "three-tier-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Route Table Association for Subnet 1
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Route Table Association for Subnet 2
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ec2-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0c3ce86fb8321acb9"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data     = file("user-data.sh")
  tags = {
    Name = "web-server for lab4"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "rds-sg"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "db_subnet" {
  subnet_ids = [aws_subnet.public.id, aws_subnet.public_2.id]
  tags = {
    Name = "db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "db" {
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "mydb"
  username          = var.db_username
  password          = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
}