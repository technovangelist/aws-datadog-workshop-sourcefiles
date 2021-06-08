#!/bin/bash
if [ -z ${KOPS_STATE_STORE+x} ]; then echo 'KOPS_STATE_STORE not set';exit; fi
if [ -z ${KOPSNAME+x} ]; then echo 'KOPSNAME not set';exit; fi
cwd=$(pwd)
cd ~/environment/section1
terraform destroy -auto-approve
cd $cwd

kops delete cluster --name="$KOPSNAME" --state="$KOPS_STATE_STORE" --yes

rm ~/.ssh/id_rsa
rm ~/.ssh/id_rsa.pub

BUCKET_TO_PURGE=${KOPS_STATE_STORE: 5}
echo '#!/bin/bash' > deleteBucketScript.sh \
&& aws --output text s3api list-object-versions --bucket $BUCKET_TO_PURGE \
| grep -E "^VERSIONS" |\
awk '{print "aws s3api delete-object --bucket $BUCKET_TO_PURGE --key "$4" --version-id "$8";"}' >> \
deleteBucketScript.sh && . deleteBucketScript.sh; rm -f deleteBucketScript.sh; echo '#!/bin/bash' > \
deleteBucketScript.sh && aws --output text s3api list-object-versions --bucket $BUCKET_TO_PURGE \
| grep -E "^DELETEMARKERS" | grep -v "null" \
| awk '{print "aws s3api delete-object --bucket $BUCKET_TO_PURGE --key "$3" --version-id "$5";"}' >> \
deleteBucketScript.sh && . deleteBucketScript.sh; rm -f deleteBucketScript.sh;

aws s3 rb "$KOPS_STATE_STORE" --force

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
rm ~/.ssh/workshop.pub
sed -i '/export DD_API_KEY/d' ~/.bashrc
sed -i '/export DD_APP_KEY/d' ~/.bashrc


rm -rf ~/environment/section1
rm -rf ~/environment/section2
rm -rf ~/environment/section3
rm -rf ~/environment/section4

rm -rf ~/sourcefiles

rm ~/environment/kopsconfig.yaml
rm ~/environment/kopskeys
rm ~/.aws/config
rm ~/.aws/credentials


