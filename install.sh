#!/bin/bash
git clone https://github.com/technovangelist/aws-datadog-workshop-sourcefiles.git ~/sourcefiles 

cp -r ~/sourcefiles/section* ~/environment/
chmod +x ~/environment/section2/setup.sh
npm i -g c9
sudo yum install terraform -y


export TF_VAR_ddapikey=$DD_API_KEY
export TF_VAR_ddappkey=$DD_APP_KEY

echo "export DD_API_KEY=$DD_API_KEY" >> ~/.bashrc
echo "export DD_APP_KEY=$DD_APP_KEY" >> ~/.bashrc
echo "export TF_VAR_ddapikey=$DD_API_KEY" >> ~/.bashrc
echo "export TF_VAR_ddappkey=$DD_APP_KEY" >> ~/.bashrc
echo "export KUBECONFIG=~/.kube/sandbox.conf" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc


curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm repo add datadog https://helm.datadoghq.com
helm repo add stable https://charts.helm.sh/stable
helm repo update

ssh-keygen -f ~/.ssh/workshop -N ""
chmod 0600 ~/.ssh/workshop
cp ~/.ssh/workshop ~/environment/section1/ecommerceapp
cp ~/.ssh/workshop.pub ~/environment/section1/ecommerceapp.pub

aws ec2 import-key-pair --key-name ecommerceapp --public-key-material fileb://~/.ssh/workshop.pub

aws iam create-group --group-name kops

aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops

aws iam create-user --user-name kops
aws iam add-user-to-group --user-name kops --group-name kops
aws iam create-access-key --user-name kops > kopskeys

aws configure set aws_access_key_id $(jq -r .AccessKey.AccessKeyId kopskeys)
aws configure set aws_secret_access_key $(jq -r .AccessKey.SecretAccessKey kopskeys)
aws configure set default.region us-west-2
aws configure set default.output json

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

aws s3api create-bucket --bucket workshop-state-store --region us-east-1
aws s3api put-bucket-versioning --bucket workshop-state-store  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket workshop-state-store --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

export KOPSNAME=workshop.k8s.local
export KOPS_STATE_STORE=s3://workshop-state-store

ssh-keygen -f /home/ec2-user/.ssh/id_rsa -q -N ""
kops create cluster -f ./kopsconfig.yaml
kops update cluster ${KOPSNAME} --yes --admin

kops export kubecfg --admin
# aws ec2 run-instances --image-id ami-07e965b5b43bda762 --count 1 --instance-type t3.medium --key-name ecommerceapp --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=workshopcluster}]'

