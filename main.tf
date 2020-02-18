provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port to use for http comms"
  type = number
  default = 8080
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type  = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} 8080 &
              EOF

  # Required when using a launch configuration with an autoscaling roup
  lifecycle {
    create_before_destroy = true
  }

}
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id

}
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  min_size = 2
  max_size = 20
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }

}

#output "public_ip" {
  #value = aws_launch_configuration.example.public_dns
  #description = "The public IP of the webserver"
#}
