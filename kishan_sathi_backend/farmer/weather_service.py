import requests
from django.conf import settings


class WeatherService:
    """Service to fetch weather data from weatherapi.com"""
    
    BASE_URL = "http://api.weatherapi.com/v1"
    
    @staticmethod
    def get_current_weather(location):
        """
        Get current weather for a location
        
        Args:
            location (str): City name, coordinates, or postal code
            
        Returns:
            dict: Weather data or error message
        """
        try:
            api_key = getattr(settings, 'WEATHER_API_KEY', None)
            
            if not api_key:
                return {
                    'error': 'Weather API key not configured',
                    'message': 'Please add WEATHER_API_KEY to settings'
                }
            
            url = f"{WeatherService.BASE_URL}/current.json"
            params = {
                'key': api_key,
                'q': location,
                'aqi': 'yes' 
                }
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            return {
                'success': True,
                'location': {
                    'name': data['location']['name'],
                    'region': data['location']['region'],
                    'country': data['location']['country'],
                    'localtime': data['location']['localtime'],
                },
                'current': {
                    'temp_c': data['current']['temp_c'],
                    'temp_f': data['current']['temp_f'],
                    'condition': {
                        'text': data['current']['condition']['text'],
                        'icon': data['current']['condition']['icon'],
                    },
                    'wind_kph': data['current']['wind_kph'],
                    'wind_dir': data['current']['wind_dir'],
                    'pressure_mb': data['current']['pressure_mb'],
                    'humidity': data['current']['humidity'],
                    'cloud': data['current']['cloud'],
                    'feelslike_c': data['current']['feelslike_c'],
                    'uv': data['current']['uv'],
                    'air_quality': data['current'].get('air_quality', {}),
                }
            }
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 400:
                return {
                    'error': 'Invalid location',
                    'message': 'Please provide a valid city name or location'
                }
            return {
                'error': 'Weather API error',
                'message': str(e)
            }
        except requests.exceptions.Timeout:
            return {
                'error': 'Request timeout',
                'message': 'Weather service is taking too long to respond'
            }
        except Exception as e:
            return {
                'error': 'Unexpected error',
                'message': str(e)
            }
    
    @staticmethod
    def get_forecast(location, days=3):
        """
        Get weather forecast for a location
        
        Args:
            location (str): City name, coordinates, or postal code
            days (int): Number of days (1-10)
            
        Returns:
            dict: Forecast data or error message
        """
        try:
            api_key = getattr(settings, 'WEATHER_API_KEY', None)
            
            if not api_key:
                return {
                    'error': 'Weather API key not configured',
                    'message': 'Please add WEATHER_API_KEY to settings'
                }
            
            url = f"{WeatherService.BASE_URL}/forecast.json"
            params = {
                'key': api_key,
                'q': location,
                'days': min(days, 10),  # API supports max 10 days
                'aqi': 'yes'
            }
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            return {
                'success': True,
                'location': {
                    'name': data['location']['name'],
                    'region': data['location']['region'],
                    'country': data['location']['country'],
                },
                'current': {
                    'temp_c': data['current']['temp_c'],
                    'condition': {
                        'text': data['current']['condition']['text'],
                        'icon': data['current']['condition']['icon'],
                    },
                    'humidity': data['current']['humidity'],
                },
                'forecast': [
                    {
                        'date': day['date'],
                        'day': {
                            'maxtemp_c': day['day']['maxtemp_c'],
                            'mintemp_c': day['day']['mintemp_c'],
                            'avgtemp_c': day['day']['avgtemp_c'],
                            'maxwind_kph': day['day']['maxwind_kph'],
                            'totalprecip_mm': day['day']['totalprecip_mm'],
                            'avghumidity': day['day']['avghumidity'],
                            'daily_chance_of_rain': day['day']['daily_chance_of_rain'],
                            'condition': {
                                'text': day['day']['condition']['text'],
                                'icon': day['day']['condition']['icon'],
                            },
                            'uv': day['day']['uv'],
                        }
                    }
                    for day in data['forecast']['forecastday']
                ]
            }
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 400:
                return {
                    'error': 'Invalid location',
                    'message': 'Please provide a valid city name or location'
                }
            return {
                'error': 'Weather API error',
                'message': str(e)
            }
        except Exception as e:
            return {
                'error': 'Unexpected error',
                'message': str(e)
            }
