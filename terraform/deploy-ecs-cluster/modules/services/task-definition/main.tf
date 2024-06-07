resource "aws_ecs_task_definition" "service" {
  family                   = var.td_service
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  network_mode       = "awsvpc"
  cpu                = var.container_cpu
  memory             = var.container_memory
  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn
  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.ecr_image
      essential = true
      command   = var.command
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.host_port
        }
      ]
      environment = var.environmentVariables
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.td_service}"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])

  tags = {
    createdBy    = var.created_by
    environment  = var.environment
    organization = var.organisation
  }
}
