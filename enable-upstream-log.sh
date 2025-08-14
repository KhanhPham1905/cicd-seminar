#!/bin/bash

NGINX_CONF="/etc/nginx/nginx.conf"
BACKUP="/etc/nginx/nginx.conf.bak"

# 1. Backup file cũ
echo "[+] Backup file cấu hình cũ..."
sudo cp $NGINX_CONF $BACKUP

# 2. Kiểm tra xem log_format đã được thêm chưa
if grep -q "log_format upstreamlog" $NGINX_CONF; then
    echo "[!] Đã cấu hình log_format rồi. Bỏ qua."
else
    echo "[+] Thêm log_format vào $NGINX_CONF..."

    # Chèn log_format vào trong block http {
    sudo sed -i '/http {/a \ \ \ \ log_format upstreamlog '\''$remote_addr - $host [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" upstream: $upstream_addr, response_time: $upstream_response_time'\'';\n\ \ \ \ access_log /var/log/nginx/access.log upstreamlog;' $NGINX_CONF
fi

# 3. Kiểm tra cấu hình
echo "[+] Kiểm tra cấu hình..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "[!] Lỗi cấu hình. Đã khôi phục bản backup."
    sudo cp $BACKUP $NGINX_CONF
    exit 1
fi

# 4. Reload Nginx
echo "[+] Reload Nginx..."
sudo systemctl reload nginx

# 5. Xem log (live)
echo "[+] Log mới:"
sudo tail -f /var/log/nginx/access.log
