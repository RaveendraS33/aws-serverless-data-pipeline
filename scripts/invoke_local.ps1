Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

aws lambda invoke --function-name aws-serverless-data-pipeline-ingest response.json
Get-Content response.json
