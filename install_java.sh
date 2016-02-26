#!/bin/sh

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

if [[ $# < 1 ]]; then
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
echo "Installing java $JAVA_VER"

if [ "$(ls -A $DEST/$JAVA_VER 2> /dev/null)" ]; then
    read -p "$DEST/$JAVA_VER containing files, do you want to delete them? (y/n) " ANS
    if [[ x$ANS = xy ]]; then
        if [[ $(dirname $(realpath $1)) == "$DEST/$JAVA_VER" ]]; then
            JDK_FILE="/tmp/$(basename $1)"
            echo "Copying $1 to $JDK_FILE"
            cp -v $1 $JDK_FILE
        fi

        echo "Deleting files..."
        rm -r "$DEST/$JAVA_VER"
    else
        echo "Operation canceled"
        exit 0
    fi
fi
mkdir -pv $DEST
[ -z $JDK_FILE ] &&JDK_FILE=$(realpath $1);


cd $DEST

echo Extracting $JDK_FILE to $DEST...
cp -v $JDK_FILE $DEST
tar -xf $(basename $JDK_FILE)

if [[ $(dirname $JDK_FILE) == "/tmp" ]]; then
    echo "Deleting $JDK_FILE"
    rm -v $JDK_FILE
fi

echo -e "\nPlease manual edit /etc/profile to set JAVA_HOME, JRE_HOME and PATH\n"
sleep 2

if which vim 1>/dev/null 2>&1; then
    vim /etc/profile
else
    vi /etc/profile
fi

source /etc/profile
echo -e "Testing installation...\n"
java -version
javac -version
echo -e "\n"

read -p "Would you like to delete other versions of java in $DEST? (y/n) " ANS_DEL
if [[ x$ANS_DEL == xy ]]; then
    for file in $DEST/*; do
        if [ -d $file ] && [[ $(basename $file) != $JAVA_VER ]] || [ -f $file ] && [[ $(basename $JDK_FILE) != $(basename $file) ]]; then
            rm -rv $file
        fi
    done
fi

if [ "$(which firefox 2>/dev/null)" ]; then
    read -p "You have Firefox installed, would you like to install plugin for Firefox? (y/n) " ANS_F
    if [ x$ANS_F = xy ]; then
        read -p "Please enter the firefox-plugin path (press [ENTER] for /usr/lib/mozilla/plugins) " F_PLG_PATH
        [[ $F_PLG_PATH == "" ]] && F_PLG_PATH="/usr/lib/mozilla/plugins"
        mkdir -pv $F_PLG_PATH
        sudo ln -svf $DEST/$JAVA_VER/jre/lib/amd64/libnpjp2.so $F_PLG_PATH
    fi
fi
echo "Installation completed"
