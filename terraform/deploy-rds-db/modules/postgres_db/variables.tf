variable "dbIdentifier" {
  type = string
}
variable "dbInstanceClass" {
  type    = string
  default = "db.t3.small"
}
variable "dbAllocatedStorage" {
  type    = number
  default = 100
}
variable "dbName" {
  type    = string
  default = "postgres"
}
variable "dbMaxAllocatedStorage" {
  type    = number
  default = 1000
}
variable "pass" {
  type = string
}
variable "environment" {
  type = string
}
variable "organization" {
  type = string
}
variable "monitoringRoleArn" {
  type    = string
  default = "arn:aws:iam::127772639952:role/rds-monitoring-role"
}
