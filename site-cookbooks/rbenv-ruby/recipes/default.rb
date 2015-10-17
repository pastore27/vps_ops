#
# Cookbook Name:: rbenv-ruby
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'git'

# gcc-c++はtherubyracerのインストールに必須
# libxml2-devel、libxslt-develはnokogiriのインストールに必須
%w(gcc openssl-devel readline-devel gcc-c++ libxml2-devel libxslt-devel).each do |pkg|
  package pkg do
    action :install
  end
end

git "/usr/local/rbenv" do
  not_if "test -d #{name}"
  repository "git://github.com/sstephenson/rbenv.git"
  reference  "master"
  revision   node[:rbenv][:revision]
  action     :checkout
  user       "root"
  group      "root"
end

directory "/usr/local/rbenv/plugins" do
  owner  "root"
  group  "root"
  mode   "0755"
  action :create
end

template "/etc/profile.d/rbenv.sh" do
  owner "root"
  group "root"
  mode  0644
end

git "/usr/local/rbenv/plugins/ruby-build" do
  not_if "test -d #{name}"
  repository "git://github.com/sstephenson/ruby-build.git"
  reference  "master"
  revision   node[:ruby_build][:revision]
  action     :checkout
  user       "root"
  group      "root"
end

execute "install ruby" do
  not_if "source /etc/profile.d/rbenv.sh; rbenv versions | grep #{node[:rbenv][:build]}"
  command "source /etc/profile.d/rbenv.sh; CONFIGURE_OPTS=\"--with-readline-dir=/usr/include/readline\" rbenv install #{node[:rbenv][:build]}"
  action :run
end

execute "install bundler" do
  not_if "source /etc/profile.d/rbenv.sh; rbenv shell #{node[:rbenv][:build]}; gem list | grep bundler"
  command "source /etc/profile.d/rbenv.sh; rbenv shell #{node[:rbenv][:build]}; gem i bundler -v '#{node[:rbenv][:bundler]}' --no-ri --no-rdoc; rbenv rehash"
  action :run
end

execute "set ruby version" do
  command "source /etc/profile.d/rbenv.sh; rbenv global #{node[:rbenv][:build]}; rbenv rehash"
  action :run
end

# railsのインストール
execute "install rails" do
  not_if "source /etc/profile.d/rbenv.sh; rbenv shell #{node[:rbenv][:build]}; gem list | grep rails"
  command "source /etc/profile.d/rbenv.sh; rbenv exec gem install rails -v 4.1.7; rbenv rehash"
  action :run
end

# mysql2のインストール
execute "install mysql2" do
  not_if "source /etc/profile.d/rbenv.sh; rbenv shell #{node[:rbenv][:build]}; gem list | grep mysql2"
  command "source /etc/profile.d/rbenv.sh; rbenv exec gem install mysql2; rbenv rehash"
  action :run
end

# therubyracerのインストール
execute "install therubyracer" do
  not_if "source /etc/profile.d/rbenv.sh; rbenv shell #{node[:rbenv][:build]}; gem list | grep therubyracer"
  command "source /etc/profile.d/rbenv.sh; rbenv exec gem install therubyracer; rbenv rehash"
  action :run
end

# nokogiriのインストール
execute "install nokogiri" do
  not_if "source /etc/profile.d/rbenv.sh; rbenv shell #{node[:rbenv][:build]}; gem list | grep nokogiri"
  command "source /etc/profile.d/rbenv.sh; rbenv exec gem install nokogiri -- --use-system-libraries=true --with-xml2-include=/usr/include/libxml2/; rbenv rehash"
  action :run
end

# social_counterのインストール
execute "install social_counter" do
  not_if "source /etc/profile.d/rbenv.sh; rbenv shell #{node[:rbenv][:build]}; gem list | grep social_counter"
  command "source /etc/profile.d/rbenv.sh; rbenv exec gem install social_counter; rbenv rehash"
  action :run
end

bash "insert_rbenv_line" do
  user "root"
  code <<-EOS
    echo 'export RBENV_ROOT="/usr/local/rbenv"' >> /etc/profile
    echo 'export PATH="${RBENV_ROOT}/bin:${PATH}"' >> /etc/profile
    echo 'eval "$(rbenv init -)"' >> /etc/profile
    source /etc/profile
  EOS
end
