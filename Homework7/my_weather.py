from requests import get
import json
import sys
import os


num_args = len(sys.argv)
MY_API = os.environ.get('API')
if MY_API is None:
    print("please set env_var API token")
    exit(1)

if num_args == 1:
    try:
        city_name = sys.argv[1]
    except:
        print("error: the city does not exists... please provide city (Paris? Dublin?) " \
              "on the command line")
        sys.exit(1)  # abort
elif num_args == 2:
    city_names = sys.argv[1]
    cities = city_names.split(',')
    for city_name in cities:
        city = get("http://api.weatherstack.com/current?access_key={}&query={}%20".format(
            MY_API, city_name))
        city_json = json.loads(city.text)
        temperature = city_json["current"]["temperature"]
        print("The weather today in {} is {} Celsius".format(city_name, temperature))
else:
    city_name = sys.argv[1]
    if sys.argv[2] == "-f":
        city = get(
            "http://api.weatherstack.com/current?access_key={}&query={}%20&units=f".format(MY_API, city_name))
        city_json = json.loads(city.text)
        temperature = city_json["current"]["temperature"]
        print("Today the weather in {} is {} Fahrenheit".format(city_name, temperature))
    else:
        city = get("http://api.weatherstack.com/current?access_key={}&query={}%20".format(
            MY_API, city_name))
        city_json = json.loads(city.text)
        temperature = city_json["current"]["temperature"]
        print("Today the weather in {} is {} Celsius".format(city_name, temperature))