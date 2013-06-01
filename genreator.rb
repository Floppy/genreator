#!/usr/bin/env ruby

require 'taglib'
require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'yaml'

def file_list
  @file_list ||= begin
    root_dir = ARGV[0]
    Dir.glob(File.join(root_dir, "**", "*.mp3"))
  end
end

def artist_list
  print 'building artist list'
  artists = file_list.map do |filename|
    print '.'
    TagLib::FileRef.open(filename) do |file|
      file.nil? ? nil : file.tag.artist
    end
  end.uniq.compact
end

def musicbrainz_id(artist)
  print ' - searching musicbrainz: '
  search_url = "http://musicbrainz.org/ws/2/artist?query=artist:#{CGI.escape(artist.delete("!"))}"
  puts search_url
  xml = Nokogiri::XML(open(search_url))
  xml.remove_namespaces!
  xml.xpath("//artist").each do |artist|
    if artist['score'].to_i >= 95
      puts artist.xpath("name/text()").to_s
      return artist['id']
    end
  end
  puts 'FAILED'
  nil
end

def wikpedia_title(musicbrainz_id)
  sleep(1)
  print ' - finding wikipedia page: '
  musicbrainz_url = "http://musicbrainz.org/ws/2/artist/#{musicbrainz_id}?inc=url-rels"
  xml = Nokogiri::XML(open(musicbrainz_url))
  xml.remove_namespaces!
  w = xml.xpath("//relation[@type='wikipedia']/target/text()").first
  if w
    title = w.to_s.split('/').last
    puts title
    return title
  end
  puts 'FAILED'
  nil
end

def wikipedia_genres(title)
  print ' - fetching wikipedia data: '
  wikipedia_url = "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{title}&rvprop=content&format=xml"
  xml = Nokogiri::XML(open(wikipedia_url))
  xml.remove_namespaces!
  content = xml.xpath("//rev/text()").first
  if content
    content.to_s.match /\|\s*genre\s*=\s*(.*)/ do |genre_string|
      if genre_string[1]
        genre_list = []
        genre_string[1].scan /\[\[(\w.*?)\]\]/ do |match|
          str = match[0].split("|")[0]
          str.gsub!(" music", "")
          genre_list << str.downcase
        end
        puts genre_list.join(', ')
        return genre_list
      end
    end
  end
  puts 'FAILED'
  []
end


def genres(artist)
  puts "fetching genre data for #{artist}"
  id = musicbrainz_id(artist)
  if id
    title = wikpedia_title(id)
    if title
      genres = wikipedia_genres(title)
    end
  end
end

# DO IT


begin
  
  artists = artist_list

  saved_genres = begin 
    YAML::load_file "artists.yml"
  rescue
    {}
  end

  artist_genres = {}
  artists.each do |artist|
    artist_genres[artist] = saved_genres[artist] || genres(artist)
  end


  genre_counts = {}
  artist_genres.values.each do |genres|
    if genres
      genres.each do |genre|
        genre_counts[genre] ||= 0
        genre_counts[genre] += 1
      end
    end
  end

  artist_genres.each_pair do |artist, genres|
    if genres
      genres = genres.sort_by do |genre|
        genre_counts[genre]
      end
      puts "Assigning #{artist} to: #{genres.first}"
    end
  end

rescue

  # Save artist data to YAML file
  File.open("artists.yml", "w") do |file|
    file.write artist_genres.to_yaml
  end

  raise
end
