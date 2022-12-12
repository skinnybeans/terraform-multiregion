provider "aws" {
  profile = ""
  region  = var.region
}

variable "region" {
  type        = string
  description = "Region to deploy resources"
  default     = ""
}

variable "environment" {
  type        = string
  description = "environment resources are deployed to"
  default     = ""
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.environment}/vpc/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.environment}/vpc/private_subnet_ids"
}

data "aws_ssm_parameter" "public_subnet_ids" {
  name = "/${var.environment}/vpc/public_subnet_ids"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

###
### instance
###
resource "aws_instance" "web" {
  //ami           = data.aws_ami.ubuntu.id

  # apache image just for testing instance is reachable
  ami             = "ami-0141022d5e2e1bd41"
  instance_type   = "t3.micro"
  subnet_id       = jsondecode(data.aws_ssm_parameter.public_subnet_ids.value)[0]
  security_groups = [aws_security_group.web_instance.id]

  tags = {
    Name = "HelloWorld"
    vpc  = data.aws_ssm_parameter.vpc_id.value
  }
}

###
### Load balancer
###

## Security group public -> LB
resource "aws_security_group" "web_lb" {
  name   = "web-lb"
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  ingress {
    description = "HTTPS traffic from public"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP traffic from public"
    from_port   = 80
    to_port     = 80
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
    Name             = "${var.environment}-lb"
    Environment      = var.environment
    TerraformManaged = "true"
  }
}

# Security group LB -> instances
resource "aws_security_group" "web_instance" {
  name   = "web-instance"
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  ingress {
    description = "traffic from LB to instance"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name             = "web-instance"
    Environment      = var.environment
    TerraformManaged = "true"
  }
}

resource "aws_lb" "test" {
  name               = "test-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_lb.id, aws_security_group.web_instance.id]
  subnets            = jsondecode(data.aws_ssm_parameter.public_subnet_ids.value)

  # enable_deletion_protection = true

  tags = {
    Name             = "${var.environment}-lb"
    Environment      = var.environment
    TerraformManaged = "true"
  }
}

###
### Target group
###

resource "aws_lb_target_group" "test" {
  name     = "test-web-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value

  health_check {
    healthy_threshold   = "3"
    interval            = 30
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 3
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.test.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.test.id
    type             = "forward"
  }

  # default_action {
  #  type = "redirect"

  #  redirect {
  #    port        = 443
  #    protocol    = "HTTPS"
  #    status_code = "HTTP_301"
  #  }
  # }
}
