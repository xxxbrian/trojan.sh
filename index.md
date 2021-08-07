# Trojan

Trojan是一款最近比较流行的代理工具，支持代理流量和伪装网站共用443端口，不支持搭配CDN使用。

Trojan可以将科学上网流量，伪装为HTTPS网页浏览。相比Shadowsocks/SSR/V2ray等其它工具，Trojan因为有真实的网页做为掩护，因此伪装效果更好，更不容易被封锁。从这一点来说，Trojan与V2ray的WS+TLS模式非常相似，两者的使用效果也很接近。

官方页面：[https://trojan-gfw.github.io/trojan/](https://trojan-gfw.github.io/trojan/)

**Trojan科学上网的实现原理：**

用户分别在服务器和本地设备搭建好Trojan后，Trojan和伪装网站，共同使用443端口。

* 用户通过Trojan客户端访问443端口时，会被服务器识别为科学上网流量，自动使用代理功能。
* 其它人直接访问服务器80/443端口时，会被服务器识别为网页请求，直接展示伪装网站。

通过以上伪装及分流，就可以让GFW防火墙认为我们在访问真实的网站，从而避开封锁和限速，提升科学上网的速度和稳定性。

**Trojan的优点：**

* 使用TLS协议加密，安全性有保证。
* 使用真实网站伪装流量，不容易被封锁。
* 由于被认为是网站流量，基本不会被QOS限速，科学上网速度更快、更稳定。
* 由于Trojan的开发目的很明确，所以参数更少，配置更简单。
* ~~目前使用人数相对较少，更不容易被墙针对。~~

**Trojan的不足：**

* 出于实现原理，Troian的搭建，需要购买一个域名指向伪装网站。
* 需要在VPS服务器建立一个伪装网站并申请SSL证书。
  
以上两点不足，其实并不算缺点，而是实现Trojan伪装效果的必备途径。相对Trojan的优点来说，不足之处可以接受，也很好克服，就是一个域名的事。

## 准备工作

相比其它几款主流的科学上网工具，比如Shadowsocks/SSR/V2Ray/WireGuard等，Trojan搭建流程稍有不同，因为它多了一个搭建伪装网站的步骤。

### 1. VPS服务器

搭建Trojan代理的第一步，当然是获得一台国外的VPS服务器。

关于VPS服务器的选择，这里推荐搬瓦工或Vultr，多年来的口碑和性价比都不错。

* [搬瓦工](https://bwh88.net/)
* [Vultr](https://www.vultr.com/)

**注意**：在购买VPS服务器时，推荐选择Debian 9系统或CentOS 7，方便各种一键脚本的安装。搬瓦工或Vultr的VPS购买成功后，都可以在后台更换系统版本。

### 2. 域名解析

由于涉及到伪装网站的搭建，以及SSL证书的申请，需要提前购买一个域名，指向你的VPS服务器IP地址。

购买域名时，可以考虑国外的Namesilo或Godaddy，都支持支付宝付款，随便选购一个便宜的域名就可以。

当然国内的域名网站也可以，但是需要额外做实名认证，相对不推荐。

域名购买成功后，在后台DNS设置里，将域名指向你的VPS服务器IP。

## 运行脚本

**脚本特点：**

* 全自动配置伪装网站，网站位于`/usr/share/nginx/html/`目录，可自行修改替换。
* 全自动申请配置SSL证书用于https网站，使用的是let’s encrypt证书。
* SSL证书到期前会自动续期，免维护。
* 自动配置开放80、443端口。
* 自动配置好Trojan客户端文件及参数，下载即可使用。
* **不支持Cloudflare等CDN服务，建议不要使用CDN。**

**安装环境：**

* 架构：KVM、OpenVZ（OVZ）
* 系统：CentOS 7+ 、Debian 9+ 、 Ubuntu 16+

**Trojan一键安装脚本：**

```sh
curl -O https://raw.githubusercontent.com/xxxbrian/trojan.sh/master/trojan.sh && chmod +x trojan.sh && ./trojan.sh
```

如果以上命令运行时出现关于curl的错误提示，那么需要先为服务器安装curl后，再运行以上命令。如果没有错误提示，则忽略本段内容。

**CentOS：**
`yum install curl -y`

**Debian/Ubuntu：**
`apt-get install curl -y`

**注意**：Trojan服务器端安装完成后，会提供Trojan客户端配置文件供下载，建议下载备用。

## 开启BBR优化

以上各步骤完成后，Trojan服务器端已经搭建完成，可以直接使用了。

不过可以通过一些额外措施，进一步优化Trojan的连接速度，提高使用体验。

Trojan使用的是TCP流量，可以为服务器安装TCP加速工具`BBR`，对网络进一步优化。

**CentOS:**

```sh
wget --no-check-certificate https://raw.githubusercontent.com/tcp-nanqinlang/general/master/General/CentOS/bash/tcp_nanqinlang-1.3.2.sh
bash tcp_nanqinlang-1.3.2.sh
```

**Debian:**

```sh
wget --no-check-certificate https://github.com/tcp-nanqinlang/general/releases/download/3.4.2.1/tcp_nanqinlang-fool-1.3.0.sh
bash tcp_nanqinlang-fool-1.3.0.sh
```

**选择1安装内核后需要重启，重启后运行脚本选择2开启算法。**
