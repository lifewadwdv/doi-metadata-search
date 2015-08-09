#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright 2014, 2015 Bloomberg Finance L.P.
#
include_recipe 'selinux::permissive'

if node['firewall']['allow_consul']
  include_recipe 'firewall::default'

  firewall_rule 'consul' do
    protocol :tcp
    port node['consul']['config']['ports'].values
    action :allow
  end
end

poise_service_user node['consul']['service_user'] do
  group node['consul']['service_group']
  action :create
end

config = consul_config node['consul']['service_name'] do |r|
  user node['consul']['service_user']
  group node['consul']['service_group']

  node['consul']['config'].each_pair { |k, v| r.send(k, v) }
end

consul_service node['consul']['service_name'] do |r|
  user node['consul']['service_user']
  group node['consul']['service_group']
  version node['consul']['version']
  config_file config.path

  node['consul']['service'].each_pair { |k, v| r.send(k, v) }
  subscribes :restart, "consul_config[#{config.name}]", :delayed
  action [:create, :enable]
end
