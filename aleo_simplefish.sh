#!/bin/bash
# aleo testnet3 激励测试一键部署脚本
# 关注作者twitter   @simplefish3 ，不定期更新撸毛教程

Workspace=/root/aleo
ScreenName=aleo
KeyFile="/root/my_aleo_key.txt"

is_root() {
	[[ $EUID != 0 ]] && echo -e "当前非root用户，请执行sudo su命令切换到root用户再继续执行(可能需要输入root用户密码)" && exit 1
}

# 判断screen是否已存在
# 0 = 是   1 = 否
has_screen(){
	Name=`screen -ls | grep ${ScreenName}`
	if [ -z "${Name}" ]
	then
		return 1
	else
		echo "screen 运行中：${Name}"
		return 0
	fi
}

# 进入screen环境
go_into_screen(){
	screen -D -r ${ScreenName}

}

# 强制关闭screen
kill_screen(){
	Name=`screen -ls | grep ${ScreenName}`
        if [ -z "${Name}" ]
        then
		echo "没有运行中的screen"
		exit 0
        else
		ScreenPid=${Name%.*}
		echo "强制关闭screen: ${Name}"
		kill ${ScreenPid}
		echo "强制关闭完成"
        fi
}

# 安装依赖以及snarkos
install_snarkos(){
	# 判断是否为root用户
	is_root

	mkdir ${Workspace}
	cd ${Workspace}	

	echo "开始安装rust"
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh  -s -- -y
	source $HOME/.cargo/env
	echo "rust安装成功!"

	echo "打开防火墙4133和3033端口"
	sudo ufw allow 4133
	sudo ufw allow 3033
	echo "防火墙设置完毕"

	echo "开始下载aleo代码"
	git clone https://github.com/AleoHQ/snarkOS.git --depth 1 ${Workspace} 
	echo "aleo代码下载完成!"

	echo "开始安装依赖项"
	bash ${Workspace}/build_ubuntu.sh
	echo "依赖项安装完成！"

	echo "开始编译snarkos"
	cargo install --path ${Workspace}
	echo "snarkos编译完成！"

	echo "开始安装screen"
	apt install screen
	echo "screen 安装成功！"

	# 判断当前服务器是否已经有生成密钥了
	if [ -f ${KeyFile} ] 
	then 
		echo "当前服务器已生成过账户和密钥"
	else
		# 生成账户和密钥
		snarkos account new > ${KeyFile}
	fi

	# 将密钥保存/etc/profile中使得可以被启动脚本读取
	PrivateKey=$(cat ${KeyFile} | grep "Private Key" | awk '{print $3}')
        echo "export PROVER_PRIVATE_KEY=$PrivateKey" >> /etc/profile
        source /etc/profile

	echo “账户和密钥保存在 ${KeyFile}，请妥善保管，以下是详细信息：”
	cat ${KeyFile}
}

# 运行client节点
run_client(){
	source $HOME/.cargo/env
	source /etc/profile

	cd ${Workspace}

	# 判断是否已经有screen存在了
	has_screen && echo "执行脚本命令5进入screen查看" && exit 1

	# 启动一个screen,并在screen中启动client节点
	screen -dmS ${ScreenName}	
	cmd=$"./run-client.sh"
	screen -x -S ${ScreenName} -p 0 -X stuff "${cmd}"
	screen -x -S ${ScreenName} -p 0 -X stuff $'\n'
	echo "client节点已在screen中启动，可执行脚本命令5 来查看节点运行情况"

}

# 运行prover节点
run_prover(){
	source $HOME/.cargo/env
	source /etc/profile

	cd ${Workspace}

	# 判断是否已经有screen存在了
        has_screen && echo "执行脚本命令5进入screen查看" && exit 1

	# 启动一个screen,并在screen中启动prover节点
        screen -dmS ${ScreenName}
        cmd=$"./run-prover.sh"
        screen -x -S ${ScreenName} -p 0 -X stuff "${cmd}"
        screen -x -S ${ScreenName} -p 0 -X stuff $'\n'
        echo "client节点已在screen中启动，可执行脚本命令5 来查看节点运行情况"
	
}



echo && echo -e " 
aleo testnet3 激励测试一键部署脚本
关注作者 twitter  @simplefish3 , 不定期更新撸毛教程
 ———————————————————————
 1.安装 aleo
 2.运行 prover 节点
 3.运行 client 节点 (目前阶段暂时不需要运行client，可跳过)
 4.查看 aleo 地址和私钥
 5.进入 screen 查看节点的运行情况，注意进入screen后，退出screen的命令是ctrl+A+D
 6.强制关闭 screen(使用kill的方式强制关闭screen，谨慎使用)
 ———————————————————————
 " && echo

read -e -p " 请输入数字 [1-6]:" num
case "$num" in
1)
	install_snarkos
    	;;
2)
    	run_prover
    	;;
3)
    	run_client
    	;;
4)
    	cat ${KeyFile}
    	;;
5)
	go_into_screen
	;;	
6)	
	kill_screen
	;;

*)
    echo
    echo -e "请输入正确的数字!"
    ;;
esac
