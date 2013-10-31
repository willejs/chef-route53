name             "route53"
maintainer       "Heavy Water Software Inc."
maintainer_email "darrin@heavywater.ca"
license          "Apache 2.0"
description      "Installs/Configures route53"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.3.1"

depends "xml"

%w{redhat centos scientific debian ubuntu amazon}.each do |os|
    supports os
end
