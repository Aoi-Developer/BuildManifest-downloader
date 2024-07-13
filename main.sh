#!/bin/sh

echo "#BuildManifest downloader Ver1.1"

#jqコマンドを確認します
which jq >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  if [ "$(uname)" == 'Darwin' ]; then
    #MacOS
    which brew >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
      #存在しない場合はインストールするようメッセージを出力して実行を停止します
      echo "E:brew command not installed"
      echo "Enter the following command to install"
      echo " bash <(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      exit 1
    else
      #Homebrewがあればlibzipをインストールします
      brew install jq
    fi
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    #Ubuntuの場合
    sudo apt update
    sudo apt install jq -y
  fi
fi

#pzbコマンドを確認します
which pzb >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  if [ "$(uname)" == 'Darwin' ]; then
    #MacOS
    which brew >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
      #存在しない場合はインストールするようメッセージを出力して実行を停止します
      echo "E:brew command not installed"
      echo "Enter the following command to install"
      echo " bash <(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      exit 1
    else
      #Homebrewがあればlibzipをインストールします
      brew install libzip
    fi
    curl -OL https://github.com/tihmstar/partialZipBrowser/releases/download/36/buildroot_macos-latest.zip
    unzip buildroot_macos-latest.zip buildroot_macos-latest/usr/local/bin/pzb
    rm -f buildroot_macos-latest.zip
    mkdir ~/Applications/pzb
    cp buildroot_macos-latest/usr/local/bin/pzb ~/Applications/pzb/
    chmod -R 766 ~/Applications/pzb/
    rm -rf buildroot_macos-latest
    export PATH="$PATH:~/Applications/pzb/"
    touch ~/.zshrc && echo export PATH="$PATH:~/Applications/pzb/" >> .zshrc
    touch ~/.bashrc && echo export PATH="$PATH:~/Applications/pzb/" >> .bashrc
    source ~/.zshrc
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    #Ubuntuの場合
    which curl > /dev/null 2>&1 && which unzip > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
      sudo apt update
      sudo apt install curl unzip jq -y
    fi
    curl -OL https://github.com/tihmstar/partialZipBrowser/releases/download/36/buildroot_ubuntu-latest.zip
    unzip buildroot_ubuntu-latest.zip buildroot_ubuntu-latest/usr/local/bin/pzb
    rm -f buildroot_ubuntu-latest.zip
    sudo cp buildroot_ubuntu-latest/usr/local/bin/pzb /usr/bin/
    sudo chmod -R 777 /usr/bin/pzb
    rm -rf buildroot_ubuntu-latest
  fi
fi

#ここから取得処理
if [ $# = 1 ]; then
  if [ -d $1 ]; then
    cd $1
  else
    mkdir $1
    cd $1
  fi
  if [ -d release ]; then
    cd release
  else
    mkdir release
    cd release
  fi
  release=$(curl -s "https://api.ipsw.me/v4/device/`echo $1`?type=ipsw" | jq ".firmwares[]" 2>/dev/null)
  beta=$(curl -s "https://aoiblog.jp/betas/`echo $1`" | jq ".firmwares[]" 2>/dev/null)
  numbershsh=0
  releasename=$(echo $release | jq -r '.buildid' 2>/dev/null)
  betaname=$(echo $beta | jq -r '.buildid' 2>/dev/null)



  while [ $numbershsh != $(echo $release | jq .url | wc -l) ]
  do
    numbershsh=$(( $numbershsh+1 ))
    if [ -f $(echo $1)_$(echo "$releasename" | sed -n `echo $numbershsh`P)_BuildManifest.plist ]; then
      echo $(echo $1)_$(echo "$releasename" | sed -n `echo $numbershsh`P)_BuildManifest.plistは存在します
    else
      pzb -g BuildManifest.plist $(echo $release | jq -r '.url' 2>/dev/null | sed -n `echo $numbershsh`P)
      mv BuildManifest.plist $(echo $1)_$(echo "$releasename" | sed -n `echo $numbershsh`P)_BuildManifest.plist
      rm -f BuildManifest.plist
    fi
  done
  cd ../
  if [ -d beta ]; then
    cd beta
  else
    mkdir beta
    cd beta
  fi
  numbershsh=0
  while [ $numbershsh != $(echo $beta | jq .url | wc -l) ]
  do
    numbershsh=$(( $numbershsh+1 ))
    if [ -f $(echo $1)_$(echo "$betaname" | sed -n `echo $numbershsh`P)_BuildManifest.plist ]; then
      echo $(echo $1)_$(echo "$betaname" | sed -n `echo $numbershsh`P)_BuildManifest.plistは存在します
    else
      pzb -g BuildManifest.plist $(echo $beta | jq -r '.url' 2>/dev/null | sed -n `echo $numbershsh`P)
      mv BuildManifest.plist $(echo $1)_$(echo "$betaname" | sed -n `echo $numbershsh`P)_BuildManifest.plist
      rm -f BuildManifest.plist
    fi
  done
  echo beta版 $(echo $beta | jq .url | wc -l)個のBuildManifestを保存しました。
  echo release版 $(echo $release | jq .url | wc -l)個のBuildManifestを保存しました。
fi
