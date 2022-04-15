# Karpenter

``` sh
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```


``` sh
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowNonRDS",
            "Effect": "Allow",
            "Action": [
                "*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "DenyRDS",
            "Effect": "Deny",
            "Action": "rds:*",
            "Resource": [
                "*"
            ]
        }
    ]
}
```
