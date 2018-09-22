# BY Andrew 2018.9.19 https://lzzone.top

aria2_dir=/home/pi/.aria2
aria2_conf=$aria2_dir/aria2.conf
aria2_download=$HOME/Downloads


check_sys(){
    if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}

check_crontab_installed_status(){
	if [[ ! -e ${Crontab_file} ]]; then
		echo -e "${Error} Crontab 没有安装，开始安装..."
		if [[ ${release} == "centos" ]]; then
			yum install crond -y
		else
			apt-get install cron -y
		fi
		if [[ ! -e ${Crontab_file} ]]; then
			echo -e "${Error} Crontab 安装失败，请检查！" && exit 1
		else
			echo -e "${Info} Crontab 安装成功！"
		fi
	fi
}

check_pid(){
	PID=`ps -ef| grep "aria2c"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}

check_new_ver(){
	aria2_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/q3aql/aria2-static-builds/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
	if [[ -z ${aria2_new_ver} ]]; then
		echo -e "${Error} Aria2 最新版本获取失败，请手动获取最新版本号[ https://github.com/q3aql/aria2-static-builds/releases ]"
		stty erase '^H' && read -p "请输入版本号 [ 格式如 1.34.0 ] :" aria2_new_ver
		[[ -z "${aria2_new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 检测到 Aria2 最新版本为 [ ${aria2_new_ver} ]"
	fi
}

check_ver_comparison(){
	aria2_now_ver=$(aria2c -v|head -n 1|awk '{print $3}')
	[[ -z ${aria2_now_ver} ]] && echo -e "${Error} aria2 当前版本获取失败 !" && exit 1
	if [[ "${aria2_now_ver}" != "${aria2_new_ver}" ]]; then
		echo -e "${Info} 发现 Aria2 已有新版本 [ ${aria2_new_ver} ](当前版本：${aria2_now_ver})"
		stty erase '^H' && read -p "是否更新(会中断当前下载任务，请注意) ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			Download_aria2 "update"
			Start_aria2
		fi
	else
		echo -e "${Info} 当前 Aria2 已是最新版本 [ ${aria2_new_ver} ]" && exit 1
	fi
}

Download_aria2(){
	update_dl=$1
	cd "/tmp"
	#echo -e "${bit}"
	if [[ ${bit} == "armv7l" ]]; then
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-arm-rbpi-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-arm-rbpi-build1"
	elif [[ ${bit} == "aarch64" ]]; then
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-arm-rbpi-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-arm-rbpi-build1"
	elif [[ ${bit} == "x86_64" ]]; then
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-64bit-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-64bit-build1"
	else
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-32bit-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-32bit-build1"
	fi
	[[ ! -s "${Aria2_Name}.tar.bz2" ]] && echo -e "${Error} Aria2 压缩包下载失败 !" && exit 1
	tar jxvf "${Aria2_Name}.tar.bz2"
	[[ ! -e "${Aria2_Name}" ]] && echo -e "${Error} Aria2 解压失败 !" && rm -rf "${Aria2_Name}.tar.bz2" && exit 1
	[[ ${update_dl} = "update" ]] && sudo make uninstall
	rm -rf "${Aria2_Name}.tar.bz2"
	cd "${Aria2_Name}"
	sudo make install
	cd ..
	rm -rf "${Aria2_Name}"
	[[ ! -e /usr/bin/aria2c ]] && echo -e "${Error} Aria2 主程序安装失败！" && exit 1
	echo -e "${Info} Aria2 主程序安装完毕！开始下载配置文件..."
}

Download_aria2_conf(){
	cd "${aria2_dir}"
	wget --no-check-certificate -N "https://raw.githubusercontent.com/lzzbhad/script/master/aria2/aria2.conf"
	[[ ! -s "aria2.conf" ]] && echo -e "${Error} Aria2 配置文件下载失败 !" && rm -rf "${aria2_dir}" && exit 1
	wget --no-check-certificate -N "https://raw.githubusercontent.com/lzzbhad/script/master/aria2/dht.dat"
	[[ ! -s "dht.dat" ]] && echo -e "${Error} Aria2 DHT文件下载失败 !" && rm -rf "${aria2_dir}" && exit 1
	echo '' > aria2.session
	TOKEN="$(date +%s%N | md5sum | head -c 20)"
	sed -i 's/^rpc-secret=.*/rpc-secret='${TOKEN}'/g' ${aria2_conf}
	sed -i "s?^dir=.*?dir=$aria2_download?g" ${aria2_conf}
	sed -i "s?^input-file=.*?input-file=$aria2_dir/aria2.session?g" ${aria2_conf}
	sed -i "s?^save-session=.*?save-session=$aria2_dir/aria2.session?g" ${aria2_conf}
	sed -i "s?^dht-file-path=.*?dht-file-path=$aria2_dir/dht.dat?g" ${aria2_conf}
	sed -i "s?^dht-file-path6=.*?dht-file-path6=$aria2_dir/dht6.dat?g" ${aria2_conf}
}
Download_aria2_Service(){
	cd /tmp
	if ! wget --no-check-certificate "https://raw.githubusercontent.com/lzzbhad/script/master/aria2/aria2d.service"; then
	    echo -e "${Error} Aria2服务 管理脚本下载失败 !" && exit 1
	fi
	sed -i "s?^User.*?User = $(whoami)?" aria2d.service
        sed -i "s?^ExecStart.*?ExecStart = /usr/bin/aria2c --conf-path=$aria2_dir/aria2.conf?" aria2d.service
	sudo mv aria2d.service /etc/systemd/system/aria2d.service
	sudo systemctl daemon-reload
}
init_script(){
	if test -z "$1"
	then
		aria2_dir=$HOME/.aria2
		echo "安装在默认位置: $aria2_dir"
		sed -i  's?^aria2_dir=.*?aria2_dir='$aria2_dir'?g' aria2.sh
	else
		echo "将安装在$1,确认Y/n"
		read next
		if [ $next = "Y" ] || [ $next = "y" ];
		then
			aria2_dir="$1/.aria2"
			sed -i  's?^aria2_dir=.*?aria2_dir='$aria2_dir'?g' aria2.sh
		else
			exit 1
		fi
	fi
	mkdir "${aria2_dir}"
	cp aria2.sh $aria2_dir/
}
Print_Setup_Info(){
	echo -e "sudo systemctl start aria2d  -- 启动aria2c"
	echo -e "sudo systemctl enable aria2d -- 开机启动"
	echo -e "rpc-secret:"$TOKEN
}
install(){
	init_script $1
	check_sys
	check_new_ver
	Download_aria2
	Download_aria2_conf
	Download_aria2_Service
	Print_Setup_Info
}

update_bt_tracker(){
	stop
	bt_tracker_list=$(wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt |awk NF|sed ":a;N;s/\n/,/g;ta")
	if [ -z "`grep "bt-tracker" ${aria2_conf}`" ]; then
		sed -i '$a bt-tracker='${bt_tracker_list} "${aria2_conf}"
		echo -e "${Info} 添加成功..."
	else
	sed -i "s@bt-tracker.*@bt-tracker=$bt_tracker_list@g" "${aria2_conf}"
	echo -e "${Info} 更新成功..."
	start
fi
}

crontab_update_start(){
        crontab -l > "$aria2_dir/crontab.bak"
        sed -i "/aria2.sh update_bt_tracker/d" "$aria2_dir/crontab.bak"
        echo -e "\n0 3 * * 1 /bin/bash $aria2_dir/aria2.sh update_bt_tracker" >> "$aria2_dir/crontab.bak"
        crontab "$aria2_dir/crontab.bak"
        rm -f "$aria2_dir/crontab.bak"
        cron_config=$(crontab -l | grep "aria2.sh update_bt_tracker")
        if [[ -z ${cron_config} ]]; then
                echo -e "${Error} Aria2 自动更新 BT-Tracker服务器 开启失败 !" && exit 1
        else
                echo -e "${Info} Aria2 自动更新 BT-Tracker服务器 开启成功 !"
		update_bt_tracker
        fi
}
crontab_update_stop(){
        crontab -l > "$aria2_dir/crontab.bak"
        sed -i "/aria2.sh update_bt_tracker/d" "$aria2_dir/crontab.bak"
        crontab "$aria2_dir/crontab.bak"
        rm -f "$aria2_dir/crontab.bak"
        cron_config=$(crontab -l | grep "aria2.sh update_bt_tracker")
        if [[ ! -z ${cron_config} ]]; then
                echo -e "${Error} Aria2 自动更新 BT-Tracker服务器 停止失败 !" && exit 1
        else
                echo -e "${Info} Aria2 自动更新 BT-Tracker服务器 停止成功 !"
        fi
}

uninstall(){
	sudo systemctl stop aria2d
	sudo systemctl disable aria2d
	sudo systemctl daemon-reload
	sudo pkill -9 aria2c
	sudo rm /usr/bin/aria2c
	sudo rm /usr/share/man/man1/aria2c.1
	sudo rm -rf $aria2_dir
	sudo rm -f /etc/systemd/system/aria2d.service
}

case "$1" in
	install)
		install $2
		;;
	uninstall)
		uninstall
	        ;;
	start)
		sudo systemctl start aria2d
		;;
	update)
		check_new_ver
		check_ver_comparison
		;;
	update_bt_tracker)
		update_bt_tracker
		;;
	crontab_update_start)
		crontab_update_start
		;;
	crontab_update_stop)
		crontab_update_stop
		;;
	*)
		echo -e " Usage: {install | update_bt_tracker | crontab_update_start | crontab_update_stop} "
		;;
esac

exit 0
