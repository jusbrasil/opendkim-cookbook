#
# Cookbook Name:: opendkim
# Recipe:: default
#
# Copyright 2012, Jeremiah Snapp
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package "opendkim" do
  action :install
end

service "opendkim" do
  supports :restart => true, :reload => true
  action :enable
end

template "/etc/opendkim.conf" do
  source "opendkim.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :reload, resources(:service => "opendkim")
end

directory "/etc/mail" do
  owner "opendkim"
  group "opendkim"
  mode "0700"
  action :create
end

opendkim = data_bag_item("keys", "opendkim")

trusted_servers = search(:node, "role:#{node['opendkim']['trusted_host_role']} AND chef_environment:#{node.chef_environment}").map { |member| "#{member[:fqdn]}" }

template "/etc/opendkim/TrustedHosts" do
  source "TrustedHosts.erb"
  owner "opendkim"
  group "opendkim"
  mode "0600"
  variables(
    :trusted_servers => trusted_servers
  )
  notifies :restart, resource(:service => "opendkim")
end

template "/etc/mail/dkim.key" do
  backup false
  source "dkim.key.erb"
  owner "opendkim"
  group "opendkim"
  mode "0600"
  variables(
    :opendkim_private => opendkim['private']
  )
  notifies :restart, resources(:service => "opendkim")
end
