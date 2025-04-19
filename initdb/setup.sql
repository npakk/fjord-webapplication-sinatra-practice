create database sinatra_app;
\c sinatra_app;
create table memos (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title text NOT NULL,
  body text NOT NULL,
  is_delete boolean NOT NULL
);
