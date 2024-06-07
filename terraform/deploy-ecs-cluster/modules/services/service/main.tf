// data_subnets.tf
data "aws_subnet_ids" "subnets" {
  vpc_id = var.vpc_id
}

output "subnet_ids" {
  value = data.aws_subnet_ids.subnets.ids
}

//  AWS ECS Service to run the task definition
resource "aws_ecs_service" "main" {
  count                = 1
  name                 = var.name
  cluster              = var.cluster
  task_definition      = var.task_definition_arn
  scheduling_strategy  = "REPLICA"
  desired_count        = var.service_count
  force_new_deployment = true

  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.subnets
    assign_public_ip = var.public_ip
  }

  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.container_name
    container_port   = var.port
  }

  depends_on = [
    aws_lb_listener.main_blue_green,
  ]

  lifecycle {
    ignore_changes = [
      load_balancer,
      desired_count,
      task_definition,
    ]
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 1
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }
}
resource "aws_lb" "loadbalancer_ecs" {
  name               = "${var.name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.lb_security_groups
  subnets            = data.aws_subnet_ids.subnets.ids

  enable_deletion_protection = false
}
// AWS ELB Target Blue groups/Listener for Blue/Green Deployments
resource "aws_lb_target_group" "blue" {
  name        = "${var.name}-tg-1"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}

// AWS ELB Target Green groups/Listener for Blue/Green Deployments
resource "aws_lb_target_group" "green" {
  name        = "${var.name}-tg-2"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener" "main_blue_green" {
  load_balancer_arn = aws_lb.loadbalancer_ecs.arn
  protocol          = "HTTP"
  port              = 80

  depends_on = [aws_lb_target_group.blue]

  default_action {
    target_group_arn = aws_lb_target_group.blue.arn
    type             = "forward"
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

/*====================================================================
      AWS CodeDeploy integration for Blue/Green Deployments.
====================================================================*/

// AWS Codedeploy apps defintion for each module
resource "aws_codedeploy_app" "main" {
  compute_platform = "ECS"
  name             = "Deployment-${var.name}"
}

// AWS Codedeploy Group for each codedeploy app created
resource "aws_codedeploy_deployment_group" "main" {
  count                  = 1
  app_name               = aws_codedeploy_app.main.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "deployment-group-${var.name}"
  service_role_arn       = var.service_role_codedeploy

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster
    service_name = aws_ecs_service.main[count.index].name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
        aws_lb_listener.main_blue_green.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }

    }
  }

  lifecycle {
    ignore_changes = [blue_green_deployment_config]
  }
}

/*===========================================
              Autoscaling zone
============================================*/

// AWS Autoscaling target to linked the ecs cluster and service
resource "aws_appautoscaling_target" "main" {
  count              = 1
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster}/${aws_ecs_service.main[count.index].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = var.auto_scale_role
  min_capacity       = var.min_scale
  max_capacity       = var.max_scale

  lifecycle {
    ignore_changes = [
      role_arn,
    ]
  }
}

// AWS Autoscaling policy to scale using cpu allocation
resource "aws_appautoscaling_policy" "cpu" {
  count              = 1
  name               = "ecs_scale_cpu"
  resource_id        = aws_appautoscaling_target.main[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.main[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[count.index].service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }

  depends_on = [aws_appautoscaling_target.main]
}

// AWS Autoscaling policy to scale using memory allocation
resource "aws_appautoscaling_policy" "memory" {
  count              = 1
  name               = "ecs_scale_memory"
  resource_id        = aws_appautoscaling_target.main[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.main[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.main[count.index].service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }

  depends_on = [
    aws_appautoscaling_target.main
  ]
}
