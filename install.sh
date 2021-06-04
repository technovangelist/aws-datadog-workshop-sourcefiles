#!/bin/bash
git clone https://github.com/technovangelist/aws-datadog-workshop-sourcefiles.git ~/sourcefiles 

cp -r ~/sourcefiles/section* ~/environment/
cp ~/sourcefiles/kopsconfig.yaml ~/environment/
chmod +x ~/environment/section2/setup.sh
npm i -g c9
sudo yum install terraform -y


export TF_VAR_ddapikey=$DD_API_KEY
export TF_VAR_ddappkey=$DD_APP_KEY

echo "export DD_API_KEY=$DD_API_KEY" >> ~/.bashrc
echo "export DD_APP_KEY=$DD_APP_KEY" >> ~/.bashrc
echo "export TF_VAR_ddapikey=$DD_API_KEY" >> ~/.bashrc
echo "export TF_VAR_ddappkey=$DD_APP_KEY" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "alias ks='kubectl -n kube-system'" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc
echo "complete -F __start_kubectl ks" >> ~/.bashrc



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

# aws ec2 import-key-pair --key-name ecommerceapp --public-key-material fileb://~/.ssh/workshop.pub

aws iam create-group --group-name kops

aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops

aws iam create-user --user-name kops
aws iam add-user-to-group --user-name kops --group-name kops
aws iam create-access-key --user-name kops > kopskeys

printf '[profile kops]\nregion = us-west-2\noutput = json' >> ~/.aws/config
printf '[kops]\naws_access_key_id = %s\naws_secret_access_key = %s' "$(jq -r .AccessKey.AccessKeyId kopskeys)" "$(jq -r .AccessKey.SecretAccessKey kopskeys)"
# aws configure set aws_access_key_id $(jq -r .AccessKey.AccessKeyId kopskeys)
# aws configure set aws_secret_access_key $(jq -r .AccessKey.SecretAccessKey kopskeys)
# aws configure set default.region us-west-2
# aws configure set default.output json

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

export kssname="workshop-state-store-${DD_API_KEY: -4}"

aws s3api create-bucket --bucket "$kssname" --region us-east-1
aws s3api put-bucket-versioning --bucket "$kssname"  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$kssname" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

export KOPSNAME="workshop-${DD_API_KEY: -4}.k8s.local"
export KOPS_STATE_STORE=s3://$kssname
echo "export KOPSNAME=$KOPSNAME" >> ~/.bashrc 
echo "export KOPS_STATE_STORE=$KOPS_STATE_STORE" >> ~/.bashrc 

curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops
sudo mv kops /usr/local/bin/kops
ssh-keygen -f /home/ec2-user/.ssh/id_rsa -q -N ""
echo "$KOPSNAME"
sed -i "s|workshop.k8s.local|$KOPSNAME|g" /home/ec2-user/environment/kopsconfig.yaml
sed -i "s|s3://workshop-state-store|$KOPS_STATE_STORE|g" /home/ec2-user/environment/kopsconfig.yaml
sed -i "s|s3://c/|s3://|g"  /home/ec2-user/environment/kopsconfig.yaml
kops create -f /home/ec2-user/environment/kopsconfig.yaml
kops create secret --name "$KOPSNAME" --state "$KOPS_STATE_STORE" sshpublickey admin -i ~/.ssh/id_rsa.pub
kops update cluster "$KOPSNAME" --yes --admin

echo "kops export kubecfg --admin" >> ~/.bashrc
# aws ec2 run-instances --image-id ami-07e965b5b43bda762 --count 1 --instance-type t3.medium --key-name ecommerceapp --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=workshopcluster}]'

source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.

