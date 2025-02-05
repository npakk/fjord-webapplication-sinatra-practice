# frozen_string_literal: true

require 'json'
require 'sinatra'
require 'sinatra/reloader'
require 'rack'

APP_NAME = 'メモアプリ'
MEMO_FILE = 'memos.json'

set :show_exceptions, false

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def new?
    params['id'].nil?
  end
end

error do
  status 400
  @error_msg = env['sinatra.error']

  if new?
    @page_title = "#{APP_NAME}：新規作成"
  else
    @id = params['id'].to_i
    memo = Memo.read(@id)
    @page_title = "#{APP_NAME}：#{memo.dig('data', 'title')}"
  end

  @title = params[:title]
  @body = params[:body]
  erb new? ? :new : :edit
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
  raise 'タイトルは必須入力です。' if params[:title].empty?

  id = Memo.create(params[:title], params[:body])
  redirect "/memos/#{id}/show"
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
  raise 'タイトルは必須入力です。' if params[:title].empty?

  id = params['id'].to_i
  Memo.update(id, params['title'], params['body'])
  redirect "/memos/#{id}/show"
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
