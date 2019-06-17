resource "aws_ecr_repository" "repo" {
  count = length(var.repos)
  name  = var.repos[count.index]
}

resource "aws_ecr_lifecycle_policy" "repo_policy" {
  count      = length(var.repos)
  repository = aws_ecr_repository.repo[count.index].name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 100 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 100
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
