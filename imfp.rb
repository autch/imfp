#!/usr/bin/env ruby

require './boot'

URL_LOGIN = "https://www.iijmio.jp/auth/login.jsp"

iijmio_user = YAML.load(File.read("config/iijmio.yml"))

agent = Mechanize.new

page = agent.get(URL_LOGIN)

login_form = page.forms.first
login_form.j_username = iijmio_user["username"]
login_form.j_password = iijmio_user["password"]
page = agent.submit(login_form, login_form.buttons.first)

page = agent.page.link_with(:href => '/service/setup/hdd/viewdata/').click

page.forms.each do |form|
  hdoCode = form.hdoCode

  pp = agent.submit(form, form.buttons.first)

  #File.open("#{hdoCode}.html", "wb:Shift_JIS") do |f|
  #  body = pp.body.force_encoding("Shift_JIS")
  #  f.write body
  #end

  heading = pp.parser.css(".item2").text.gsub(/(^\s+)|(\s+)$/, '')
  heading_hash = Hash[%w(tel iccid sim_type).zip(heading.split(/\n/))]

  daily_usage = pp.parser.css(".base2 tr").map{|tr| tr.css(".data2-c").map{|td| td.text.strip } }.reject{|i| i.empty? }
  daily_usage_hash = daily_usage.map do |day|
    date = Time.strptime(day[0], '%Y年%m月%d日')
    lte_3g = day[1].gsub(/MB/, '').to_i
    limited_200k = day[2].gsub(/MB/, '').to_i

    { "date" => date.strftime("%Y-%m-%d"),
      "lte_3g" => lte_3g,
      "limited_200k" => limited_200k }
  end

  DailyUsage.transaction do
    now = Time.now
    hc = Sim.where(hdo_code: hdoCode).first || Sim.new
    hc.hdo_code = hdoCode
    hc.phone_number = heading_hash["tel"]
    hc.iccid = heading_hash["iccid"]
    hc.sim_type = heading_hash["sim_type"]
    hc.save!

    daily_usage_hash.each do |day|
      usage = DailyUsage.where(hdo_code: hc, date: day["date"]).first || DailyUsage.new
      usage.hdo_code = hc
      usage.date = day["date"]
      usage.lte_3g = day["lte_3g"]
      usage.limited_200k = day["limited_200k"]
      usage.last_checked = now
      usage.save!
    end
  end
end
