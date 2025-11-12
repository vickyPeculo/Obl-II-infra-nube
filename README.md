## Comandos para desplegar la infraestructura

## Configurar credenciales de AWS
aws configure
### Región: us-east-2

aws sts get-caller-identity


## Desplegar VPC, RDS, ECS y ALB
cd app
terraform init
terraform plan
terraform apply -auto-approve
terraform output


## Desplegar notificaciones (SQS, SNS, Lambda notify)
cd ../notifications
terraform init
terraform plan
terraform apply -auto-approve
terraform output sqs_queue_url   # guardar este valor


## Desplegar generador de artículos (SQS + Lambda + S3)
cd ../articles
terraform init
terraform plan    # acá Terraform pedirá notify_queue_url
terraform apply -auto-approve

## Prueba:
Ir a SQS → certeza360-generate-requests → Send message:
 {
   "topic": "Articulo de prueba",
   "id": "test-001"
 }


## Desplegar sitio estático (S3 + CloudFront)
cd ../static-site
terraform init
terraform plan
terraform apply -auto-approve
terraform output website_url


## Destruir infraestructura (en orden)
cd articles
terraform destroy -auto-approve

cd ../notifications
terraform destroy -auto-approve

cd ../static-site
terraform destroy -auto-approve

cd ../app
terraform destroy -auto-approve
