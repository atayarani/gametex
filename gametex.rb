#!/usr/bin/env ruby
require 'csv'
require 'json'
require 'erb'
require 'open-uri'
require 'nokogiri'
require 'htmlentities'
require 'sanitize'
require 'trollop'
require_relative './feeds.rb'

def keywords(game)
  mechanics = game.css('boardgamemechanic').map(&:text).join(', ')
  categories = game.css('boardgamecategory').map(&:text).join(', ')
  if mechanics.empty?
    categories
  elsif categories.empty?
    mechanics
  else
    "#{mechanics}, #{categories}"
  end
end

def write_file(game_hash)
  ERB.new(File.new('./gametex.erb').read, nil, '-').result(binding)
end

def decode_html(html)
  HTMLEntities.new.decode(html).gsub('<br/>', "\n").gsub('&'){'\&'}.gsub('#', '\#').gsub('&gt;', '>')
end

opts = Trollop.options do
  # Set help message
  usage '[options]'
  synopsis 'This command generates a menu or book of games owned by the user specified'
  opt :username, 'The boardgamegeek.com username whose collection you want to parse', type: :string, required: true
  opt :age, 'The age of the youngest player playing', type: :int
  opt :players, 'The number of players playing', type: :int
  opt :length, 'The number of minutes for the game', type: :int
end

@feeds = Feeds.new(opts)
doc = @feeds.game
games = doc.css('boardgame')
game_hash = {}
games.each do |game|
  game_name = game.css('name[primary="true"]').text.gsub('&'){'\&'}
  next unless @feeds.filters(game)
  game_hash[game_name] = {
    description: decode_html(Sanitize.fragment(game.css('description').text)),
    minplayers: game.css('minplayers').text,
    maxplayers: game.css('maxplayers').text,
    age: game.css('age').text,
    mechanics: keywords(game),
    minplay: game.css('minplaytime').text,
    maxplay: game.css('maxplaytime').text
  }
end


puts write_file(game_hash)
