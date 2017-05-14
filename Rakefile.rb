require_relative 'lib/scraper'
desc 'Create databases'
task :create_db do
  DataMapper.auto_migrate!
end
desc 'Scrape mp all'
task :scrape_mp do
  ScrapeMp.new.parser
end
