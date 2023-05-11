config firewall vip
edit "vip-${mapped_ip}-${suffix}"
set extip ${external_ip}
set mappedip ${mapped_ip}
set extintf "any"
set portforward enable
set extport ${external_port}
set mappedport ${mapped_port}
next
end

config firewall policy
edit 0
set name "vip-${external_ip}-${suffix}"
set srcintf "${public_port}"
set dstintf "${private_port}"
set action accept
set srcaddr "all"
set dstaddr "vip-${mapped_ip}-${suffix}"
set schedule "always"
set service "ALL"
set utm-status enable
set ssl-ssh-profile "certificate-inspection"
set ips-sensor "all_default_pass"
set application-list "default"
set logtraffic all
set nat enable
next
end