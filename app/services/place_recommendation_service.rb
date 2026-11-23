require "net/http"
require "uri"
require "json"

class PlaceRecommendationService
  NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
  OVERPASS_URL = ENV.fetch(
  "OVERPASS_URL",
  "https://overpass-api.de/api/interpreter"
)

  SEARCH_RADIUS = 5_000
  MAX_RESULTS = 40

  CATEGORIES = {
    "tourism" => {
      "attraction" => "Достопримечательность",
      "museum" => "Музей",
      "artwork" => "Произведение искусства",
      "gallery" => "Галерея"
    },
    "amenity" => {
      "restaurant" => "Ресторан",
      "cafe" => "Кафе"
    },
    "leisure" => {
      "park" => "Парк",
      "garden" => "Сад"
    }
  }.freeze

  def initialize(destination)
    @destination = destination.to_s.strip
  end

  def call
    return failure("Укажи город назначения в настройках поездки.") if @destination.blank?

    coordinates = geocode_destination

    return failure("Не удалось определить город «#{@destination}». Проверь название места назначения.") unless coordinates

    places = fetch_places(coordinates)

    {
      success: true,
      places: places,
      error: nil
    }
  rescue Net::OpenTimeout, Net::ReadTimeout
    failure("Сервис поиска мест не ответил вовремя. Попробуй ещё раз позже.")
  rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET
    failure("Не удалось подключиться к сервису поиска мест. Проверь интернет-соединение.")
  rescue JSON::ParserError
    failure("Сервис поиска вернул некорректный ответ. Попробуй позже.")
  rescue StandardError => e
    Rails.logger.error("Place recommendation error: #{e.class}: #{e.message}")
    failure("Не удалось загрузить рекомендации. Попробуй позже.")
  end

  private

  def geocode_destination
    uri = URI(NOMINATIM_URL)
    uri.query = URI.encode_www_form(
      q: @destination,
      format: "jsonv2",
      limit: 1,
      "accept-language": "ru"
    )

    response = http_get(uri)

    return nil unless response.is_a?(Net::HTTPSuccess)

    results = JSON.parse(response.body)
    return nil if results.empty?

    {
      latitude: results.first.fetch("lat").to_f,
      longitude: results.first.fetch("lon").to_f
    }
  end

  def fetch_places(coordinates)
    query = build_overpass_query(
      coordinates[:latitude],
      coordinates[:longitude]
    )

    uri = URI(OVERPASS_URL)
    request = Net::HTTP::Post.new(uri)
    request["User-Agent"] = user_agent
    request.set_form_data(data: query)

    response = perform_request(uri, request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Overpass API returned HTTP #{response.code}"
    end

    data = JSON.parse(response.body)

    data.fetch("elements", []).filter_map do |element|
      build_place(element)
    end.uniq { |place| [place[:latitude], place[:longitude]] }
      .first(MAX_RESULTS)
  end

  def build_overpass_query(latitude, longitude)
    filters = CATEGORIES.flat_map do |key, values|
      values.keys.map do |value|
        %([#{key}=#{value}])
      end
    end

    selectors = filters.map do |filter|
      "nwr(around:#{SEARCH_RADIUS},#{latitude},#{longitude})#{filter};"
    end.join("\n")

    <<~QUERY
      [out:json][timeout:25];
      (
        #{selectors}
      );
      out center tags;
    QUERY
  end

  def build_place(element)
    tags = element.fetch("tags", {})
    name = tags["name"] || tags["name:ru"]

    return nil if name.blank?

    latitude = element["lat"] || element.dig("center", "lat")
    longitude = element["lon"] || element.dig("center", "lon")

    return nil unless latitude && longitude

    category = detect_category(tags)

    {
      name: name,
      category: category,
      latitude: latitude.to_f,
      longitude: longitude.to_f
    }
  end

  def detect_category(tags)
    CATEGORIES.each do |key, values|
      category = values[tags[key]]
      return category if category
    end

    "Интересное место"
  end

  def http_get(uri)
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = user_agent

    perform_request(uri, request)
  end

  def perform_request(uri, request)
    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 5,
      read_timeout: 30
    ) do |http|
      http.request(request)
    end
  end

  def user_agent
    "TravelTracker/1.0 (travel planning application)"
  end

  def failure(message)
    {
      success: false,
      places: [],
      error: message
    }
  end
end
