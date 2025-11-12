terraform {
  required_version = ">= 1.6"
  required_providers {
    aws     = { source = "hashicorp/aws", version = ">= 5.0" }
    archive = { source = "hashicorp/archive", version = ">= 2.4" }
  }
}

provider "aws" {
  region = var.region
}

# Bucket donde se guardan los artículos generados (JSON/HTML)
module "s3_articles" {
  source      = "./modules/s3-articles"
  bucket_name = var.articles_bucket_name
  tags        = { Name = "s3-articles" }
}

# Cola de "pedidos de generación" (trigger de la Lambda generadora)
module "sqs_generate" {
  source         = "./modules/sqs-generate"
  name           = "certeza360-generate-requests"
  visibility     = 60
  retention_secs = 345600
  tags           = { Name = "sqs-generate-requests" }
}

# Lambda que consume sqs-generate, llama a Bedrock (us-east-1),
# guarda el artículo en S3 y avisa a la cola "articles" que ya tenés (notificaciones).
module "lambda_generator" {
  source               = "./modules/lambda-generator"
  function_name        = "certeza360-article-generator"
  runtime              = "nodejs20.x"
  generate_queue_arn   = module.sqs_generate.arn
  generate_queue_name  = module.sqs_generate.name
  articles_bucket_name = module.s3_articles.bucket
  notify_queue_url     = var.notify_queue_url

  openai_api_key = var.openai_api_key
  openai_model   = var.openai_model

  tags = { Name = "lambda-article-generator" }
}
