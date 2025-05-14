create database sinatra_app;
\c sinatra_app;
create table memos (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title text NOT NULL,
  body text NOT NULL,
  is_delete boolean NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
create function update_timestamp()
returns trigger as $$
begin
    IF (TG_OP = 'UPDATE') then
        new.updated_at := now();
        return NEW;
    end IF;
end;
$$ language plpgsql;
create trigger update_timestamp_trigger
before update on memos
for each row
execute procedure update_timestamp();
