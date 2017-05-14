require 'open-uri'
require 'nokogiri'
require_relative './people'

class ScrapeMp
  def parse
    DataMapper.auto_upgrade!
    url = "https://www.lvivrada.gov.ua/deputaty/deputaty-miskoi-rady"
    page = get_page(url)
    page.css('#componentin .catItemTitle a').each do |mp|
      scrape_mp(mp[:href])
    end
    resigned_mp()
    create_mer()
  end
  def create_mer
    #TODO create mer Sadovoy
    names = %w{Садовий Андрій Іванович}
    People.first_or_create(
        first_name: names[1],
        middle_name: names[2],
        last_name: names[0],
        full_name: names.join(' '),
        deputy_id: 1111,
        okrug: nil,
        photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/AndriiSadovyi.JPG/255px-AndriiSadovyi.JPG",
        faction: "Самопоміч",
        end_date:  nil,
        created_at: "9999-12-31",
        updated_at: "9999-12-31"
    )
  end
  def get_page(url)
    Nokogiri::HTML(open(url, "User-Agent" => "HTTP_USER_AGENT:Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/534.13 (KHTML, like Gecko) Chrome/9.0.597.47"), nil, 'utf-8')
  end
  def resigned_mp
    uri = "https://www.lvivrada.gov.ua/deputaty/sklaly-povnovazhennya"
    page_resigned = get_page(uri)
    resigned =  page_resigned.css('.itemFullText table tr')
    resigned.shift
    resigned.each do |tr|
      next if tr.css('td')[0].text.strip == "VII СКЛИКАННЯ"
      break if tr.css('td')[0].text.strip[/СКЛИКАННЯ/]
      mp_url = tr.css('td a')[0][:href]
      sourse_date = tr.css('td')[2].text.strip
      scrape_mp(mp_url, sourse_date )
    end
  end
  def scrape_mp(mp, date_end = nil )
    if date_end.nil?
      date_end = nil
    else
      date_end = Date.parse(date_end,'%d.%m.%Y')
    end
    if mp[/https:/]
      uri = mp
    else
      uri = "https://lvivrada.gov.ua" + mp
    end
    rada_id =mp.split('/').last[/\d{4}/]
    page_mp= get_page(uri)
    name = page_mp.css('h2.itemTitle').text.gsub(/\n/,'').strip
    image_html = page_mp.css('.itemIntroText p a')[0]
    if image_html.nil?
      image = "https://lvivrada.gov.ua" + page_mp.css('.itemIntroText p img')[0][:src]
    else
      image = "https://lvivrada.gov.ua" + page_mp.css('.itemIntroText p a')[0][:href]
    end
    p uri
    p name
    hash = {}
    page_mp.css('.itemFullText p').each do |p|

      next  unless  p.text[/(округ №|округ№)/] or p.text[/(Висунутий|Висунута)/]

      if p.text[/(округ №|округ№)(\s|\d)/]
        hash[:okrug]= p.text[/№(\s|\d)\d+/]
      end
      if p.text[/исунут/]
        ser=p.text.split('.').find{|str| str.include?('исунут')}
        hash[:party ] = ser[/(“|«).+(”|»)/].gsub(/(“|”|»|«)/,'')
      end
    end
    p hash[:party]
    p hash[:okrug]
    if hash[:party].include?("УКРОП")
      party = "УКРОП"
    elsif hash[:party].include?("Народний контроль")
      party = "Народний контроль"
    elsif hash[:party].include?("Солідарність") or  hash[:party].include?("СОЛІДАРНІСТЬ")
      party = "Блок Петра Порошенка"
    elsif hash[:party].include?("Самопоміч")
      party = "Самопоміч"
    elsif hash[:party].include?("галицька партія")
      party = "Українська Галицька Партія"
    else
      party = hash[:party].strip
    end
    if name == 'Веремчук Валерій Миколайович' or name == 'Адамик Петро Михайлович' or name == 'Береза Олег Ігорович'
      okrug = nil
    else
      okrug = hash[:okrug].strip.gsub(/([[:blank:]]|№)/,'')
    end

    name_array= name.split(' ')
    people = People.first(
        first_name: name_array[1],
        middle_name: name_array[2],
        last_name: name_array[0],
        full_name: name_array.join(' '),
        deputy_id: rada_id,
        okrug: okrug,
        photo_url: image,
        faction: party,
    )
    unless people.nil?
    people.update(end_date:  date_end,  updated_at: Time.now)
    else
      People.create(
          first_name: name_array[1],
          middle_name: name_array[2],
          last_name: name_array[0],
          full_name: name_array.join(' '),
          deputy_id: rada_id,
          okrug: okrug,
          photo_url: image,
          faction: party,
          end_date:  date_end,
          created_at: Time.now,
          updated_at: Time.now
      )
    end
  end
end
unless ENV['RACK_ENV']
  ScrapeMp.new
end


