
# Security groups EXISTENTES (solo lectura, no los crea Terraform)

# SG de la app / ALB (app-sg)
data "aws_security_group" "app" {
  id = "sg-0d30a2a5404b4b62f"
}

# SG de la base de datos (db-sg)
data "aws_security_group" "db" {
  id = "sg-0693a280b6588fc55"
}


# IAM ROLE para ECS task execution (esto sí lo maneja Terraform)

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-certeza360"

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

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
