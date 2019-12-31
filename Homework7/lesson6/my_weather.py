from requests import get
import json
import sys

nargs = len(sys.argv)
#print(nargs)

if nargs == 1:
    try:
        city_name = sys.argv[1]
    except:
        print("error: the city does not exists... please provide city (Paris? Dublin?) " \
              "on the command line")
        sys.exit(1)  # abort
elif nargs == 2:
    city_names = sys.argv[1]
    cities = city_names.split(',')
    for city_name in cities:
        city = get("http://api.weatherstack.com/current?access_key=0823fd35d0df5ccec0e8eb6bd3660635&query={}%20".format(
            city_name))
        city_json = json.loads(city.text)
        temperature = city_json["current"]["temperature"]
        print("The weather today in " + city_name + " is " + str(temperature))
else:
    city_name = sys.argv[1]
    if sys.argv[2] == "-f":
        city = get(
            "http://api.weatherstack.com/current?access_key=0823fd35d0df5ccec0e8eb6bd3660635&query={}%20&units=f".format(
                city_name))
        city_json = json.loads(city.text)
        temperature = city_json["current"]["temperature"]
        print("Today the weather in " + city_name + " is " + str(temperature) + " Fahrenheit")
    else:
        city = get("http://api.weatherstack.com/current?access_key=0823fd35d0df5ccec0e8eb6bd3660635&query={}%20".format(
            city_name))
        city_json = json.loads(city.text)
        temperature = city_json["current"]["temperature"]
        print("Today the weather in {} is {} Celsius".format(city_name, temperature))
        #print("Today the weather in %s is: %d Celsius" % (city_name, temperature))