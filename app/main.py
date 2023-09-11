from fastapi import FastAPI
import urllib.request
import json
import os

app = FastAPI()

appconfig_application_name = os.environ.get('APPCONFIG_APPLICATION_NAME')
appconfig_environment_name = os.environ.get('APPCONFIG_ENVIRONMENT_NAME')
appconfig_configuration_profile_name = os.environ.get('APPCONFIG_CONFIGURATION_PROFILE_NAME')
appconfig_feature_flag_key_name = os.environ.get('APPCONFIG_FEATURE_FLAG_KEY_NAME')


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
    url = f'http://localhost:2772/applications/{appconfig_application_name}/environments/{appconfig_environment_name}/configurations/{appconfig_configuration_profile_name}?flag={appconfig_feature_flag_key_name}'
    config = json.loads(urllib.request.urlopen(url).read())
    print(config)
    return config

