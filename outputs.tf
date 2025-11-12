output "vpc_id" {
  value = aws_vpc.main.id
}

output "app_subnet_id" {
  value = aws_subnet.public.id
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "api_url" {
  value = aws_lb.api.dns_name
}

output "articles_queue_url" {
  value = aws_sqs_queue.articles.url
}

output "website_url" {
  value = aws_cloudfront_distribution.website.domain_name
}
