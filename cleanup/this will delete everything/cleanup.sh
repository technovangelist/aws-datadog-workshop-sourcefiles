kops delete cluster --name=workshop.k8s.local --state=s3://workshop-state-store --yes

rm ~/.ssh/id_rsa
rm ~/.ssh/id_rsa.pub

BUCKET_TO_PURGE=workshop-state-store
echo '#!/bin/bash' > deleteBucketScript.sh \
&& aws --output text s3api list-object-versions --bucket $BUCKET_TO_PURGE \
| grep -E "^VERSIONS" |\
awk '{print "aws s3api delete-object --bucket $BUCKET_TO_PURGE --key "$4" --version-id "$8";"}' >> \
deleteBucketScript.sh && . deleteBucketScript.sh; rm -f deleteBucketScript.sh; echo '#!/bin/bash' > \
deleteBucketScript.sh && aws --output text s3api list-object-versions --bucket $BUCKET_TO_PURGE \
| grep -E "^DELETEMARKERS" | grep -v "null" \
| awk '{print "aws s3api delete-object --bucket $BUCKET_TO_PURGE --key "$3" --version-id "$5";"}' >> \
deleteBucketScript.sh && . deleteBucketScript.sh; rm -f deleteBucketScript.sh;

aws s3 rb s3://workshop-state-store --force

aws iam delete-access-key --access-key-id $(jq -r .AccessKey.AccessKeyId ~/environment/kopskeys) --user-name kops
aws iam remove-user-from-group --user-name kops --group-name kops
aws iam delete-user --user-name kops

aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops
aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
aws iam delete-group --group-name kops
aws ec2 delete-key-pair --key-name ecommerceapp

rm ~/.ssh/workshop
sed -i '/export DD_API_KEY/d' ~/.bashrc
sed -i '/export DD_APP_KEY/d' ~/.bashrc

cd ~/
rm -rf ~/environment/section1
rm -rf ~/environment/section2
rm -rf ~/environment/section3
rm -rf ~/environment/section4

rm -rf ~/sourcefiles


