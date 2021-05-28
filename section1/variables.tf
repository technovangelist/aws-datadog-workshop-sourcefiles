variable "instance_type" {
  description = "Instance type to use for each host."
  type        = string
  default     = "t2.medium"
}
variable "region" {
  type    = string
  default = "us-west-2"
}
variable "az" {
  description = "AWS region availability zone"
  type        = string
  default     = "b"
}
variable "keyname" {
  description = "Name of the ssh key to use"
  default     = "ecommerceapp"
}
variable "owner" {
  type    = string
  default = "datadogworkshop"
}
variable "mainami" {
  type    = string
  default = "ami-02701bcdc5509e57b"
}
variable "mainamiuser" {
  type    = string
  default = "ubuntu"
}

variable "rubyami" {
  type    = string
  default = "ami-0def4a8d8d8395506"
}
variable "rubyamiuser" {
  type    = string
  default = "bitnami"
}

variable "ddapikey" {
  type      = string
  sensitive = true
}

variable "ddappkey" {
  type      = string
  sensitive = true
}

variable "clienttoken" {
  type = string
}

variable "rumappid" {
  type = string
}
