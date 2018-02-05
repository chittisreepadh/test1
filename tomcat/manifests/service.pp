# Definition: tomcat::service
#
# Service management for Tomcat.
#
define tomcat::service (
  $catalina_home                    = undef,
  $catalina_base                    = undef,
  Boolean $use_service              = true,
  Boolean $use_init                 = true,
  #$java_home                        = undef,
  $service_ensure                   = running,
  Optional[Boolean] $service_enable = undef,
  $service_name                     = undef,
  $start_command                    = undef,
  $stop_command                     = undef,
  $user                             = undef,
) {
  include ::tomcat
  $_user = pick($user, $::tomcat::user)
  # XXX Backwards compatibility: If the user declares a base but not a home, we
  # assume they are in compatibility mode
  if $catalina_base {
    $_catalina_home = pick($catalina_home, $catalina_base)
  } else {
    $_catalina_home = pick($catalina_home, $tomcat::catalina_home)
  }
  $_catalina_base = pick($catalina_base, $_catalina_home) #default to home
  tag(sha1($_catalina_home))
  tag(sha1($_catalina_base))



  if $use_service and $use_init {
    $_service_name = "${name}"
    $_hasstatus    = true
    $_hasrestart   = true
    $_start        = "service ${name} start"
    $_stop         = "service ${name} stop"
    $_status       = "service ${name} status"
    $_provider     = undef
    # Template uses:
    # - $_catalina_home
    # - $_catalina_base
    # - $java_home
    # - $_user
    file { "/etc/init.d/${name}":
      mode    => '0755',
      content => template('tomcat/service-init.erb'),
    }
    file { "/usr/lib/systemd/system/${name}.service":
      mode    => '0755',
      content => template('tomcat/tomcatservice.erb'),
    }

  
  } elsif $use_init {
    $_service_name = $service_name
    $_hasstatus    = true
    $_hasrestart   = true
    $_start        = $start_command
    $_stop         = $stop_command
    $_status       = undef
    $_provider     = undef
  } else {
    $_service_name = "${name}"
    $_hasstatus    = false
    $_hasrestart   = false
    $_start        = $start_command ? {
      undef   => "su -s /bin/bash -c 'CATALINA_HOME=${_catalina_home} CATALINA_BASE=${_catalina_base} ${_catalina_home}/bin/catalina.sh start' ${_user}", # lint:ignore:140chars
      default => $start_command
    }
    $_stop         = $stop_command ? {
      undef   => "su -s /bin/bash -c 'CATALINA_HOME=${_catalina_home} CATALINA_BASE=${_catalina_base} ${_catalina_home}/bin/catalina.sh stop' ${_user}", # lint:ignore:140chars
      default => $stop_command
    }
    $_status       = "ps aux | grep 'catalina.base=${_catalina_base} ' | grep -v grep"
    $_provider     = 'base'
  }

  if $use_init {
    if $service_enable != undef {
      $_service_enable = $service_enable
    } else {
      $_service_enable = $service_ensure ? {
        'running' => true,
        true      => true,
        default   => undef,
      }
    }
  } else {
    $_service_enable = undef
  }

  service { $_service_name:
    ensure     => $service_ensure,
    enable     => $_service_enable,
    hasstatus  => $_hasstatus,
    hasrestart => $_hasrestart,
    start      => $_start,
    stop       => $_stop,
    status     => $_status,
    provider   => $_provider,
  }
}
