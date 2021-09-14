#!/bin/bash

blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

install_panel(){
if cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	red "======================================="
	red "本脚本仅仅支持：Debian9+ / Ubuntu16.04+"
	red "======================================="	
	exit 1
else	
	apt-get update -y
    apt install -y curl
    green "======================="
	blue "请输入绑定到本VPS的域名"
	green "======================="
	read your_domain
	real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
	local_addr=`curl ipv4.icanhazip.com`
	green " "
	green " "
	green "================================================="
	 blue "    检测到域名解析地址为 $real_addr"
	 blue "             本VPS的IP为 $local_addr"
	green "================================================="
	sleep 2s
if [ $real_addr == $local_addr ] ; then
	green "================================================="
	blue "        现在开始更新系统并安装必要组件"
	green "================================================="
	sleep 2s
	apt update -y
		if cat /etc/issue | grep -Eqi "ubuntu"; then
			apt install -y software-properties-common
			yes | add-apt-repository ppa:ondrej/php
			apt update -y
			apt install -y expect nginx curl socat sudo git unzip wget  mariadb-server php7.2-fpm php7.2-mysql php7.2-cli php7.2-xml php7.2-json php7.2-mbstring php7.2-tokenizer php7.2-bcmath
		else
			apt -y install software-properties-common apt-transport-https lsb-release ca-certificates
			wget -O /etc/apt/trusted.gpg.d/php.gpg https://mirror.xtom.com.hk/sury/php/apt.gpg
			sh -c 'echo "deb https://mirror.xtom.com.hk/sury/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'   
			apt update -y
			apt install -y expect nginx curl socat sudo git unzip wget  mariadb-server php7.2-fpm php7.2-mysql php7.2-cli php7.2-xml php7.2-json php7.2-mbstring php7.2-tokenizer php7.2-bcmath
		fi
if test -s /etc/php/7.2/cli/php.ini; then
	green "================================================="
	blue "           开始安装官方的Trojan服务"
	green "================================================="
	sleep 2s
	yes | sudo bash -c "$(wget -O- https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
	trojan_passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
cat > /usr/local/etc/trojan/config.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/usr/local/etc/trojan/cert.crt",
        "key": "/usr/local/etc/trojan/private.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "alpn_port_override": {
            "h2": 81
        },
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": true,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": "$trojan_passwd",
        "cafile": ""
    }
}
EOF
	systemctl enable nginx
	systemctl enable trojan
	green "========================="
	blue "     开始申请证书"
	green "========================="
	sleep 2s
cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    server {
        listen       80;
        server_name  $your_domain;
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    }
}
EOF
	systemctl restart nginx
	curl https://get.acme.sh | sh
  ~/.acme.sh/acme.sh  --register-account  -m myemail@example.com --server zerossl
	~/.acme.sh/acme.sh --issue -d $your_domain --nginx
	~/.acme.sh/acme.sh --installcert -d $your_domain --key-file /usr/local/etc/trojan/private.key --fullchain-file /usr/local/etc/trojan/cert.crt
	~/.acme.sh/acme.sh --upgrade --auto-upgrade
	chmod -R 755 /usr/local/etc/trojan
	if test -s /usr/local/etc/trojan/cert.crt; then
		green " "
		green " "
		green "==========================="
		 blue "      证书申请成功"
		green "==========================="
		sleep 2s
	else
		green " "
		green " "
		green "==========================="
		  red "     证书申请失败"
		green "==========================="
		exit 1
	fi
	green " "
	green " "
	green "========================="
	blue "     开始配置数据库"
	green "========================="
	sleep 2s

