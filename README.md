# Bolt SRE test
This project serves content from a private S3 bucket via CloudFront Distribution on a different AWS account that the S3 bucket is hosted on, sets an alternate domain, and requests an SSL certificate using Terraform.

## Technical overview
The current implementation uses resources such as CloudFront distribution, Route 53 zone and records, SSL certificate request in Certificate Manager (ACM), and private S3 bucket.

Please pay attention that S3 bucket is hosted on the separate AWS account. To allow access to a private S3 bucket from another account IAM policy was attached to the resource.

When CloudFront distribution has access to S3, content can be delivered to a client. If the content is already in the edge location, then CloudFront immediately delivers it, otherwise retrieves it from S3.

Route 53 zone and records are being created to validate the certificate and then ACM returns valid certificate until next year issued by Amazon.

![Architecture diagram](/images/bolt-sre-task-diagram.drawio.svg)

## Installation guide

### Preparations
1. [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) 
2. [Install Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Configure AWS
1. Open the AWS config file by running `vim ~/.aws/config`
2. Add profiles with names `account_1` and `account_2`
3. For `account_1` please set `us-east-1` region since CloudFront supports certificates only in the North Virginia

**Example**
```
[profile account_1]
aws_access_key_id = XXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXX
region = us-east-1
output = json

[profile account_2]
aws_access_key_id = XXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXX
region = eu-west-1
output = json
```

### Deploy
1. Navigate to the repository root directory
2. Run `terraform plan`
3. Enter the alternate domain for Cloudfront distribution
4. If terraform showed an execution plan, then run `terraform apply` and enter alternate domain again
5. Wait for **<span style="color:green">Apply complete!</span>** message. It might take time due to certificate validation

**NB!** You might need to set Route 53 nameserver records in the domain registrar portal if the domain is not registered in AWS

### Test
1. Upload file to the S3 (e.g. test.png)
2. Open in your browser `https://<alternate_domain>/test.png` (e.g. https://example.com/test.png)
