terraform {
    required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.7.0"
    }
}

}

provider "aws" {
    profile = "Geralt"
    region = "us-east-1"
  
}

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["al2023-ami-*-x86_64"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_vpc" "Geralt" {
    cidr_block = "192.168.0.0/16"
    tags = {
        Name = "Geralt-VPC"
    }
  
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.Geralt.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "us-east-1a"
}

resource "aws_route_table" "public-rt" {
    vpc_id = aws_vpc.Geralt.id
    tags = {
        Name = "public-route-table"
    }
}

resource "aws_internet_gateway" "internet-access" {
    vpc_id = aws_vpc.Geralt.id
    tags = {
        Name = "main-igw"
    }  
}

resource "aws_route" "default-route" {
    route_table_id = aws_route_table.public-rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-access.id
  
}

resource "aws_route_table_association" "public-rt-assoc" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_security_group" "allow-http-inbound" {
    name = "allow-http-inbound"
    description = "sg for allowing inbound traffic"
    vpc_id = aws_vpc.Geralt.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

resource "aws_key_pair" "public-key" {
    key_name = "id_rsa"
    public_key = file("C:/Users/User/.ssh/id_rsa.pub")
}

resource "aws_instance" "t2-micro" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t2.micro"
    key_name = aws_key_pair.public-key.key_name
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [ aws_security_group.allow-http-inbound.id ]
    associate_public_ip_address = true
    tags =  {
        Name = "TerraformAssignment"
    }
 
}

resource "aws_s3_bucket" "assignment" {
    bucket_prefix = "terraform-assignment-"
    tags = {
        Name = "TerraformAssignment"
    }
}