/usr/bin/expect << EOF
spawn mysql_secure_installation
expect "password for root" {send "$trojan_passwd\r"}
expect "root password" {send "n\r"}
expect "Remove anonymous users" {send "y\r"}
expect "Disallow root login remotely" {send "y\r"}
expect "Remove test database and access to it" {send "y\r"}
expect "Reload privilege tables now" {send "y\r"}
spawn mysql -u root -p
expect "Enter password" {send "$trojan_passwd\r"}
expect "none" {send "CREATE DATABASE trojan;\r"}
expect "none" {send "GRANT ALL PRIVILEGES ON trojan.* to trojan@'%' IDENTIFIED BY '$trojan_passwd';\r"}
expect "none" {send "quit\r"}
EOF

	green " "
	green " "
	green "========================================="
	blue "   开始部署Panel相关服务，此过程耐心等待！"
	green "========================================="
	sleep 2s
	cd /var/www
	curl -sS https://getcomposer.org/installer -o composer-setup.php
	php composer-setup.php --install-dir=/usr/local/bin --filename=composer
	curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
	apt install -y nodejs
	git clone https://github.com/trojan-gfw/trojan-panel.git
	cd trojan-panel
	composer install
	npm install
	rm -rf /var/www/trojan-panel/.env
	wget https://raw.githubusercontent.com/V2RaySSR/Trojan_Panel/master/.env
	php artisan key:generate
	sed -i "s/your_domain/$your_domain/;" /var/www/trojan-panel/.env
	sed -i "s/your_password/$trojan_passwd/;" /var/www/trojan-panel/.env
	green " "
	green " "
	green "====================================================="
	  red "  接下来会提示输入 YES/NO，请输入 y 或者 yes 之后回车"
	green "====================================================="
    read -s -n1 -p "看清提示并请做好输入准备，准备好了请按任意键继续 ... "
	php artisan migrate
	chown -R www-data:www-data /var/www/trojan-panel
	green "========================================="
	blue "       开始配置Nginx以及Panel参数"
	green "========================================="
	sleep 2s
	cd /etc/nginx/sites-available
	rm -rf /etc/nginx/sites-available/default
	wget -P /etc/nginx/sites-available https://raw.githubusercontent.com/V2RaySSR/Trojan_Panel/master/default
	sed -i "s/your_domain/$your_domain/;" /etc/nginx/sites-available/default
	sed -i "s/vps_ip/$local_addr/;" /etc/nginx/sites-available/default
	systemctl restart nginx
	cd /root
	rm -rf /etc/nginx/nginx.conf
	wget -P /etc/nginx https://raw.githubusercontent.com/V2RaySSR/Trojan_Panel/master/nginx.conf
	systemctl restart trojan nginx
cat > /usr/local/etc/trojan/Trojan配置信息.txt <<-EOF
==================================================
            搭建完毕（请仔细阅读以下提示）
==================================================
你的数据库密码为：$trojan_passwd
Trojan面板的访问地址为 https://$your_domain/config
访问此面板第一次注册的用户为系统管理员
此面板搭建包含了 Trojan 服务器的搭建
==================================================
            以下是 Trojan 的连接信息
==================================================
            域名：$your_domain
            端口：443
            密码：用户名:密码
 以上提到的密码为 Trojan-Panel 注册的用户名和密码
        请注意（用户名:密码）为英文标点
		  
==================================================
EOF
	green "=================================================="
   yellow "            搭建完毕（请仔细阅读以下提示）"
	green "=================================================="
	 blue "你的数据库密码为：$trojan_passwd"
	 blue "Trojan面板的访问地址为 https://$your_domain/config"
	 blue "访问此面板第一次注册的用户为系统管理员"
	 blue "此面板搭建包含了 Trojan 服务器的搭建"
	green "=================================================="
   yellow "            以下是 Trojan 的连接信息"
	green "=================================================="
	 blue "             域名：$your_domain"
	 blue "             端口：443"
	 blue "             密码：用户名:密码"
	 blue " "
   yellow "以上提到的密码为 Trojan-Panel 注册的用户名和密码"
	  red "             请注意（:）为英文标点"
	green "=================================================="
   yellow "      以上信息BAK在 /usr/local/etc/trojan/ "
   yellow "教程: https://v2rayssr.com/trojan-panel-aoto.html"
    green "=================================================="
	exit 0
	
else
	red "================================"
	red "  PHP7.2等基础依赖安装不成功"
	red "================================"	
	exit 1
fi
else
	red "================================"
	red "域名解析地址与本VPS IP地址不一致"
	red "本次安装失败，请确保域名解析正常"
	red "================================"	
	exit 1
fi
fi
}

bbr_boost_sh(){
    apt install -y wget
    wget -N --no-check-certificate -q -O tcp.sh "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && bash tcp.sh
}

start_menu(){
    clear
	green "=========================================================="
   yellow "本脚本仅仅支持：Debian9+ / Ubuntu16.04+"
	 blue "trojan.bojin.co"
	green "=========================================================="
   yellow "一键安装多用户 Trojan 管理面板 2021"
	green "=========================================================="
	green " "
	green "=========================================================="
      red "本脚本会覆盖 Nginx 并占用80/443，请勿在生产环境使用！切记！"
	green "=========================================================="
	green " "
	green "=========================================================="
	  red "      为确保一次性安装成功，请使用新系统安装"
	green "=========================================================="
     blue "1. 安装 Trojan-Panel 面板"
     blue "2. 安装 BBRPlus4 合一加速（第一次运行安装内核）"
	 blue "3. 安装 BBRPlus4 合一加速（第二次运行启动加速）"
   yellow "0. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    	1)
		install_panel
		;;
		2)
		bbr_boost_sh
		;;
		3)
		./tcp.sh
		;;
		0)
		exit 0
		;;
		*)
	clear
	echo "请输入正确数字"
	sleep 2s
	start_menu
	;;
    esac
}

start_menu
