#!/bin/bash  -e
WARE_HOUSE_NAME=`pwd`							#定制仓库位置
MKISO_DIR=$WARE_HOUSE_NAME/custom_made_iso		#iso,mkiso存放的位置
ISO_DIR=$WARE_HOUSE_NAME                        #定制的ISO存放位置
PATCH_DEB_DIR=$WARE_HOUSE_NAME/debs             #Debian安装程序的补丁安装包存放位置
VENDOR_DIR=vendors                              #供应商的位置
BEGIN_TIME=`date +'%Y-%m-%d %H:%M:%S'`          #计算定制时间
VENDOR_NAME=()


cd $VENDOR_DIR
j=0
for i in $(ls)
do
    if [ $i = "template" ]
    then
        continue
    fi
    VENDOR_NAME[$j]=$i
    j=`expr $j + 1 `
done 
j=${#VENDOR_NAME[@]}
cd $WARE_HOUSE_NAME


#脚本help函数
show_help()
{
    for i in $(seq 0 `expr $j - 1`)
    do
    	echo "请将基线版ISO放到$MKISO_DIR目录"
        echo "请输入需要的修改的ISO文件和定制版本编号：./build90.sh -i input_iso_file -v ${VENDOR_NAME[${i}]} -a {i386 | amd64}"
    done 
    exit
}

#脚本参数的筛选
run=
while getopts ":h:v:i:a:" o; do
    case "${o}" in
        i)
        ISO=${OPTARG}
        ;;
        v)  
        run=${OPTARG}
        ;;
        a)
        ARCH=${OPTARG}
        ;;
        h)
        show_help
        ;;
        *)
        show_help
        ;;
        esac
        done
shift $((OPTIND-1))

#创建日志文件
touch $WARE_HOUSE_NAME/build.log-${run}-$(date +%Y%m%d)
build_log=$WARE_HOUSE_NAME/build.log-${run}-$(date +%Y%m%d)
build_log_list=$WARE_HOUSE_NAME/$VENDOR_DIR/${run}/.build_log.md

#编译日志记录
log()
{
	if [ ! -f $2 ];then
		touch $2
	fi
    build_times=1
	user=`whoami`
	DATE=$(date +%Y%m%d)
	if cat $2 | grep "$(date +%Y%m%d)" | grep ${user} | grep ${1} > /dev/null
	then
		cat $2 | while read line
		do
			times_old=`echo $line | grep "$(date +%Y%m%d)" | grep ${user} | grep ${1} | awk -F":" '{printf$3}'`
			if [ ! -z "$times_old" ];then
				build_times=$times_old
				build_times=$((build_times+1))
				sed -i 's/'${line}'/'\<${user}\>':'${DATE}'定制'${1}'次数:'${build_times}'/g' $2
            fi
        done
    else
        echo "$(date +'%Y年%m月%d日')" >> $2
        echo "<${user}>:${DATE}定制${1}次数:${build_times}" >> $2
    fi
}

