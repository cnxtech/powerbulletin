CREATE TABLE sequences (
  name VARCHAR(64) NOT NULL,
  val  BIGINT      NOT NULL,
  PRIMARY KEY(name)
);

CREATE TABLE users (
  id    BIGINT NOT NULL,
  login VARCHAR(32) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE comments (
  id      BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  post_id BIGINT NOT NULL,
  body    VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE posts ( 
  id    BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  title VARCHAR(64) NOT NULL,
  body  VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE docs (
  key VARCHAR(100) NOT NULL,
  type VARCHAR(100) NOT NULL,
  json VARCHAR(1048576) NOT NULL,
  index_enabled TINYINT NOT NULL,
  index_dirty TINYINT NOT NULL,
  PRIMARY KEY (key)
);

CREATE PROCEDURE select_doc_by_type_and_key AS
  SELECT json FROM docs WHERE type=? AND key=? LIMIT 1;
