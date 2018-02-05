class unzip::install inherits unzip {

file {'unzip-distrib':
    path      => "${distribsfolder}/${zip_file}",
    source    => "puppet:///ficodistribs/${zip_file}",
    }
    
package {'unzip-6.0-16.el7.x86_64':
    ensure          => installed,
    provider        => "rpm",
    install_options => ["-Uvh"],
    source          => "${distribsfolder}/${zip_file}",
    require         => File["unzip-distrib"],
   }
}
