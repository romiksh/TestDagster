from dagster import asset, Definitions
@asset
def hello_asset():
    return "hello from Dagster on ECS via GitHub Actions and new VPC"
defs = Definitions(assets=[hello_asset])
