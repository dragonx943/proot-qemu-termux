#!/data/data/com.termux/files/usr/bin/bash
clear

ARCHITECTURE=$(dpkg --print-architecture)

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

echo ${R}"Cảnh báo: Vì đây là Proot sử dụng với giả lập QEMU nên có thể tốc độ sẽ chậm hơn Proot bình thường!"
sleep 5
clear

echo ${G}"==> Tiến trình: Cài đặt những gói cần thiết..."
pkg install proot wget qemu-user-x86-64 proot-distro blink -y
clear

echo ${G}"==> Tiến trình: Lựa chọn Runtime để cài đặt..."
echo ${R}"Vui lòng chọn loại Runtime mà bạn muốn sử dụng với Proot:"
echo "1. qemu-x86_64-static (nhanh nhất, không ổn định, có thể bị Crash)"
echo "2. qemu-user-x86-64 (nhanh, không ổn định, có thể bị Crash)"
echo "3. blink (không ổn định / thử nghiệm, thường xuyên bị Crash)"
read -p "==> Lựa chọn của bạn là: " RUNTIME
sleep 1
clear

echo ${Y}"W: Cấu trúc nhân hệ điều hành Android của bạn là: $ARCHITECTURE"
case $RUNTIME in
    1)
        RUNTIME_NAME="qemu-x86_64-static"
        echo ${C}"Bạn đã chọn Runtime là: qemu-x86_64-static!"
        case `dpkg --print-architecture` in
            aarch64)
			    sleep 1
			    echo ${G}"Đang cài đặt Runtime..."${W} ;
			    wget https://github.com/AllPlatform/Termux-UbuntuX86_64/raw/master/arm64/qemu-x86_64-static;
			    chmod 777 qemu-x86_64-static;
			    mv qemu-x86_64-static ~/../usr/bin ;;
            arm*)
                echo ${G}"Please download the rootfs file for amd64." ;
			    sleep 1
			    echo ${G}"Đang cài đặt Runtime..."${W} ;
			    wget https://github.com/AllPlatform/Termux-UbuntuX86_64/raw/master/arm/qemu-x86_64-static;
			    chmod 777 qemu-x86_64-static;
			    mv qemu-x86_64-static ~/../usr/bin/ ;;
            i*86)
                echo ${R}"Chưa có sẵn Runtime cho cấu trúc 32bit của bạn, hãy thử với Runtime khác!"${W}; exit 1 ;;
	        x86)	
			    echo ${R}"Chưa có sẵn Runtime cho cấu trúc 32bit của bạn, hãy thử với Runtime khác!"${W}; exit 1 ;;
            x86_64)
                echo ${G}"Bạn đang có hệ điều hành cùng cấu trúc với Linux bạn muốn cài, bỏ qua!"${W};
			    sleep 1 ;;
            *)
                echo ${R}"Cấu trúc của bạn không thể xác định, xin hãy thử Runtime khác. Hủy bỏ câu lệnh!"${W}; exit 1 ;;
        esac
        sleep 1
        clear
    2)
        RUNTIME_NAME="qemu-x86_64"
        echo ${C}"Bạn đã chọn Runtime là: qemu-user-x86-64!"
        echo ${G}"Đang cài đặt Runtime..."${W}
        pkg update
        pkg install qemu-user-x86-64
        echo ${G}"W: Đã cài đặt Runtime xong!"${W}
        sleep 1
        clear
    3)
        RUNTIME_NAME="blink"
        echo ${C}"Bạn đã chọn Runtime là: Blink!"
        echo ${G}"Đang cài đặt Runtime..."${W}
        pkg update
        pkg install blink
        echo ${G}"W: Đã cài đặt Runtime xong!"${W}
        sleep 1
        clear
esac

echo ${C}"=== Đã xong những thiết đặt cơ bản, hãy lựa chọn: "
echo "1. Cài đặt Distro theo đường dẫn URL bên ngoài (mượt hơn nhưng không ổn định, có thể sẽ bị Crash)"
echo "2. Cài đặt Distro theo gói proot-distro của Termux (ổn định hơn nhưng tốc độ phản hồi chậm hơn)"
read -p "Lựa chọn của bạn là (1 hoặc 2): " choice

