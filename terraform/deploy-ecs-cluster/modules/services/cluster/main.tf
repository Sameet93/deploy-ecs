resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    created_by   = var.created_by
    organisation = var.organisation
    environment  = var.environment
  }
}

