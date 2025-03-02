# Effortless-H2Proxy-Setup
Effortlessly set up a secure proxy with Hysteria2 and automate SSL certification with ACME. This script streamlines the configuration process, making it fast and easy.

## 使用方法:

```sh
git clone https://github.com/AnemoneMoennig36/Effortless-H2Proxy-Setup.git
cd Effortless-H2Proxy-Setup

复制 config.example.sh 并修改配置:
cp ~/Effortless-H2Proxy-Setup/config.example.sh ~/Effortless-H2Proxy-Setup/config.sh
nano ~/Effortless-H2Proxy-Setup/config.sh

在 config.sh 文件内填写你的 邮箱、域名和密码，注意保留双引号 ""，不要删除它。

修改完成后，按以下键保存:
	1.	按 Ctrl + X 退出
	2.	按 Y 保存
	3.	按 Enter 确认

运行安装脚本:
bash main.sh
运行结束，看到 Installation completed. 说明安装完成。

检查 hysteria 运行状态:
systemctl status hysteria-server.service
	•	如果显示 active，则 hysteria 安装并运行成功。

其他 hysteria 命令

启动 hysteria
sudo systemctl start hysteria-server.service
设置开机自启
sudo systemctl enable hysteria-server.service
停止 hysteria
sudo systemctl stop hysteria-server.service
重启 hysteria
sudo systemctl restart hysteria-server.service
测试 hysteria 配置文件
hysteria server -c /etc/hysteria/config.yaml