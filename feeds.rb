require 'faraday'
class Feeds
  def initialize(opts)
    @base_url = 'https://www.boardgamegeek.com/xmlapi/'
    @username = opts[:username]
    @players = opts[:players] if opts.key?(:players)
    @age = opts[:age] if opts.key?(:age)
    @length = opts[:length] if opts.key?(:length)
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

  def filters(game)
    filter_state = true
    if @players
      min = game.css('minplayers').text.to_i
      max = game.css('maxplayers').text.to_i
      filter_state = false unless @players.between?(min, max)
    elsif @age
      filter_state = false unless @age >= game.css('age').text.to_i
    elsif @length
      min = game.css('minplaytime').text.to_i
      max = game.css('maxplaytime').text.to_i
      if min.eql?(max)
        filter_state = false unless @length >= min
      else
        filter_state = false unless @length.between?(min, max)
      end
    end

    filter_state
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