#定制函数编写
custom()
{
	num=1
	#把64位的config文件修改为32位，只有在做32位系统时需要
    if [ -d $VENDOR_DIR/${1}/archive-config ]
    then
        cp $VENDOR_DIR/${1}/archive-config/* custom_made_iso/mkiso-90/config/
        ls -l custom_made_iso/mkiso-90/config/*
    fi
	#安全加固与内网监控下载最新版
	echo -e "NO.${num}:\033[32m进行安全加固与内网监控最新版下载\033[0m\n"
	{
       echo "开始下载安全加固与内网监控"
	   #$WARE_HOUSE_NAME/$VENDOR_DIR/${1}/update_soft 	$WARE_HOUSE_NAME/$VENDOR_DIR/${1}  $1
    } > ${2}
    num=$((num+1))

   	#进行ISO-configure文件的复制
    echo -e "NO.${num}:\033[32m进行ISO-configure中的文件复制\033[0m\n"
    {

        cd $WARE_HOUSE_NAME/$VENDOR_DIR/${1}/
        chmod +x ./replace_preseed_deb.sh
        ./replace_preseed_deb.sh $MKISO_DIR $WARE_HOUSE_NAME ${1}
    }   > ${2}
    num=$((num+1))

    echo -e "NO.${num}:\033[32m进行kde桌面安装包的复制与替换\033[0m\n"
    {
    echo "进行kde桌面安装的复制与替换"
    cd $WARE_HOUSE_NAME/$VENDOR_DIR/${1}
    chmod +x ./generator-kde.sh
    ./generator-kde.sh
    cd -
    if [ -f $WARE_HOUSE_NAME/$VENDOR_DIR/${1}/replace_kde_deb.sh ]
    then
        $WARE_HOUSE_NAME/$VENDOR_DIR/${1}/replace_kde_deb.sh $MKISO_DIR $PATCH_DEB_DIR
        rm $WARE_HOUSE_NAME/$VENDOR_DIR/${1}/replace_kde_deb.sh
    fi
    } >> ${2}
    num=$((num+1))

    #进行custom目录的复制
    echo -e "NO.${num}:\033[32m进行custom目录下包的制作和复制\033[0m\n"
    {
      cd $WARE_HOUSE_NAME/$VENDOR_DIR/${1}/linx-custom
      echo -e "进行udeb和deb包的制作"
      chmod +x ./linx-custom.sh
      ./linx-custom.sh ${ARCH}
      echo -e "进行udeb和deb包的拷贝替换"
      cd $WARE_HOUSE_NAME/$VENDOR_DIR/${1}/
      chmod +x ./replace_iso_deb.sh
      ./replace_iso_deb.sh ${MKISO_DIR} ${WARE_HOUSE_NAME} ${1}
      sleep 3
    }  >> $2
    num=$((num+1))
}

echo -e "\n\033[32m#********************************欢迎使用linx-90-${ARCH}自动化定制************************#\033[0m"    
if [ "${ARCH}" = "arm64" ];then
echo  "
       _      _               ___   ___             _____  __  __   __ _  _   
      | |    (_)             / _ \ / _ \      /\   |  __ \|  \/  | / /| || |  
      | |     _ _ __ __  __ | (_) | | | |    /  \  | |__) | \  / |/ /_| || |_ 
      | |    | | '_ \\\ \/ /  \__, | | | |   / /\ \ |  _  /| |\/| | '_ \__   _|
      | |____| | | | |>  <     / /| |_| |  / ____ \| | \ \| |  | | (_) | | |  
      |______|_|_| |_/_/\_\   /_/  \___/  /_/    \_\_|  \_\_|  |_|\___/  |_|                                    "
else
    echo "
      _      _               ___   ___             __  __ _____    __ _  _   
     | |    (_)             / _ \ / _ \      /\   |  \/  |  __ \  / /| || |  
     | |     _ _ __ __  __ | (_) | | | |    /  \  | \  / | |  | |/ /_| || |_ 
     | |    | | '_ \\\ \/ /  \__, | | | |   / /\ \ | |\/| | |  | | '_ \__   _|
     | |____| | | | |>  <     / /| |_| |  / ____ \| |  | | |__| | (_) | | |  
     |______|_|_| |_/_/\_\   /_/  \___/  /_/    \_\_|  |_|_____/ \___/  |_|                                     "
fi

echo -e "\033[32m#*******************************开始定制环境检测*****************************************#\033[0m"          
# check the iso file
seq=1 
if [ ! -f custom_made_iso/${ISO} ];
then
    echo "the iso file ${ISO} is not exist!"
    show_help
fi
for i in $(seq 0 $j )
do
    if [ "$run" == "${VENDOR_NAME[${i}]}" ]
    then
        break
    fi
    if [ "$i" == "$j" -o "$run" == "" -o "$ARCH" == "" ]
    then
        show_help
    fi
done

#解压缩mkiso和用来进行制作定制盘的ISO，修改其权限
cd $MKISO_DIR                  
if [ -d "mkiso-90" ]
then
    echo -e  "NO.${seq}:\033[32mmkiso-90文件存在，即将进行删除处理\033[0m"
    echo -e "     如果不删除mkiso-90文件夹，请按CTRL + C 退出定制环境"
    echo -e "     5秒之后将进行删除mkiso-90文件夹操作"
    sleep 5
    echo -e "     \033[31m执行删除mkiso-90文件夹操作\033[0m"
    sudo rm -rf mkiso-90
    seq=$((seq+1))
fi
echo -e  "NO.${seq}:\033[32m解压新mkiso-90文件夹...\033[0m"
seq=$((seq+1))
sudo tar -xf mkiso-90.tgz -C $MKISO_DIR/
sudo chown `whoami`:`whoami` $MKISO_DIR/mkiso-90

if [ -d "$MKISO_DIR/chroot-stretch-${ARCH}" ]
then
 echo -e  "NO.${seq}:\033[32mchroot-stretch-${ARCH}文件存在，即将进行删除处理\033[0m"
 echo -e  "     \033[31m执行删除chroot-stretch-${ARCH}文件夹操作\033[0m"
 sudo rm -rf $MKISO_DIR/chroot-stretch-${ARCH}
 seq=$((seq+1))
fi
echo -e  "NO.${seq}:\033[32m解压新chroot-stretch-${ARCH}文件夹...\033[0m\n"
sudo tar -xf $MKISO_DIR/chroot-stretch-${ARCH}.tar.gz -C $MKISO_DIR/
sudo chown `whoami`:`whoami` $MKISO_DIR/chroot-stretch-${ARCH}

echo -e "待定制基线版ISO              \033[32mok !\033[0m"
echo -e "定制参数格式                 \033[32mok !\033[0m"
echo -e "mkiso-90文件夹               \033[32mok !\033[0m"
echo -e "chroot-stretch-${ARCH}文件夹   \033[32mok !\033[0m"

echo -e "\n\033[32m#*******************************完成定制环境初始化****************************************#\033[0m"


echo -e "\n\033[32m#***********************************开始解压ISO*******************************************#\033[0m\n"          
sudo rm -rf  mkiso-90/CD1
./extrack-iso.sh $ISO mkiso-90/CD1
sudo chown -R `whoami`:`whoami` mkiso-90/CD1
sudo chmod -R 755 mkiso-90/CD1 
mkdir $WARE_HOUSE_NAME/custom_made_iso/mkiso-90/CD1/custom
echo -e "\n\033[32m#***********************************完成解压ISO*******************************************#\033[0m\n" 


echo -e "\033[32m#***********************************开始定制ISO*******************************************#\033[0m\n" 
echo -e "执行定制化函数，详细定制日志可到${build_log}查看"
cd $WARE_HOUSE_NAME
custom "$run"  $build_log
sleep 1
echo -e "\033[32m#*********************************完成定制ISO******************************************#\033[0m\n" 


echo -e "\033[32m#*********************************开始合成ISO******************************************#\033[0m\n" 
ISO_NAME=linx-6.0.90-ts-${run}-1.1.0.$(date +%Y%m%d)-${ARCH}-DVD.iso
echo "<ISO_NAME>:$ISO_NAME" > $WARE_HOUSE_NAME/isoname
echo -e "合成定制ISO名字：$ISO_NAME" 
cd $MKISO_DIR/mkiso-90
LABEL_NAME="Linx6.0.90-${run}-20200902-${ARCH}"
echo -e "合成定制ISO光盘卷标： $LABEL_NAME\n"
echo "<LABEL_NAME>:$LABEL_NAME" >> $WARE_HOUSE_NAME/isoname
chmod +x ./regenerate_iso_${ARCH}.sh  
sudo ./regenerate_iso_${ARCH}.sh  ${LABEL_NAME} ${ISO_NAME}
log ${ISO_NAME} ${build_log_list}
echo -e "\033[32m#******************************************完成合成ISO****************************************#\033[0m\n" 


echo -e "\033[32m#*****************************感谢使用linx-90-${ARCH}自动化定制*********************************#\033[0m\n" 
if [ -f "$ISO_DIR/$ISO_NAME"  ];then
    echo -e "\033[31m注意：$ISO_DIR/$ISO_NAME文件存在，即将删除\033[0m"
    echo -e "如果不删除$ISO_NAME文件，请按CTRL + C 退出 \nCTRL + C退出之后新生成的ISO为$MKISO_DIR/mkiso-90/$ISO_NAME \n等待8秒之后将进行删除$ISO_NAME文件操作"
    sleep 8
    echo -e "\033[31m执行删除$ISO_DIR/$ISO_NAME文件操作\033[0m"
    sudo rm -rf $ISO_DIR/$ISO_NAME
fi
    mv $ISO_NAME $ISO_DIR/$ISO_NAME
    echo -e "\033[32m制作成功，定制ISO位置:$ISO_DIR/$ISO_NAME\033[0m\n"
    sudo rm -rf $MKISO_DIR/mkiso-90

END_TIME=`date +'%Y-%m-%d %H:%M:%S'`
BEGIN_TIMES=$(date --date="$BEGIN_TIME" +%s)
END_TIMES=$(date --date="$END_TIME" +%s)
echo "结束时间：$END_TIME"
cat ${build_log_list} | while read line
do
    show_times=`echo $line | grep ${DATE} | grep ${user} | grep ${ISO_NAME} | awk -F":" '{printf$3}'`
    if [ ! -z "$show_times" ];then
        echo -e "用户${user}：${DATE}第 \033[32m'${show_times}'\033[0m 次定制${ISO_NAME}"
    fi
done
cd $WARE_HOUSE_NAME
memiso=`du -sh $ISO_NAME`
mem_iso=`echo $memiso | awk -F"G\ " '{printf$1}'`  
echo -e "本次定制总运行时间： \033[32m$((END_TIMES-BEGIN_TIMES))\033[0m s"
echo -e "定制完成后的ISO大小：\033[32m$mem_iso\033[0m G\n"
echo -e "\033[32m#******************北京凝思软件股份有限公司四川分公司-成都研发一部操作系统组*******************#\033[0m"
echo -e "\033[32m#**********************成都市高新区天府大道中段东方希望天祥广场B座3401*************************#\033[0m"
