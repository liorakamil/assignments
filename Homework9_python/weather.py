from requests import get
import json
import click

@click.command()
@click.option('--token', prompt='Insert token', help='Your weatherstack token.')
@click.option('--city', help="city")
@click.option('--T', default='Celsius', type=click.Choice(['Celsius', 'Fahrenheit']), help="temperature units")
def weather(token, city, t):
    cities = city.split(',')
    for city_name in cities:
        city = get("http://api.weatherstack.com/current?access_key={}&query={}%20&units={}".format(
            token, city_name, 'm' if t=='Celsius' else 'f'))
        city_json = json.loads(city.text)
        if "error" in city_json:
            print(city_json["error"]["info"])
            exit(1)
        temperature = city_json["current"]["temperature"]
        click.echo("The weather today in {} is {} {}".format(city_name, temperature, t))

if __name__ == "__main__":
    weather()