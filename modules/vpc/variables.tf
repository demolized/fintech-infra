################################################################################
# General Variables from root module
################################################################################

variable "main_region" {
  type    = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "env_name" {
  type    = string
  default = "dev"
}
