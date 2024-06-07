variable "port" {
  description = "Port number exposed by container"
}

variable "name" {
  description = "Name of service"
}

variable "container_name" {
  description = "container name for the service"
}

variable "service_count" {
  description = "Number of desired task"
  default     = 1
}

variable "subnets" {
  description = "Private subnets from VPC"
  default     = ["subnet-093ce2fadbc13b007"]
}

variable "lb_security_groups" {
  default = ["sg-0d31196656edf4250"]
}

variable "security_groups" {
  description = "Security groups allowed"
  default     = []
}

variable "cluster" {
  description = "Cluster used in ecs"
}

variable "role_service" {
  description = "Role for execution service"
}

variable "vpc_id" {
  description = "VPC ID for create target group resources"
  default     = "vpc-0a5111ae1db3d5fe4"
}

variable "roleArn" {
  description = "Role Iam for task def"
}

variable "roleExecArn" {
  description = "Role Iam for execution"
}

variable "environment" {
  description = "Environment variables for ecs task"
  default     = []
}

variable "auto_scale_role" {
  description = "IAM Role for autocaling services"
}

variable "service_role_codedeploy" {
  description = "Role for ecs codedeploy"
}

variable "max_scale" {
  description = "Maximun number of task scaling"
  default     = 3
}

variable "min_scale" {
  description = "Minimun number of task scaling"
  default     = 1
}

variable "public_ip" {
  default     = false
  description = "Flag to set auto assign public ip"
}

variable "disable_autoscaling" {
  default     = false
  description = "Flag to disable autoscaling service"
}

variable "health_check_path" {
  default = "/"
}

variable "use_cloudwatch_logs" {
  default = true
}

variable "environment_list" {
  description = "Environment variables in map-list format. eg: [{ name='foo', value='bar' }]"
  default     = []
}
variable "task_definition_arn" {
  description = "arn of the task definition used by the service"

}
