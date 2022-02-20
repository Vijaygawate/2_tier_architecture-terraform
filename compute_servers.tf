//EC2 CONFIGURATIONS//

//fetching subnet ids//
data "aws_subnet_ids" "available_subnet" {
  vpc_id = data.aws_vpc.vpc_available.id
  filter {
    name   = "tag:Name"
    values = ["private-subnet*"]
  }
}

//fetching security group id//
data "aws_security_group" "mysg1" {
  filter {
    name   = "tag:Name"
    values = ["mysg"]
  }
}

//creation of load balancer//
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = data.aws_subnet_ids.available_db_subnet.ids

  enable_deletion_protection = false
  
  tags = {
    Environment = "Dev"
  }
}

//fetching vpc//
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["myvpc"]
  }
}

//creation of target group//
resource "aws_lb_target_group" "mytg" {
name = "mytg"
port = 80
protocol = "HTTP"
vpc_id = data.aws_vpc.vpc_available.id
}

//creation of listners//
resource "aws_lb_listener" "mylistener" {
load_balancer_arn = aws_lb.myalb.arn
port = "80"
protocol = "HTTP"
default_action {
type = "forward"
target_group_arn = aws_lb_target_group.mytg.arn
}
}

//fetching ami from aws//
data "aws_ami" "amazon_linux_2" {
 most_recent = true
 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }
 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
 owners = ["amazon"]
}

//fetching user data from .sh file//
data "template_file" "user_data" {
  template = file("./user-data.sh")
}

//creation of launch configuration//
resource "aws_launch_configuration" "mylc" {
  name_prefix   = "mylc"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  user_data = data.template_file.user_data.rendered
  key_name = "testkey"
  associate_public_ip_address = true
  security_groups    = [data.aws_security_group.mysg.id]
  
  #lifecycle {
  #  create_before_destroy = true
  #}
}

//creation of autoscaling group//
resource "aws_autoscaling_group" "myasg" {
  name = "myasg"
  vpc_zone_identifier = data.aws_subnet_ids.available_db_subnet.ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  launch_configuration = aws_launch_configuration.mylc.name
  target_group_arns = [aws_lb_target_group.mytg.arn]
  tag {
    key = "Name"
    value = "wordpress-app-server"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_target_group.mytg
  ]
}

//variables//
variable "min_size" {
  description = "Minimum number of instances launched"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Minimum number of instances launched"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Minimum number of instances launched"
  type        = number
  default     = 1
}

variable "use_name_prefix" {
  description = "Creates a unique name beginning with the specified prefix. Conflicts with name"
  type        = string
  default     = null
}
