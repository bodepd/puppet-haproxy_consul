# This has been shamelessly lifed from stacktira
# Other parts have been liften from puppetlabs-haproxy
#
# This module sets up the configuration of haproxy.
# Most of the configuration is statically defined by
# puppet, except the actual endpoints, which are read in
# from consul-template.
#
# backends is a hash of the following form:
#   name => options
#   where options can have the following keys:
#     vip, ports, mode, listen_options, options, service_name
#
class haproxy_consul(
  $logfile                 = '/var/log/haproxy.log',
  $log_level               = '127.0.0.1 local0 notice',
  $default_log_level       = 'global',
  $default_mode            = 'http',
  $default_options         = ['httplog', 'dontlognull', 'redispatch'],
  $default_retries         = 3,
  $default_maxconn         = 5000,
  $default_timeout_connect = 20000,
  $default_timeout_client  = 20000,
  $default_timeout_server  = 20000,
  $errorfile               = [
                              '400 /etc/haproxy/errors/400.http',
                              '403 /etc/haproxy/errors/403.http',
                              '408 /etc/haproxy/errors/408.http',
                              '500 /etc/haproxy/errors/500.http',
                              '502 /etc/haproxy/errors/502.http',
                              '503 /etc/haproxy/errors/503.http',
                              '504 /etc/haproxy/errors/504.http'
                            ],
  $global_maxconn          = 5000,
  $stats                   = 'socket /var/run/haproxy mode 777',
  $consul_wait             = '5s:30s',
  $consul_log_level        = 'debug',
  $backends                = {},
) {

  $defaults_options = {
    'log'        => $default_log_level,
    'mode'       => $default_mode,
    'option'     => $default_options,
    'retries'    => $default_retries,
    'maxconn'    => $default_maxconn,
    'timeout'    => [ "connect ${default_timeout_connect}",
                      "client ${default_timeout_client}",
                      "server ${default_timeout_server}" ],
    'errorfile'  => $errorfile,
  }

  $global_options = {
    'log'       => $log_level,
    'maxconn'   => $global_maxconn,
    'user'      => 'haproxy',
    'group'     => 'haproxy',
    'daemon'    => '',
    'quiet'     => '',
    'stats'     => $stats,
  }

  package { 'haproxy':
    ensure => installed,
  }

  service { 'haproxy':
    ensure  => running,
    enable  => true,
    require => [Package['haproxy'], Service['consul-template']],
  }

  class { 'consul_template':
    init_style     => 'upstart',
    log_level      => $consul_log_level,
    consul_wait    => $consul_wait,
  }

  consul_template::watch { 'haproxy':
    template      => 'haproxy_consul/haproxy.cfg.erb',
    destination   => '/etc/haproxy/haproxy.cfg',
    command       => '/etc/init.d/haproxy reload',
  }

}
