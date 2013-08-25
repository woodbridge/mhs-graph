create table relations (
  id         integer primary key autoincrement,
  start_id   integer not null,
  end_id     integer not null,
  start_name varchar(255) not null,
  end_name   varchar(255) not null 
);
