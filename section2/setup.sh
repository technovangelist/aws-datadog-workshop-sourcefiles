sftp -i ~/.ssh/ecommerceapp bitnami@$(aws ec2 describe-instances --filters "Name=tag:Name,Values=workshopcluster" | jq -r .Reservations[0].Instances[0].PublicIpAddress):/etc/kubernetes/admin.conf
mv admin.conf ~/.kube/sandbox.conf
