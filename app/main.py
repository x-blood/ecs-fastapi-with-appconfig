from fastapi import FastAPI
import urllib.request
import json

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/hello/{name}")
async def say_hello(name: str):
    config = get_appconfig_profile()
    print(config["enabled"])
    return {
        "message": f"Hello {name}",
        "config": f"{config}"
    }


def get_appconfig_profile():
    url = f'http://localhost:2772/applications/AppConfigLab/environments/AppConfigLabAPIGatewayDevelopment/configurations/FeatureFlagA?flag=featureFlagAItemA'
    config = json.loads(urllib.request.urlopen(url).read())
    print(config)
    return config

