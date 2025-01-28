# frozen_string_literal: true

require 'json'
require 'sinatra'
require 'sinatra/reloader'
require 'rack'

APP_NAME = 'メモアプリ'
MEMO_FILE = 'memos.json'

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  @page_title = "#{APP_NAME}：トップ"
  @is_show_add_button = true
  memos, = Memo.read
  @memos = memos.reject do |memo|
    memo['is_delete']
  end
  erb :index
end

get '/memos' do
  @page_title = "#{APP_NAME}：新規作成"
  erb :memo_layout, layout: true do
    erb :new
  end
end

post '/memos' do
  id = Memo.create(params[:title], params[:body])
  redirect "/memos/#{id}/show"
end

get '/memos/:id/show' do
  @id = params['id'].to_i
  memo, = Memo.read(@id)
  @is_disable_textbox = true
  @title = memo.dig('data', 'title')
  @body = memo.dig('data', 'body')
  erb :memo_layout, layout: true do
    erb :show
  end
end

get '/memos/:id/edit' do
  @id = params['id'].to_i
  memo, = Memo.read(@id)
  @is_disable_textbox = false
  @title = memo.dig('data', 'title')
  @body = memo.dig('data', 'body')
  erb :memo_layout, layout: true do
    erb :edit
  end
end

patch '/memos/:id' do
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
    memos, next_id = read
    memo = { id: next_id, data: { title: title, body: body }, is_delete: false }
    memos.push(memo)
    write(memos)
    next_id
  end

  def self.read(id = nil)
    return [], 0 unless File.exist?(MEMO_FILE)

    File.open(MEMO_FILE, 'r') do |f|
      data = JSON.parse(f.read)
      return data, data.last['id'] + 1 if id.nil?

      data.find do |memo|
        memo['id'] == id
      end
    end
  end

  def self.update(id, title, body)
    memos, = read

    memos.each do |memo|
      if memo['id'] == id
        memo['data']['title'] = title
        memo['data']['body'] = body
      end
    end

    write(memos)
  end

  def self.delete(id)
    memos, = read

    memos.each do |memo|
      memo['is_delete'] = true if memo['id'] == id
    end

    write(memos)
  end
end
