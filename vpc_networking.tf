//VPC CONFIGURATIONS//

//provider declaration//
provider "aws" {
region = "ap-south-1"
}

//vpc creation//
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames #imp to connect internet publicaly
  enable_dns_support  = var.enable_dns_support
 tags = {
    Name = "myvpc"
}
}

//creation of IG//
resource "aws_internet_gateway" "mygateway" {
  vpc_id = aws_vpc.myvpc.id ###it will attach IG to the above created vpc 
  tags = {
    Name = var.mygateway
  }
}

//fetching available AZ//
data "aws_availability_zones" "available" {
  state = "available"
}

//creation of public subnet-1//
resource "aws_subnet" "public-subnet-1" {
  vpc_id     = aws_vpc.myvpc.id ##subnet will launch in above created vpc thats why we gave ref myvpc.id
  cidr_block = var.public-subnet-1-cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = var.map_public_ip_on_launch #to convert subnet into public subnet
  tags = {
    Name = var.public-subnet-1
  }
}

//creation of public subnet-2//
resource "aws_subnet" "public-subnet-2" {
  vpc_id     = aws_vpc.myvpc.id ##subnet will launch in above created vpc thats why we gave ref myvpc.id
  cidr_block = var.public-subnet-2-cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags = {
    Name = var.public-subnet-2
  }
}

//creation of private subnet-1//
resource "aws_subnet" "private-subnet-1" {
  vpc_id     = aws_vpc.myvpc.id ##subnet will launch in above created vpc thats why we gave ref myvpc.id
  cidr_block = var.private-subnet-1-cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false #to make subnet private 
   tags = {
    Name = var.private-subnet-1
  }
}

//creation of private subnet-2//
resource "aws_subnet" "private-subnet-2" {
  vpc_id     = aws_vpc.myvpc.id ##subnet will launch in above created vpc thats why we gave ref myvpc.id
  cidr_block = var.private-subnet-2-cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false #to make subnet private 
    tags = {
    Name = var.private-subnet-2
  }
}

//creation of public route table//
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.myvpc.id

  route = []

  tags = {
    Name = var.public-route-table
  }
}

//creation of public route//
resource "aws_route" "public-route" {
  route_table_id            = aws_route_table.public-route-table.id ##it will attach route to above route table 
  destination_cidr_block    = "0.0.0.0/0" ##for internet connection 
  gateway_id                = aws_internet_gateway.mygateway.id
  depends_on                = [aws_route_table.public-route-table] ##it is depend on above route table it only creates when above route table will 1 create
}

//creation of private route table//
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.myvpc.id

  route = []

  tags = {
    Name = var.private-route-table
  }
}

//no need to create route for private subnet//

//subnet public association1//
resource "aws_route_table_association" "public-association1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}

//subnet public association2//
resource "aws_route_table_association" "public-association2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}

//subnet private association1//
resource "aws_route_table_association" "private-association1" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-route-table.id
}

//subnet private association2//
resource "aws_route_table_association" "private-association2" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-route-table.id
}

//creation of security group//
resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "allow all inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "All traffic"
    from_port        = 0 ##all port
    to_port          = 0
    protocol         = "-1" ##for all protocal 
    cidr_blocks      = ["0.0.0.0/0"] ##internet se access 
    ipv6_cidr_blocks = null ##dont have value 
    security_groups  = null
    prefix_list_ids  = null
    self             = null
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Outbound rule"
    security_groups  = null
    prefix_list_ids  = null
    self             = null
  }

  tags = {
    Name = "mysg"
  }
}

//variables declaration//
variable "cidr" {
  description = "Enter the CIDR range required for VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS Hostname"
  type        = bool
  default     = null
}

variable "enable_dns_support" {
  description = "Enable DNS Support"
  type        = bool
  default     = null
}

variable "mygateway" {
  description = "internet gateway name"
  type        = string
  default     = "mygateway"
}

variable "public_subnet" {
  description = "enter the number of public subnets you need"
  type        = number
  default     = null
}

variable "private_subnet" {
  description = "CIDR block for database subnet"
  type        = list(any)
  default     = null
}

variable "public-subnet-1-cidr" {
  description = "Cidr Blocks"
  type        = string
  default     = "192.168.1.0/24"
}

variable "public-subnet-2-cidr" {
  description = "Cidr Blocks"
  type        = string
  default     = "192.168.2.0/24"
}

variable "map_public_ip_on_launch" {
  description = "It will map the public ip while launching resources"
  type        = bool
  default     = null
}

variable "public-subnet-1" {
  description = "public subnet name"
  type        = string
  default     = "public-subnet-1"
}

variable "public-subnet-2" {
  description = "public subnet name"
  type        = string
  default     = "public-subnet-2"
}

variable "private-subnet-1-cidr" {
  description = "Cidr Blocks"
  type        = string
  default     = "192.168.5.0/24"
}

variable "private-subnet-2-cidr" {
  description = "Cidr Blocks"
  type        = string
  default     = "192.168.6.0/24"
}

variable "private-subnet-1" {
  description = "private subnet name"
  type        = string
  default     = "private-subnet-1"
}

variable "private-subnet-2" {
  description = "private subnet name"
  type        = string
  default     = "private-subnet-2"
}

variable "manage_default_route_table" {
  description = "Are we managing default route table"
  type        = bool
  default     = null
}

variable "public-route-table" {
  description = "Tag name for public route table"
  type        = string
  default     = "public-route-table"
}

variable "private-route-table" {
  description = "Tag name for private route table"
  type        = string
  default     = "private-route-table"
}

variable "database_route_table_association_required" {
  description = "Whether db route table association required"
  type        = bool
  default     = null
}

variable "enable_ipv6" {
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block."
  type        = bool
  default     = null
}

variable "default_security_group_name" {
  description = "Enter the name for security group"
  type        = string
  default     = null
}

variable "enable_dhcp_options" {
  description = "Enable DHCP options True or False"
  type        = bool
  default     = null
}
