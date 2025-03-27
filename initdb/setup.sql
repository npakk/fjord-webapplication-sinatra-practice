create database sinatra_app;
\c sinatra_app;
create table memos (
  id serial PRIMARY KEY,
  title text NOT NULL,
  body text NOT NULL
);
