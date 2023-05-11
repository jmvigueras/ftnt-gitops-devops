curl --location 'https://api.fortiweb-cloud.com/v1/application' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic ${token}' \
--data '{
"app_name": "${app_name}",
"domain_name": "${app_name}.${zone_name}",
"custom_port":{
"http":80,
"https":443
},
"cdn_status": 0,
"region": "${region}",
"platform": "AWS",
"block_mode": 0,
"service": ["http"],
"server_address": "${server_ip}",
"server_port": ${server_port},
"server_type": "http",
"server_country": "Ireland",
"head_availability": 1,
"extra_domains": [],
"head_status_code": 404,
"template_id": "${template_id}"
}' | jq -r '.domain_info[].dns' >> ${file_name}