variable "td_service" {
  type = string
}
variable "execution_role_arn" {
  type = string
}
variable "container_name" {
  type = string
}
variable "ecr_image" {
  type = string
}
variable "container_cpu" {
  type = number
}
variable "command" {
  type    = list(string)
  default = []
}
variable "container_memory" {
  type = number
}
variable "container_port" {
  type = number
}
variable "aws_region" {
  type = string
}
variable "host_port" {
  type    = number
  default = 3000
}
variable "environmentVariables" {
  type    = list(map(any))
  default = []
}
variable "created_by" {
  type = string
}
variable "environment" {
  type = string
}
variable "organisation" {
  type = string
}
variable "task_role_arn" {
  default = "arn:aws:iam::994094640628:role/ecsTaskRoleArn"
}