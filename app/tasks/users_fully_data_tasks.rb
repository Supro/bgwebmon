# coding: utf-8
require 'net/scp'
require 'net/ssh'

class UsersFullyDataTasks

  #deviceId = this is NAS id
  #ipResourceId - show into module Inet -> IP resourses
  #current_template  - It looks like the module Inet
  #right_template - as it should be in dokuwiki

  def self.data_by_node
    generate_data(12, 22, '10.22.186', '172.28.186')  #Красногорка
    #generate_data(12, 23, '10.22.187', '172.28.187')  #Виноградное
    generate_data(12, 24, '10.22.190', '172.28.190')   #Семисотка
    generate_data(12, 25, '10.22.192', '172.28.192')   #Новониколаевка
    generate_data(12, 26, '10.22.193', '172.28.193')   #Ленинское
    generate_data(12, 99, '10.22.195', '172.28.195')  #Вишневое PPPoE
    generate_data(12, 28, '10.22.199', '172.28.199')   #Семеновка
    generate_data(12, 29, '10.10.230', '172.28.230')   #Симферополь PPPtP
    #generate_data(12, 30, '10.10.231', '172.28.204')  #Симферополь PPtP
    #generate_data(12, 34, '10.10.233', '172.28.197')  #Вишневое PPPtP
    generate_data(12, 100, '10.22.196', '172.28.196')  #Вишневое PPPoE secondary
    generate_data(12, 76, '10.22.183', '172.28.183')   #Семеновка secondary
    generate_data(12, 78, '10.22.172', '172.28.172')   #Фронтовое
    generate_data(12, 79, '10.22.174', '172.28.174')   #Соленое
    generate_data(12, 80, '10.22.176', '172.28.176')   #Фонтан
    generate_data(12, 81, '10.22.178', '172.28.178')   #Щелкино-Мысовое
    generate_data(12, 82, '10.22.180', '172.28.180')   #Каменское
    generate_data(12, 83, '10.22.164', '172.28.164')   #Новониколаевка - водохранилище
    generate_data(12, 88, '10.22.168', '172.28.168')   #Песочное
    generate_data(12, 87, '10.22.110', '172.28.110')   #Sev58 Vlan 301
    generate_data(12, 86, '10.22.111', '172.28.111')   #Sam5b Vlan 302
    generate_data(12, 90, '10.22.112', '172.28.112')   #Rlux  Vlan 303
    generate_data(12, 92, '10.22.113', '172.28.113')   #Shelf  Vlan 304
    generate_data(12, 98, '10.22.114', '172.28.114')   #Simferopol area  Vlan 305
    generate_data(12, 91, '10.22.166', '172.28.166')   #Белинское
    generate_data(12, 93, '10.22.184', '172.28.184')   #Ерофеево
    generate_data(12, 94, '10.22.185', '172.28.185')   #Южное
    generate_data(12, 67, '10.22.194', '172.28.194')   #Останино Vlan 910
  end

  def self.generate_data device, resourse, current_template, right_template
    #download file wiki
    download_file_wiki(right_template)

    #copy title in file
    content = copy_file_title(right_template)

    data = ip_resourse(device, resourse)
    total_data = data.map do |d|
      "|[[http://#{d.addressFrom.to_s.bytes.to_a.join('.').gsub(current_template, right_template)}|#{d.addressFrom.to_s.bytes.to_a.join('.').gsub(current_template, right_template)}]]" +
       "|#{ContractParameterType1.where(cid: d.contractId, pid: 71).map {|x| x.val}.first} " +
       "|#{ContractParameterType7Value.where(id: "#{ContractParameterType7.where(cid: d.contractId, pid: 68).map {|x| x.val}.first}").map {|x| x.title }.first} " +
       "| " +
       "|#{Contract.find(d.contractId).title}" +
       "|#{Contract.find(d.contractId).comment}" +
       "|#{d.login}:#{d.password}" +
       "|#{d.comment} |"
    end

    total_data = total_data.sort_by! {|ip| ip.split('.').map{ |octet| octet.to_i} }

    #Create file and push data to file
    #create_file_and_push_data(right_template)
    File.open("#{right_template}.0_robot.txt", "w"){|file| file.write content + "\n" }
    File.open("#{right_template}.0_robot.txt", "a"){|file| file.write total_data.join("\n") }
    File.open("#{right_template}.0_robot.txt", "a"){|file| file.write "\n" }

    #send file to dokuwiki server
    transfer_file_to_wikki(right_template)

    #delete file on rails app root
    delete_all_files(right_template)
  end

  def self.download_file_wiki(right_template)
    host = ENV["REMOTE_WIKI_HOST"]
    username = ENV["REMOTE_WIKI_USER"]
    password = ENV["REMOTE_WIKI_PASSWORD"]

    Net::SSH.start(host, username, password: password) do |ssh|
      ssh.scp.download! "/var/lib/dokuwiki/data/pages/ip-fake/#{right_template}.0_head.txt", "."
    end
  end

  def self.copy_file_title right_template
    IO.read("#{right_template}.0_head.txt")
  end

  #def self.create_file_and_push_data right_template
    #File.open("#{right_template}.0_robot.txt", "w"){|file| file.write content + "\n" }
    #File.open("#{right_template}.0_robot.txt", "a"){|file| file.write total_data.join("\n") }
    #File.open("#{right_template}.0_robot.txt", "a"){|file| file.write "\n" }
  #end

  def self.transfer_file_to_wikki right_template
    host = ENV["REMOTE_WIKI_HOST"]
    username = ENV["REMOTE_WIKI_USER"]
    password = ENV["REMOTE_WIKI_PASSWORD"]

    Net::SCP.start(host, username, password: password) do |scp|
      scp.upload("#{right_template}.0_robot.txt", "/var/lib/dokuwiki/data/pages/ip-fake/")
    end
  end

  def self.delete_all_files right_template
    File.delete("#{right_template}.0_head.txt")
    File.delete("#{right_template}.0_robot.txt")
  end

  #search data in module Inet by deviceId and ipResourceId
  def self.ip_resourse device, resourse
    InetService.where(deviceId: device, ipResourceId: resourse)
  end
end
