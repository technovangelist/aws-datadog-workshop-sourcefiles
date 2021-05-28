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


curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl


ssh-keygen -f ~/.ssh/workshop -N ""
chmod 0600 ~/.ssh/workshop
cp ~/.ssh/workshop ~/environment/section1/ecommerceapp

aws ec2 import-key-pair --key-name ecommerceapp --public-key-material fileb://~/.ssh/workshop.pub
aws ec2 run-instances --image-id ami-07e965b5b43bda762 --count 1 --instance-type t3.medium --key-name ecommerceapp --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=workshopcluster}]'

