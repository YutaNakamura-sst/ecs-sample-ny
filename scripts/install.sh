#!/bin/bash

sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq

#各種ユーティリティのバージョンを最新状態に更新する
## -q：サイレントモードで実行
pip install --upgrade pip awscli aws-sam-cli -q --no-warn-script-location

#共通の設定
## 各種使用するユーティリティをpipコマンドでインストール
# pip install -r requirements.txt -q --no-warn-script-location

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip > /dev/null 2>&1
ls -l /root/.pyenv/shims/aws
./aws/install --bin-dir /root/.pyenv/shims --install-dir /usr/local/aws-cli --update > /dev/null 2>&1