output "ecs_service_id" {
  description = "ID of service created"
  value       = join("", aws_ecs_service.main[*].id)
}

output "codedeploy_group_id" {
  description = "Codedeploy group id"
  value       = join("", aws_codedeploy_deployment_group.main[*].id)
}