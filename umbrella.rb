# Dependencies
require "http"
require "json"
require "dotenv/load"
require "ascii_charts"

# Credentials
pirate_weather_api_key = ENV.fetch("PIRATE_WEATHER_KEY")
googlemaps_api_key = ENV.fetch("GMAPS_KEY")

puts "========================================"
puts "    Will you need an umbrella today?    "
puts "========================================"


puts "Hello, fellow human being. Please enter your current location."

user_location = gets.chomp

# Call Google Maps for Lat/Long
google_maps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=" + user_location + "&key=" + googlemaps_api_key


# Start with getting raw HTML response
google_maps_html_response = HTTP.get(google_maps_url)

parsed_google_maps_response = JSON.parse(google_maps_html_response)

latitude = parsed_google_maps_response.fetch("results")[0].fetch("geometry").fetch("location").fetch("lat")
longitude = parsed_google_maps_response.fetch("results")[0].fetch("geometry").fetch("location").fetch("lng")

# Call Pirates Weather for Weather
pirates_weather_url = "https://api.pirateweather.net/forecast/" + pirate_weather_api_key + "/#{latitude},#{longitude}"

pirates_html = HTTP.get(pirates_weather_url)
pirates_parsed = JSON.parse(pirates_html)

temperature_current = pirates_parsed.fetch("currently").fetch("temperature")
summary_current = pirates_parsed.fetch("currently").fetch("summary")
rain_chance_current = pirates_parsed.fetch("currently").fetch("precipProbability")
temperature_hour1 = pirates_parsed.fetch("hourly").fetch("data")[1].fetch("temperature")
rain_chance_hour1 = pirates_parsed.fetch("hourly").fetch("data")[1].fetch("precipProbability")

# From revieiwng Pirates Data:
# Current data is in: .fetch("currently").fetch("summary") or .fetch("temperature") etc.
# Hourly data is in: .fetch("hourly").fetch("data")[i]
  # i should correlate with how many hours from now you want
  # time is in UTC

puts "The weather is #{summary_current} today in #{user_location} with temperature of #{temperature_current} and a #{rain_chance_current*100}\% chance of rain. Next hour, the temperature will change to #{temperature_hour1} with a #{rain_chance_hour1*100}\% chance of rain."

N = 12
n = 0

hourly_chance_of_rain = Array.new
hourly_chance_of_rain_pairs = Array.new

while n < N do
  hourly_chance_of_rain = pirates_parsed.fetch("hourly").fetch("data")[n].fetch("precipProbability")
  hourly_chance_of_rain_pairs[n] = [n, 100 * pirates_parsed.fetch("hourly").fetch("data")[n].fetch("precipProbability")]
  if n == 9
     hourly_chance_of_rain = 0.75
     hourly_chance_of_rain_pairs[n] = [n, 100 * hourly_chance_of_rain]
  end
  if hourly_chance_of_rain >= 0.10
    puts "You might want to carry an umbrella today!"
    puts "There is a #{hourly_chance_of_rain*100}\% chance of rain in #{n} hours."
    break
  end
  n += 1
  if n == N
    puts "It looks like you don't need an umbrella. :cartwheel:"
  end
end

puts AsciiCharts::Cartesian.new(hourly_chance_of_rain_pairs, :bar => true, :hide_zero => false).draw # does not work
