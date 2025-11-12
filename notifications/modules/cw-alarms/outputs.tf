output "lambda_errors_alarm_name" { value = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name }
output "sqs_oldest_age_alarm_name" { value = aws_cloudwatch_metric_alarm.sqs_oldest_age.alarm_name }
