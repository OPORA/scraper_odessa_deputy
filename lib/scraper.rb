require 'open-uri'
require 'nokogiri'
require_relative './people'

class ScrapeMp
  def parser

    url = "http://omr.gov.ua/ua/2432/"
    page = get_page(url)
    page.css('span div table tr td a').each do |mp|
      scrape_mp(mp[:href], mp.text)
    end
    #resigned_mp()
    create_mer()
  end
  def create_mer
    #TODO create mer
    names = %w{Труханов Геннадий Леонидович}
    People.first_or_create(
        first_name: names[1],
        middle_name: names[2],
        last_name: names[0],
        full_name: names.join(' '),
        deputy_id: 1111,
        okrug: nil,
        photo_url: "http://omr.gov.ua/images/Image/2014_2/0_Truhanov/IMG_5640.jpg",
        faction: nil,
        end_date:  nil,
        created_at: "9999-12-31"
    )
  end
  def get_page(url)
    Nokogiri::HTML(open(url, "User-Agent" => "HTTP_USER_AGENT:Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/534.13 (KHTML, like Gecko) Chrome/9.0.597.47"), nil, 'windows-1251')
  end
  def resigned_mp
    #scrape_mp(mp_url, sourse_date )

  end
  def scrape_mp(mp, full_name, date_end = nil )

    if date_end.nil?
      date_end = nil
    else
      date_end = Date.parse(date_end,'%d.%m.%Y')
    end
    if mp[/http:/]
      uri = mp
    else
      uri = "http://omr.gov.ua/ru" + mp
    end
    rada_id =mp.split('/').last[/\d{5}/]
    page_mp= get_page(uri)
    hash = {}
     page_mp.css('.pageText p').each do |p|
       next unless p.text[/(по территориальному округу|округ)/]
       if p.text[/№\d+/]
         hash[:okrug] = p.text[/№\d+/].gsub(/№/,'')
       end
     end
    if full_name == "Квасницкая Ольга Алексеевна"
      party = "САМОПОМОЩЬ"
    elsif full_name == "Киреев Владимир Анатольевич"
      party = "ДОВЕРЯЙ ДЕЛАМ"
    elsif full_name == "Коваль Денис Александрович"
      party = "Оппозиционный блок"
    elsif full_name == "Боровик Александр"
      party = "Внефракционный депутат"
    elsif full_name == "Потапский Алексей Юрьевич"
      party = "БЛОК ПЕТРА ПОРОШЕНКО СОЛИДАРНОСТЬ"
    else
      paragraf = page_mp.css('.shortText b span span').text.split(',').first[/(«|").*(»|")/].gsub(/(«|»|")/,'')
      party = case
                when paragraf[/БЛОК ПЕТРА ПОРОШЕНКО/]
                  "БЛОК ПЕТРА ПОРОШЕНКО"
                when paragraf[/САМОПОМОЩЬ/]
                  "САМОПОМОЩЬ"
                else
                  paragraf
              end
    end
    if not page_mp.css('.pageText img').empty?
      image_html = page_mp.css('.pageText img')[0][:src]
      if image_html[/http:/]
        image = image_html
      else
        image = "http://omr.gov.ua" + image_html
      end
    end
    name_array= full_name.split(' ')
    people = People.first(
         first_name: name_array[1],
         middle_name: name_array[2],
         last_name: name_array[0],
         full_name: name_array.join(' '),
         deputy_id: rada_id,
         okrug: hash[:okrug],
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
           okrug: hash[:okrug],
           photo_url: image,
           faction: party,
           end_date:  date_end,
           created_at: Time.now,
           updated_at: Time.now
       )
    end
  end
end



