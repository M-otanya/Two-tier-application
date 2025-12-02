terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############################################
# Generate EC2 Key Pair Locally
############################################

resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "app_key" {
  key_name   = "terraform-generated-key"
  public_key = tls_private_key.generated_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.generated_key.private_key_pem
  filename = "C:/Users/ADMN/Documents/AWS Projects/terraform-generated-key.pem"
}

############################################
# VPC + Subnets
############################################

resource "aws_vpc" "app_vpc" {
  cidr_block = "10.20.0.0/16"
  tags = { Name = "app-vpc" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone        = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "app-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone        = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "app-public-b" }
}

resource "aws_subnet" "private_a" {
  vpc_id           = aws_vpc.app_vpc.id
  cidr_block       = "10.20.3.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "app-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id           = aws_vpc.app_vpc.id
  cidr_block       = "10.20.4.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "app-private-b" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = { Name = "app-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id
  tags = { Name = "app-public-rt" }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_a_assoc" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_route_table_association" "public_b_assoc" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_b.id
}

############################################
# Security Groups
############################################

resource "aws_security_group" "web_sg" {
  name   = "app-web-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.my_ip]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "app-web-sg" }
}

resource "aws_security_group" "db_sg" {
  name   = "app-db-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    description     = "MySQL"
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "app-db-sg" }
}

############################################
# EC2 Instance
############################################

resource "aws_instance" "web" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = aws_key_pair.app_key.key_name
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  tags = { Name = "app-web-server" }
}

############################################
# RDS (MySQL)
############################################

resource "aws_db_subnet_group" "db_subnet" {
  name       = "app-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  tags = { Name = "app-db-subnet-group" }
}

resource "aws_db_instance" "mysql" {
  identifier              = "app-db-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password

  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  publicly_accessible     = false
  skip_final_snapshot     = true

  tags = { Name = "app-db" }
}
