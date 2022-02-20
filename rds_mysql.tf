//RDS CONFIGURATIONS//

//fetching subnet group ids from vpc section//
data "aws_vpc" "vpc_available" {
  filter {
    name   = "tag:Name"
    values = ["myvpc"]
  }
}
data "aws_subnet_ids" "available_db_subnet" {
  vpc_id = data.aws_vpc.vpc_available.id
  filter {
    name   = "tag:Name"
    values = ["private-subnet*"]
  }
}

data "aws_security_group" "mysg" {
  filter {
    name   = "tag:Name"
    values = ["mysg"]
  }
}

//creation of db subnet group//
resource "aws_db_subnet_group" "db_sub_group" {
  name       = "db_sub_group"
  subnet_ids = data.aws_subnet_ids.available_db_subnet.ids

  tags = {
    Name = "My DB subnet group"
  }
}

//creation of db instance//
resource "aws_db_instance" "db_instance" {
  engine                   = var.engine_name
  name                     = var.db_name
  username                 = var.user_name
  password                 = var.pass
  skip_final_snapshot      = var.skip_finalSnapshot
  db_subnet_group_name     = aws_db_subnet_group.db_sub_group.id
  delete_automated_backups = var.delete_automated_backup
  multi_az                 = var.multi_az_deployment
  publicly_accessible      = var.public_access
  vpc_security_group_ids   = [data.aws_security_group.mysg.id]
  instance_class           = var.instance_class
  allocated_storage        = 20
}

//variable creation//
variable "engine_name" {
  description = "Enter the DB engine"
  type        = string
  default     = "mysql"
}

variable "db_name" {
  description = "Enter the name of the database to be created inside DB Instance"
  type        = string
  default     = "mydatabase"
}

variable "user_name" {
  description = "Enter the username for DB"
  type        = string
  default     = "vijaydb"
}

variable "pass" {
  description = "Enter the username for DB"
  type        = string
  default     = "Vijaygawate.1999"
}

variable "skip_finalSnapshot" {
  type    = bool
  default = true
}

variable "delete_automated_backup" {
  type    = bool
  default = true
}

variable "multi_az_deployment" {
  description = "Enable or disable multi-az deployment"
  type        = bool
  default     = false
}

variable "public_access" {
  description = "Whether public access needed"
  type        = bool
  default     = false
}

variable "instance_class" {
  type    = string
  default = "db.t2.micro"
}

//output required//
output "rds_address" {
  value = aws_db_instance.db_instance.address
}
