module "ecs_cluster" {
  source           = "../../../modules/services/cluster"
  ecs_cluster_name = "<ECS_CLUSTER_NAME>"
  created_by       = "<CREATED_BY>"
  organisation     = var.organization
  environment      = var.environment
}

module "task_definition" {
  source           = "../../../modules/services/task-definition"
  td_service       = "${var.container_name}-td"
  container_name   = var.container_name
  ecr_image        = "${module.ecr.repository_url}:${var.environment}"
  container_cpu    = 1024
  container_memory = 2048
  container_port   = <CONTAINER_PORT>
  host_port        = <HOST_PORT>
  # command          = ["yarn", "dev-server:start"]
  environmentVariables = [
    { name = "ECS_AVAILABLE_LOGGING_DRIVERS", value = "['json-file', 'awslogs']" },
    // add more env variables here
  ]
  created_by         = "<CREATED_BY>"
  environment        = var.environment
  organisation       = var.organization
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  aws_region         = var.region
}

module "rds_postgres" {
  source          = "../../../../deploy-rds-db/modules/postgres_db"
  dbIdentifier    = "${var.container_name}-${var.environment}-db"
  dbName          = var.container_name
  dbInstanceClass = "db.t3.medium"
  pass            = "<DB_PASSWORD>"
  environment     = var.environment
  organization    = var.organization
}

output "rds_address" {
  description = "rds Address"
  value       = module.rds_postgres.address
}

output "rds_password" {
  value     = module.rds_postgres.password
  sensitive = true
}

// data_subnets.tf
data "aws_subnet_ids" "subnets" {
  vpc_id = var.vpc_id
}

output "subnet_ids" {
  value = data.aws_subnet_ids.subnets.ids
}

module "ecs_service" {
  source                  = "../../../modules/services/service"
  port                    = module.task_definition.container_port
  name                    = "${var.container_name}-service"
  container_name          = var.container_name
  auto_scale_role         = "<AUTO_SCALE_ROLE>"
  cluster                 = module.ecs_cluster.ecs_cluster_name
  task_definition_arn     = module.task_definition.task_definition_arn
  security_groups         = aws_security_group.ecs_security_group.id
  lb_security_groups      = aws_security_group.ecs_security_group.id
  public_ip               = false
  service_count           = <SERVICE_COUNT>
  subnets                 = data.aws_subnet_ids.subnets.ids
  vpc_id                  = "<VPC_ID>"
  service_role_codedeploy = "<SERVICE_ROLE_CODEDEPLOY>"
  min_scale               = <MIN_SCALE>
  max_scale               = <MAX_SCALE>
  role_service            = aws_iam_role.ecs_task_execution_role.arn 
  roleExecArn             = aws_iam_role.ecs_task_execution_role.arn
  roleArn                 = aws_iam_role.ecs_task_role.arn
}

resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name = "/ecs/${module.task_definition.td_service}"
  tags = {
    environment = var.environment
    application = var.container_name
  }
}

data "vpc" "default" {
  default = true
}

resource "aws_security_group" "ecs_security_group" {
  name        = "${module.ecs_service.name}-sg"
  description = "Security group for ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow inbound traffic on app port"
    from_port   = module.task_definition.container_port
    to_port     = module.task_definition.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0.0"]
  }

  ingress {
    description = "Allow inbound traffic on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0.0"]
  }

  ingress {
    description = "Allow inbound traffic on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0.0"]
  }

  ingress {
    description = "Allow inbound traffic on DB port"
    from_port   = module.rds_postgres.db_port
    to_port     = module.rds_postgres.db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0.0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${module.ecs_service.name}-sg"
  }
}

resource "aws_iam_role" "codedeploy-service-role" {
  name = "codedeploy-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codedeploy-service-policy" {
  name = "codedeploy-service-policy"
  role = aws_iam_role.codedeploy-service-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:CreateTaskSet",
          "ecs:UpdateServicePrimaryTaskSet",
          "ecs:DeleteTaskSet",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule",
          "lambda:InvokeFunction",
          "cloudwatch:DescribeAlarms",
          "sns:Publish",
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
// Adjust if required for production
resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecsTaskExecutionPolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*"
          "es:*",
          "ssm:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
// Adjust if required for production
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "ecsTaskPolicy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          // Add required actions here
          "s3:*",
          "es:*",
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = var.container_name

  repository_read_write_access_arns = [
    aws_iam_role.ecs_task_execution_role.arn,
    aws_iam_role.ecs_task_role.arn
  ]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}


