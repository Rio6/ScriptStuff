#!/bin/bash

# This script will install Oracle Java in your computer.
# This was wirtten for Arch Linux, if you need for other distributions, you may need to change something.
# 
# Arthor: Rio
# 2016/2/21

# Change DEST to chage the installation location.
DEST="/usr/local/java"

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

if [ $# = 0 ]; then
    echo "Usage: $0 <jdk_file>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: $1: file not found" 1>&2
    exit 1
fi

if file $1 | grep gzip > /dev/null ; then
    JAVA_VER=$(tar -tf $1 | head -n1 | tr -d "/")
else
    echo "$1 is not a valid gzip file" 1>&2
    exit 1
fi

JDK_FILE=$(realpath $1);
ARCH="${JDK_FILE##*-}"
ARCH="${ARCH%.tar.gz}"

firefox_plugin() {
    if [ "$(which firefox 2>/dev/null)" ]; then
        read -p "You have Firefox installed, would you like to install plugin for Firefox? (y/n) [y] " ANS_F
        if [ x$ANS_F = xy ] || [ -z $ANS_F ]; then
            [ $ARCH == x64 ] && DFT_PLG_PATH="/usr/lib64/mozilla/plugins" || DFT_PLG_PATH="/usr/lib/mozilla/plugins"
            DFT_PLG_PATH=${MOZ_PLUGIN_PATH:-$DFT_PLG_PATH}
            read -p "Please enter the firefox-plugin path [$DFT_PLG_PATH] " F_PLG_PATH
            if [ -z $F_PLG_PATH ]; then
                if [ $ARCH == x64 ]; then 
                    F_PLG_PATH=$DFT_PLG_PATH
                else
                    F_PLG_PATH=$DFT_PLG_PATH
                fi
            fi
            mkdir -pv $F_PLG_PATH
            if [ $ARCH == x64 ]; then
                ln -svf $DEST/$JAVA_VER/jre/lib/amd64/libnpjp2.so $F_PLG_PATH
            else
                ln -svf $DEST/$JAVA_VER/jre/lib/i386/libnpjp2.so $F_PLG_PATH
            fi
        fi
    fi
}

delete_old() {
    read -p "Would you like to delete other versions of java in $DEST? (y/n) [y] " ANS_DEL
    if [ x$ANS_DEL = xy ] || [ -z $ANSDEL ]; then
        for file in $DEST/*; do
            if [ -d $file ] && [ $(basename $file) != $JAVA_VER ] || [ -f $file ] && [ $(basename $JDK_FILE) != $(basename $file) ]; then
                rm -r $file
                echo "Removed $file"
            fi
        done
    fi
}

test_install() {
    source /etc/profile
    echo -e "Testing installation...\n"
    java -version
    javac -version
    echo -e "\n"
}

set_path() {
    if [ -d /etc/profile.d ]; then
        echo "Setting JAVA_HOME, JRE_HOME, PATH to /etc/profile.d/java.sh"
        echo "
JAVA_HOME=$DEST/$JAVA_VER"'
JRE_HOME=$JAVA_HOME/jre

PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH

export JAVA_HOME JRE_HOME PATH' > /etc/profile.d/java.sh
        chmod 755 /etc/profile.d/java.sh

    else

        echo -e "\nPlease manual edit /etc/profile to set JAVA_HOME, JRE_HOME and PATH\n"
        sleep 2

        if which vim 1>/dev/null 2>&1; then
            vim /etc/profile
        else
            vi /etc/profile
        fi
    fi
    source /etc/profile
}

copy_files() {
    echo "Installing java $JAVA_VER"


    if [ -f $DEST ]; then
        rm -v $DEST
    fi
    if [ ! -e $DEST ]; then
        mkdir -v $DEST
    fi

    cp -v $JDK_FILE $DEST

    if [ "$(ls -A $DEST/$JAVA_VER 2> /dev/null)" ]; then
        read -p "$DEST/$JAVA_VER containing files, do you want to delete them? (y/n) [n] " ANS
        if [ x$ANS = xy ]; then
            echo "Deleting files..."
            rm -r "$DEST/$JAVA_VER"
        else
            echo "Operation canceled"
            exit 0
        fi
    fi
    mkdir -pv $DEST

    cd $DEST

    echo Extracting $JDK_FILE to $DEST...
    tar -xf $(basename $JDK_FILE)
}

echo -e "0) Every thing\n1) extract files\n2) set variebles\n3) remove old files\n4) install plugin\n5) test installation\nq) quit"
read -p "Enter selection: " ACT

case $ACT in
    0)
        copy_files $@
        set_path
        test_install
        delete_old
        firefox_plugin
    ;;
    1)
        copy_files $@
    ;;
    2)
        set_path
    ;;
    3)
        delete_old
    ;;
    4)
        firefox_plugin
    ;;
    5)
        test_install
    ;;
    q)
        echo "Quit"
        exit
    ;;
    *)
        echo Unknown number
    ;;
esac

echo "Finished"
