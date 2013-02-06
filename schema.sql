-- keeps 'updated' field up to date
-- intended to be used in an AFTER UPDATE trigger
CREATE OR REPLACE FUNCTION upd_timestamp() RETURNS TRIGGER 
LANGUAGE plpgsql
AS
$$
BEGIN
    NEW.updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- site has many forums
-- site belongs to user (if they are an admin)
-- NOTE: id is the base domain (string)
CREATE TABLE sites (
  id      VARCHAR(256) NOT NULL,
  user_id BIGINT NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  PRIMARY KEY (id)
);
CREATE TRIGGER sites_timestamp AFTER UPDATE ON sites FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- forum has many posts
-- forum has many child forums
-- if a forum does not have a parent, then it is a top-level category
-- if a forum does not have a parent, then it cannot have posts
CREATE TABLE forums (
  id          BIGSERIAL NOT NULL,
  parent_id   BIGINT,
  site_id     VARCHAR(256) NOT NULL,
  title       VARCHAR(256) NOT NULL,
  slug        VARCHAR(256) NOT NULL,
  description VARCHAR(1024) NOT NULL,
  media_url   VARCHAR(1024),
  created     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated     TIMESTAMP,
  PRIMARY KEY (id)
);
CREATE TRIGGER forums_timestamp AFTER UPDATE ON forums FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- user has many auths
-- user has many aliases
-- user has many sites (if they are admin)
-- user has many posts
CREATE TABLE users (
  id      BIGSERIAL NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  PRIMARY KEY (id)
);
CREATE TRIGGER users_timestamp AFTER UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- alias belongs to user
CREATE TABLE aliases (
  user_id BIGINT NOT NULL,
  site_id VARCHAR(256) NOT NULL,
  name    VARCHAR(64) NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  PRIMARY KEY (user_id, site_id)
);
CREATE TRIGGER aliases_timestamp AFTER UPDATE ON aliases FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- auth belongs to user
CREATE TABLE auths (
  user_id BIGINT NOT NULL,
  type    VARCHAR(16),
  json    VARCHAR(1024),
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  PRIMARY KEY (user_id, type)
);
CREATE TRIGGER auths_timestamp AFTER UPDATE ON auths FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- post has many child posts
-- post belongs to user
-- post belongs to forum
CREATE TABLE posts ( 
  id        BIGSERIAL NOT NULL,
  parent_id BIGINT,
  user_id   BIGINT NOT NULL,
  forum_id  BIGINT NOT NULL,
  title     VARCHAR(256) NOT NULL,
  body      VARCHAR(1024) NOT NULL,
  created   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated   TIMESTAMP,
  PRIMARY KEY (id)
);
CREATE TRIGGER posts_timestamp AFTER UPDATE ON posts FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

CREATE TABLE docs (
  key           VARCHAR(64) NOT NULL,
  type          VARCHAR(64) NOT NULL,
  json          TEXT NOT NULL,
  index_enabled BOOLEAN NOT NULL,
  index_dirty   BOOLEAN NOT NULL,
  created       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated       TIMESTAMP,
  PRIMARY KEY (key, type)
);
CREATE TRIGGER docs_timestamp AFTER UPDATE ON docs FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();
