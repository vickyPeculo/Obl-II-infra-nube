resource "aws_ecr_repository" "api" {
  name                 = "certeza360-api"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "ecr-certeza360-api" }
}

resource "aws_ecs_cluster" "main" {
  name = "certeza360-cluster"
}

resource "aws_lb" "api" {
  name               = "certeza360-api-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
  security_groups    = [data.aws_security_group.app.id]
  tags               = { Name = "alb-certeza360-api" }
}

resource "aws_lb_target_group" "api" {
  name        = "certeza360-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
  tags = { Name = "tg-certeza360-api" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "certeza360-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "certeza360-api"
      image     = "${aws_ecr_repository.api.repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        { containerPort = 8080, hostPort = 8080, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.certeza.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        { name = "DB_HOST", value = aws_db_instance.main.address },
        { name = "DB_NAME", value = aws_db_instance.main.db_name },
        { name = "DB_USER", value = aws_db_instance.main.username },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "ADMIN_SCHEMA_SECRET", value = "amo-el-helado-de-mandarina" },
        { name = "SCHEMA_SQL_PATH", value = "/app/schema.sql" }
      ]
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "certeza360-api-service"
  cluster         = aws_ecs_cluster.main.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.api.arn

  network_configuration {
    assign_public_ip = false
    security_groups  = [data.aws_security_group.app.id]
    subnets          = [aws_subnet.private.id, aws_subnet.private_b.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "certeza360-api"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}
