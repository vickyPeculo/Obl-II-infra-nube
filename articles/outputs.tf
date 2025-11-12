output "generate_requests_queue_url" {
  value = module.sqs_generate.url
}
output "articles_bucket_name" {
  value = module.s3_articles.bucket
}
output "generator_function_name" {
  value = module.lambda_generator.function_name
}
