## Process

- set aws profile
- set aws_access_key_id, aws_secret_access_key, region
- make kubernetes template
- fill out relevant infomation in `config.json`
- `cd auditkube && make build`
- fill out `ami` in `config.json`
- `cd [CLUSTER_DIR] && make up`
