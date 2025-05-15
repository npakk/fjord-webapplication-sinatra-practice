# fjord-webapplication-sinatra-practice
フィヨルドブートキャンプのプラクティスで作成したメモアプリです。  
WebアプリケーションフレームワークのSinatraで実装しており、メモのタイトルと内容をDocker上のPostgreSQLに保存します。

## Requirements
Ruby >= 3.4.0  
Docker

## Installation
```console
git clone https://github.com/npakk/fjord-webapplication-sinatra-practice.git
# レビュー時は開発ブランチを指定してください。
# git clone -b feature https://github.com/npakk/fjord-webapplication-sinatra-practice.git 

# 環境変数によって実行環境を指定し、開発環境の場合は.envファイルをdotenvで読み込みます。
export ENVIRONMENT='development'
cd fjord-webapplication-sinatra-practice
cp .env.sample .env

# DBユーザーとパスワードを任意で変更
vi .env

docker compose up -d

bundle

ruby app.rb
```

上記コマンドをお持ちのターミナルエミュレータで実行後、  
ブラウザで`http://localhost:4567`へアクセスするとお使いいただけます。
