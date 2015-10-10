require 'faraday'
class Feeds
  def initialize(username)
    @base_url = 'https://www.boardgamegeek.com/xmlapi/'
    @username = username
  end

  def user
    conn = Faraday.new
    url = "#{@base_url}/collection/#{@username}?own=1"
    response = Faraday.get(url)
    while response.status.eql?(202) do
      response = Faraday.get(url)
      sleep 10
    end

    response.body
  end

  def game
    site = open("#{@base_url}/boardgame/#{user_games.join(',')}")
    Nokogiri::XML(site)
  end

  private
  def user_games
    games = Nokogiri::XML(user).css('item')
    game_list = []
    games.each do |game|
      game_list << game.css('@objectid')
    end

    game_list
  end
end
