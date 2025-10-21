# Effortless-H2Proxy-Setup
Effortlessly set up a secure proxy with Hysteria2 and automate SSL certification with ACME. This script streamlines the configuration process, making it fast and easy.

## 准备工作:
1、邮箱: 用来注册acme  
2、域名: 用来注册SSL证书  
3、密码: 使用hysteria2的时候的密码  
## 使用方法:
### 一、第一步  
复制代码到你的服务器并按回车:
```sh
sudo dnf install -y git && \
git clone https://github.com/AnemoneMoennig36/Effortless-H2Proxy-Setup.git && \
cd Effortless-H2Proxy-Setup && \
cp config.example.sh config.sh
```
### 二、第二步 (可跳过)  
编辑config.sh文件  
在config.sh文件内填写你的邮箱、域名和密码, **注意保留双引号””**,不要删除它.  
你可以使用nano或者vi等编辑器修改  
nano的使用方法:
```sh
nano config.sh
```
用nano修改完成后，按以下键保存:  
	1.	按 Ctrl + X 退出
	2.	按 Y 保存
	3.	按 Enter 确认

### 三、第三步
```sh
bush main.sh 
```
如果跳过第二步,此时需要根据提示输入邮箱、域名和密码.  
脚本会自动运行,运行结束看到 Installation completed. 后  
```sh
systemctl status hysteria-server.service
```
检查hysteria的状态,如果显示active,则安装并运行成功  <br>
<br>
<br>
<br>
 > 其他hysteria命令参考:
 > ```sh
 > sudo systemctl start hysteria-server.service
 > ```
 > 启动hysteria
 > ```sh
 > systemctl enable hysteria-server.service
 > ```
 > 应用hysteria(重启服务器后hysteria自动开启)
 > ```sh
 > sudo systemctl stop hysteria-server.service
 > ```
 > 停止hysteria
 > ```sh
 > sudo systemctl restart hysteria-server.service
 > ```
 > 重启hysteria
 > ```sh
 > hysteria server -c /etc/hysteria/config.yaml
 > ```
 > 测试配置文件