case $choice in
    1)
        echo ${C}"=== Bạn đã chọn cài đặt Distro theo đường dẫn URL bên ngoài! ==="
        echo ${G}"Tiếp theo, hãy cung cấp một URL hợp lệ để tải về Distro của bạn (là file .tar.gz hoặc .tar.xz)"
        echo "==> URL của bạn là: "
        read URL
        sleep 1
        echo ${G}"Hãy đặt tên cho Distro của bạn! Ví dụ: Bạn nhập là 'alpine' thì khi đăng nhập vào Distro, bạn sẽ gõ: 'bash alpine-x64.sh' "
        read ds_name
        sleep 1

        folder=$ds_name-x64-fs
        if [ -d "$folder" ]; then
            echo ${G}"Đã phát hiện Distro đã cài đặt trước đó, bạn có muốn gỡ bỏ? (y hoặc n)"${W}
            read ans
            if [[ "$ans" =~ ^([yY])$ ]]; then
                    echo ${W}"Đang gỡ cài đặt Distro cũ..."${W}
                    rm -rf ~/$folder
                    rm -rf ~/$ds_name-x64.sh
                    sleep 2
            elif [[ "$ans" =~ ^([nN])$ ]]; then
            echo ${R}"Vì file Distro cũ có cùng tên với Distro bạn muốn cài nên không thể tiếp tục, hủy bỏ thực thi lệnh!"
            exit
            else 
            echo
            fi
        else 
        mkdir -p $folder
        fi

        clear
        echo ${G}"==> Tiến trình: Đang tải về Distro theo đường dẫn URL mà bạn cung cấp..."
        wget $URL -P ~/$folder/ 
        clear
        echo ${G}"==> Tiến trình: Đang giải nén file cài đặt Distro..."
        proot --link2symlink \
            tar -xpf ~/$folder/*.tar.* -C ~/$folder/ --exclude='dev'||:
        if [[ ! -d "$folder/etc" ]]; then
            mv $folder/*/* $folder/
        fi
        echo "127.0.0.1 localhost" > ~/$folder/etc/hosts
        rm -rf ~/$folder/etc/resolv.conf
        echo "nameserver 8.8.8.8" > ~/$folder/etc/resolv.conf
        echo "nameserver 1.1.1.1" > ~/$folder/etc/resolv.conf
        echo -e "#!/bin/sh\nexit" > "$folder/usr/bin/groups"
        mkdir -p $folder/binds
        clear

        bin=$ds_name-x64.sh
        echo ${G}"==> Tiến trình: Đang tạo file khởi động / đăng nhập vào Distro..."
        cat > $bin <<- EOM
        #!/bin/bash
        cd \$(dirname \$0)
        ## unset LD_PRELOAD nếu termux-exec đã được cài
        unset LD_PRELOAD
        command="proot"
        command+=" --link2symlink"
        command+=" -0"
        command+=" -r $folder -q $RUNTIME_NAME"
        command+=" -b /dev"
        command+=" -b /proc"
        command+=" -b $folder/root:/dev/shm"
        command+=" -b /data/data/com.termux/files/usr/tmp:/tmp"
        ## Xóa # liên kết /root với HOME của Termux
        #command+=" -b /data/data/com.termux/files/home:/root"
        ## Xóa # dòng dưới để mount bộ nhớ trong ra /sdcard của Distro (cần termux-setup-storage)
        #command+=" -b /sdcard"
        command+=" -w /root"
        command+=" /usr/bin/env -i"
        command+=" HOME=/root"
        command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
        command+=" TERM=\$TERM"
        command+=" LANG=C.UTF-8"
        command+=" /bin/sh --login"
        com="\$@"
        if [ -z "\$1" ]; then
            exec \$command
        else
            \$command -c "\$com"
        fi
EOM
        termux-fix-shebang $bin
        chmod +x $bin
        echo ${G}"==> Tiến trình: Xóa file cài đặt Distro giải phóng bộ nhớ..."
        rm -rf $folder/*.tar.*
        echo ${G}"==> Hoàn thành! Giờ bạn có thể đăng nhập vào Distro với câu lệnh: 'bash $bin' và tận hưởng!"
        ;;
    2)
        echo ${C}"=== Bạn đã chọn cài đặt Distro theo gói proot-distro của Termux! ==="
        sleep 3
        if [ "$RUNTIME" -eq 1 ]; then
            echo ${R}"Rất tiếc, qemu-x86_64-static không thể dùng với proot-distro!"
            exit
        fi
        if [ "$RUNTIME" -eq 2 ]; then
            export PROOT_DISTRO_X64_EMULATOR=QEMU
            PROMPT="PROOT_DISTRO_X64_EMULATOR=QEMU"
        fi
        if [ "$RUNTIME" -eq 3 ]; then
            export PROOT_DISTRO_X64_EMULATOR=BLINK
            PROMPT="PROOT_DISTRO_X64_EMULATOR=BLINK"
        fi
        ls $PREFIX/etc/proot-distro/
        echo ${G}"Trên đây là những tệp cài đặt Distro được hỗ trợ bởi proot-distro!" 
        read -p "Hãy ghi tên file mà bạn muốn cài đặt. Ví dụ: debian.sh hoặc ubuntu.sh,...: " DISTRO
        sleep 1
        clear
        echo "==> Lựa chọn của bạn là: $DISTRO - Bắt đầu cài đặt"
        echo "==> Tiến trình: Thử gỡ cài đặt Distro (nếu đã cài đặt trước đó)..."
        DISTRO_INSTALL="${DISTRO%.sh}"
        proot-distro remove $DISTRO_INSTALL
        clear
        echo "==> Tiến trình: Bắt đầu cài đặt Distro..."
        echo "DISTRO_ARCH=x86_64" >> $PREFIX/etc/proot-distro/$DISTRO
        proot-distro install $DISTRO_INSTALL
        echo ${G}"Đã xong. Hãy đăng nhập Distro với câu lệnh: '$PROMPT proot-distro login $DISTRO_INSTALL' (thêm --shared-tmp nếu muốn sử dụng với Termux:X11)"
        ;;
    *)
        echo ${R}"Lỗi: Lựa chọn của bạn không hợp lệ, hãy lựa chọn 1 hoặc 2 để tiếp tục!"
        ;;
esac
