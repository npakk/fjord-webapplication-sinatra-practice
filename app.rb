# frozen_string_literal: true

require 'json'
require 'sinatra'
require 'sinatra/reloader'
require 'rack'
require 'pg'
require 'dotenv/load' if ENV['ENVIRONMENT'] == 'development'

APP_NAME = 'メモアプリ'
MEMO_FILE = 'memos.json'

set :show_exceptions, false

before do
  @error_messages = {}
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

error 404 do
  halt erb :not_found
end

get '/' do
  @page_title = "#{APP_NAME}：トップ"
  @memos = Memo.read
  erb :index
end

get '/memos' do
  @page_title = "#{APP_NAME}：新規作成"
  erb :new
end

post '/memos' do
  @error_messages[:title] = 'タイトルは必須入力です。' if params[:title].empty?
  @error_messages[:body] = '本文は必須入力です。' if params[:body].empty?

  if @error_messages.empty?
    id = Memo.create(params[:title], params[:body])
    redirect "/memos/#{id}/show"
  else
    # エラー時に入力内容は初期化せず復元する
    @title = params[:title]
    @body = params[:body]

    body erb :new
  end
end

get '/memos/:id/show' do
  @id = params['id'].to_i
  memo = Memo.read(@id)
  @page_title = "#{APP_NAME}：#{memo['title']}"
  @title = memo['title']
  @body = memo['body']
  erb :show
end

get '/memos/:id/edit' do
  @id = params['id'].to_i
  memo = Memo.read(@id)
  @page_title = "#{APP_NAME}：#{memo['title']}"
  @title = memo['title']
  @body = memo['body']
  erb :edit
end

patch '/memos/:id/edit' do
  @error_messages[:title] = 'タイトルは必須入力です。' if params[:title].empty?
  @error_messages[:body] = '本文は必須入力です。' if params[:body].empty?

  @id = params['id'].to_i

  if @error_messages.empty?
    Memo.update(@id, params['title'], params['body'])
    redirect "/memos/#{@id}/show"
  else
    # エラー時に入力内容は初期化せず復元する
    @title = params[:title]
    @body = params[:body]

    body erb :edit
  end
end

delete '/memos/:id' do
  Memo.delete(params['id'].to_i)
  redirect '/'
end

class Memo
  @conn = PG.connect(
    host: 'localhost',
    port: 5432,
    dbname: 'sinatra_app',
    user: ENV['DB_USER'],
    password: ENV['DB_PASSWORD']
  )

  def self.create(title, body)
    @conn.exec('INSERT INTO memos (title, body, is_delete) VALUES ($1, $2, FALSE)', [title, body])
    new_id
  end

  def self.read(id = nil)
    base_sql = 'SELECT id::int, title::text, body::text FROM memos WHERE is_delete = FALSE'
    order_sql = ' ORDER BY id;'

    if id
      @conn.exec("#{base_sql} AND id = $1 #{order_sql}", [id]).first
    else
      @conn.exec("#{base_sql} #{order_sql}")
    end
  end

  def self.update(id, title, body)
    memos = read_all

    memos.each do |memo|
      if memo['id'] == id
        memo['data']['title'] = title
        memo['data']['body'] = body
      end
    end

    write(memos)
  end

  def self.delete(id)
    memos = read_all

    memos.each do |memo|
      memo['is_delete'] = true if memo['id'] == id
    end

    write(memos)
  end
end
