resource "aws_cloudwatch_log_group" "certeza" {
  name              = "/certeza360/app"
  retention_in_days = 30

  tags = {
    Name = "cwlg-certeza360"
  }
}
