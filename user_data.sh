#!/bin/bash
# Get instance details from the metadata service (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
IID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Build the web page
mkdir -p /var/www
cat > /var/www/index.html <<EOF
<h1>Hello from the 3-tier app</h1>
<p>Instance: $IID</p>
<p>Availability Zone: $AZ</p>
EOF

# Run Python's web server as a service, so it restarts automatically
cat > /etc/systemd/system/webapp.service <<'EOF'
[Unit]
Description=Simple web server
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 80 --directory /var/www
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now webapp