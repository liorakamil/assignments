#!/usr/bin/python
from requests import get

get("https://www.google.com")

import json

import sys
print("Today the weather in: ", str(sys.argv[0]))

#print("Today's weather in: ", sys.argv[1])
city = get("http://api.weatherstack.com/current?access_key=0823fd35d0df5ccec0e8eb6bd3660635&query=dublin%20")
print(city.text)

city_json = json.loads(city.text)
print(city_json["current"]["temperature"])








