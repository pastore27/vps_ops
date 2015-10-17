# coding: utf-8
#
# Cookbook Name:: mysql
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# インストール済みのMySQLの削除
bash 'remove_installed_mysql' do
  only_if 'yum list installed | grep mysql*'
  user 'root'

  code <<-EOL
    yum remove -y mysql*
  EOL
end

# インストールするパッケージのtarファイルの取得
remote_file "/tmp/#{node['mysql']['file_name']}" do
  source "#{node['mysql']['remote_uri']}"
end

# tarを解凍
bash "install_mysql" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    tar xf "#{node['mysql']['file_name']}"
    rm "#{node['mysql']['file_name']}"
  EOH
end

# パッケージのインストール
node['mysql']['rpm'].each do |rpm|
  package rpm[:package_name] do
    action :install
    source "/tmp/#{rpm[:rpm_file]}"
  end
end

# 設定ファイルの設置
template "my.cnf" do
  path    'etc/my.cnf'
  source  'my.cnf.erb'
  owner   'root'
  group   'root'
  mode    '0644'
end

# サービスの起動
service 'mysql' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

# 初期パスワード設定
script "secure_install" do
  interpreter 'bash'
  user "root"
  not_if "mysql -u root -p#{node[:mysql][:password]} -e 'show databases'"
  code <<-EOL
    export Initial_PW=`head -n 1 /root/.mysql_secret |awk '{print $(NF - 0)}'`
    mysql -u root -p${Initial_PW} --connect-expired-password -e "SET PASSWORD FOR root@localhost=PASSWORD('#{node[:mysql][:password]}');"
    mysql -u root -p#{node[:mysql][:password]} -e "SET PASSWORD FOR root@'127.0.0.1'=PASSWORD('#{node[:mysql][:password]}');"
    mysql -u root -p#{node[:mysql][:password]} -e "FLUSH PRIVILEGES;"
  EOL
end
