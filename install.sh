#!/data/data/com.termux/files/usr/bin/bash
clear

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

echo ${R}"Cảnh báo: Vì đây là Proot sử dụng với giả lập QEMU nên có thể tốc độ sẽ chậm hơn Proot bình thường!"
sleep 5
clear

echo ${G}"==> Tiến trình: Cài đặt những gói cần thiết..."
pkg install proot wget qemu-user-x86_64 proot-distro -y
clear

echo ${C}"=== Đã xong những thiết đặt cơ bản, hãy lựa chọn: "
echo "1. Cài đặt Distro theo đường dẫn URL bên ngoài (mượt hơn nhưng không ổn định, có thể sẽ bị Crash)"
echo "2. Cài đặt Distro theo gói proot-distro của Termux (ổn định hơn nhưng tốc độ phản hồi chậm hơn)"
read -p "Lựa chọn của bạn là (1 hoặc 2): " choice

case $choice in
    1)
        echo ${C}"=== Bạn đã chọn cài đặt Distro theo đường dẫn URL bên ngoài! ==="
        echo ${G}"Tiếp theo, hãy cung cấp một URL hợp lệ để tải về Distro của bạn (là file .tar.gz hoặc .tar.xz)"
        while true; do
            read -p "==> URL của bạn là: " URL
            if [[ "$URL" =~ ^https?:// ]]; then
                break
            else
                echo ${R}"Lỗi: Vui lòng nhập một URL hợp lệ bắt đầu bằng http hoặc https!"
            fi
        done
        sleep 1
        echo ${G}"Hãy đặt tên cho Distro của bạn! Ví dụ: Bạn nhập là 'alpine' thì khi đăng nhập vào Distro, bạn sẽ gõ: 'bash alpine-x64.sh' "
        while true; do
            read -p "==> Bạn sẽ đặt tên Distro là: " ds_name
            if [[ -n "$ds_name" ]]; then
                break
            else
                echo ${R}"Lỗi: Tên Distro không được để trống, vui lòng nhập lại!"
            fi
        done
        sleep 1

        folder=$ds_name-x64-fs
        if [ -d "$folder" ]; then
            echo ${G}"Đã phát hiện Distro đã cài đặt trước đó, bạn có muốn gỡ bỏ? (y hoặc n)"
            while true; do
                read -p "==> Lựa chọn của bạn: " ans
                if [[ "$ans" =~ ^([yY])$ ]]; then
                    echo ${W}"Đang gỡ cài đặt Distro cũ..."
                    rm -rf ~/$folder
                    rm -rf ~/$ds_name-x64.sh
                    sleep 2
                    break
                elif [[ "$ans" =~ ^([nN])$ ]]; then
                    echo ${R}"Vì file Distro cũ có cùng tên với Distro bạn muốn cài nên không thể tiếp tục, hủy bỏ thực thi lệnh!"
                    exit
                else
                    echo ${R}"Lỗi: Lựa chọn không hợp lệ, vui lòng nhập y hoặc n!"
                fi
            done
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
        command+=" -r $folder -q qemu-x86_64"
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
        ls $PREFIX/etc/proot-distro/
        echo ${G}"Trên đây là những tệp cài đặt Distro được hỗ trợ bởi proot-distro!" 
        read -p "Hãy ghi tên file mà bạn muốn cài đặt. Ví dụ: debian.sh hoặc ubuntu.sh,...: " DISTRO
        sleep 1
        clear
        echo "==> Lựa chọn của bạn là: $DISTRO - Bắt đầu cài đặt"
        DISTRO_INSTALL="${DISTRO%.sh}"
        echo "DISTRO_ARCH=x86_64" >> $PREFIX/etc/proot-distro/$DISTRO
        proot-distro install $DISTRO_INSTALL
        echo ${G}"Đã xong. Hãy đăng nhập Distro với câu lệnh: 'proot-distro login $DISTRO_INSTALL' (thêm --shared-tmp nếu muốn sử dụng với Termux:X11)"
        ;;
    *)
        echo ${R}"Lỗi: Lựa chọn của bạn không hợp lệ, hãy lựa chọn 1 hoặc 2 để tiếp tục!"
        ;;
esac