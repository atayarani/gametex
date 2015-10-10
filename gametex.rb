#!/usr/bin/env ruby
require 'nokogiri'
require 'csv'
require 'json'
require 'erb'
require 'open-uri'
require 'htmlentities'
require 'sanitize'

def user_games
  game_filename = './collection.csv'
  game_file = File.read(game_filename)
  game_list = []
  csv = CSV.new(game_file, headers: true, header_converters: :symbol)
  csv.to_a.each do |column|
    game_list << column[1]
  end

  game_list
end

def data_feed
  site = open('./game.xml')
  Nokogiri::XML(site)
end

def build_url(game_list)
  base_url = 'https://www.boardgamegeek.com/xmlapi/boardgame'
  "#{base_url}/#{game_list.join(',')}"
end

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

doc = data_feed
games = doc.css('boardgame')
game_hash = {}
games.each do |game|
  game_name = game.css('name[primary="true"]').text.gsub('&'){'\&'}
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
