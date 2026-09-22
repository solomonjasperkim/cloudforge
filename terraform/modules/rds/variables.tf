variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "private_cidr_blocks" { type = list(string) }
variable "instance_class" { type = string }
variable "multi_az" { type = bool }
variable "deletion_protection" { type = bool }
