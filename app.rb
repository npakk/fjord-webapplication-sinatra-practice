# frozen_string_literal: true

require 'json'
require 'sinatra'
require 'sinatra/reloader'
require 'rack'

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
  memos = Memo.read_all
  @memos = memos.reject do |memo|
    memo['is_delete']
  end
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
  @page_title = "#{APP_NAME}：#{memo.dig('data', 'title')}"
  @title = memo.dig('data', 'title')
  @body = memo.dig('data', 'body')
  erb :show
end

get '/memos/:id/edit' do
  @id = params['id'].to_i
  memo = Memo.read(@id)
  @page_title = "#{APP_NAME}：#{memo.dig('data', 'title')}"
  @title = memo.dig('data', 'title')
  @body = memo.dig('data', 'body')
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
  def self.write(memos)
    File.open(MEMO_FILE, 'w') do |f|
      JSON.dump(memos, f)
    end
  end

  def self.create(title, body)
    memos = read_all
    new_id = memos.empty? ? 0 : memos.last['id'] + 1
    memo = { id: new_id, data: { title: title, body: body }, is_delete: false }
    memos.push(memo)
    write(memos)
    new_id
  end

  def self.read_all
    return [] unless File.exist?(MEMO_FILE)

    File.open(MEMO_FILE, 'r') do |f|
      JSON.parse(f.read)
    end
  end

  def self.read(id)
    memos = read_all

    memos.find do |memo|
      memo['id'] == id
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
