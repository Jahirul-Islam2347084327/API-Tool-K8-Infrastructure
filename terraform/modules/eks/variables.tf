variable "vpc-id" {
  type = string
}

variable "private-subnets" {
    type = list(string)  
}