-- keeps 'updated' field up to date
-- intended to be used in an BEFORE UPDATE trigger
-- http://stackoverflow.com/questions/2362871/postgresql-current-timestamp-on-update?rq=1
-- http://stackoverflow.com/a/10246381
CREATE OR REPLACE FUNCTION upd_timestamp() RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
  --XXX: there is no equality operator for point so line below broken
  --IF (NEW != OLD) THEN
  NEW.updated = CURRENT_TIMESTAMP;
  RETURN NEW;
  --  RETURN NEW;
  --END IF;
  --RETURN OLD;
END;
$$;

-- user has many auths
-- user has many aliases
-- user has many sites (if they are admin)
-- user has many posts
CREATE TABLE users (
  id      BIGSERIAL NOT NULL,
  email   VARCHAR(256),
  stripe_id TEXT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  UNIQUE (email),
  PRIMARY KEY (id)
);
CREATE TRIGGER users_timestamp BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- site has many forums
-- site has many domains
-- site belongs to user (if they are an admin)
-- NOTE: id is the base domain (string)
CREATE TABLE sites (
  id      BIGSERIAL NOT NULL,
  name    VARCHAR(256) NOT NULL,
  config  JSON NOT NULL DEFAULT '{}',
  user_id BIGINT references users(id),
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  PRIMARY KEY (id)
);
CREATE TRIGGER sites_timestamp BEFORE UPDATE ON sites FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- domain belongs to site
CREATE TABLE domains (
  id      BIGSERIAL NOT NULL,
  site_id BIGINT NOT NULL references sites(id),
  name    VARCHAR(256) NOT NULL,
  config  JSON NOT NULL DEFAULT '{}',
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  UNIQUE (name),
  PRIMARY KEY (id)
);
CREATE TRIGGER domains_timestamp BEFORE UPDATE ON domains FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- alias belongs to user
CREATE TABLE aliases (
  user_id     BIGINT NOT NULL references users(id),
  site_id     BIGINT NOT NULL references sites(id),
  name        VARCHAR(64) NOT NULL,
  photo       VARCHAR(256),
  verify      VARCHAR(32),
  verified    BOOLEAN NOT NULL DEFAULT FALSE,
  forgot      VARCHAR(32),
  login_token VARCHAR(32),
  rights      JSON NOT NULL DEFAULT '{"super":0}',
  config      JSON NOT NULL DEFAULT '{}',
  created     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated     TIMESTAMP,
  UNIQUE (site_id, name),
  UNIQUE (site_id, verify),
  UNIQUE (site_id, forgot),
  UNIQUE (site_id, login_token),
  PRIMARY KEY (user_id, site_id)
);
CREATE TRIGGER aliases_timestamp BEFORE UPDATE ON aliases FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- auth belongs to user
CREATE TABLE auths (
  id      DECIMAL NOT NULL,
  user_id BIGINT NOT NULL references users(id),
  type    VARCHAR(16),
  profile JSON NOT NULL DEFAULT '{}',
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  UNIQUE (type, id),
  PRIMARY KEY (user_id, type)
);
CREATE TRIGGER auths_timestamp BEFORE UPDATE ON auths FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- forum has many posts
-- forum has many child forums
-- if a forum does not have a parent, then it is a top-level category
-- if a forum does not have a parent, then it cannot have posts
CREATE TABLE forums (
  id          BIGSERIAL NOT NULL,
  parent_id   BIGINT references forums(id),
  site_id     BIGINT references sites(id) NOT NULL,
  title       VARCHAR(256) NOT NULL,
  slug        VARCHAR(256) NOT NULL,
  uri         TEXT,
  description VARCHAR(1024) NOT NULL,
  media_url   VARCHAR(2000),
  classes     VARCHAR(128),
  created     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated     TIMESTAMP,
  UNIQUE (site_id, uri),
  PRIMARY KEY (id)
);
CREATE TRIGGER forums_timestamp BEFORE UPDATE ON forums FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- post has many child posts
-- post belongs to user
-- post belongs to forum
-- note: thread_id is the topmost parents' id
CREATE TABLE posts (
  id          BIGSERIAL NOT NULL,
  thread_id   BIGINT NOT NULL,
  parent_id   BIGINT,
  user_id     BIGINT references users(id),
  forum_id    BIGINT NOT NULL references forums(id),
  title       VARCHAR(256),
  slug        VARCHAR(256) NOT NULL,
  uri         TEXT,
  body        TEXT NOT NULL,
  html        TEXT NOT NULL,
  media_url   VARCHAR(2000),
  ip          VARCHAR(16),
  loc         POINT,
  views       BIGINT NOT NULL DEFAULT 0,
  index_dirty BOOLEAN NOT NULL DEFAULT 't',
  is_locked   BOOLEAN NOT NULL DEFAULT 'f',
  is_sticky   BOOLEAN NOT NULL DEFAULT 'f',
  created     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated     TIMESTAMP,
  CONSTRAINT potential_loop_prevention CHECK (parent_id <= id),
  UNIQUE (forum_id, uri), -- would rather have site_id in here but oh well
  PRIMARY KEY (id)
);
CREATE TRIGGER posts_timestamp BEFORE UPDATE ON posts FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();
CREATE INDEX ON posts (parent_id);

CREATE TABLE docs (
  site_id       BIGINT references sites(id) NOT NULL,
  key           VARCHAR(64) NOT NULL,
  type          VARCHAR(64) NOT NULL,
  json          TEXT NOT NULL,
  index_enabled BOOLEAN NOT NULL DEFAULT 'f',
  index_dirty   BOOLEAN NOT NULL DEFAULT 'f',
  created       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated       TIMESTAMP,
  PRIMARY KEY (site_id, key, type)
);
CREATE TRIGGER docs_timestamp BEFORE UPDATE ON docs FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- keep track of who moderated what
CREATE TABLE moderations (
  user_id BIGINT NOT NULL references users(id),
  post_id BIGINT NOT NULL references posts(id),
  reason  TEXT NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  PRIMARY KEY (user_id, post_id)
);
CREATE TRIGGER moderations_timestamp BEFORE UPDATE ON moderations FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

CREATE TABLE tags (
  id      BIGSERIAL NOT NULL,
  name    VARCHAR(64),
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  UNIQUE (name),
  PRIMARY KEY (id)
);
CREATE TRIGGER tags_timestamp BEFORE UPDATE ON tags FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

CREATE TABLE tags_posts (
  tag_id  BIGINT NOT NULL REFERENCES tags(id),
  post_id BIGINT NOT NULL REFERENCES posts(id),
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP,
  PRIMARY KEY (tag_id, post_id)
);
CREATE TRIGGER tags_posts_timestamp BEFORE UPDATE ON tags_posts FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- a collection of related messages (like gmail threads)
CREATE TABLE conversations (
  id        BIGSERIAL NOT NULL,
  site_id   BIGINT NOT NULL REFERENCES sites(id),
  created   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated   TIMESTAMP,
  PRIMARY   KEY (id)
);
CREATE TRIGGER conversations_timestamp BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- private messages
CREATE TABLE messages (
  id              BIGSERIAL NOT NULL,
  user_id         BIGINT NOT NULL references users(id),
  conversation_id BIGINT,
  body            TEXT NOT NULL,
  created         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated         TIMESTAMP,
  PRIMARY         KEY (id)
);
CREATE TRIGGER messages_timestamp BEFORE UPDATE ON messages FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- tags associated with messages
CREATE TABLE tags_messages (
  tag_id     BIGINT NOT NULL REFERENCES tags(id),
  message_id BIGINT NOT NULL REFERENCES messages(id),
  created    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated    TIMESTAMP,
  PRIMARY    KEY (tag_id, message_id)
);
CREATE TRIGGER tags_messages_timestamp BEFORE UPDATE ON tags_messages FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- users associated with messages
CREATE TABLE users_conversations (
  user_id         BIGINT NOT NULL REFERENCES users(id),
  conversation_id BIGINT NOT NULL REFERENCES conversations(id),
  created         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated         TIMESTAMP,
  PRIMARY         KEY (user_id, conversation_id)
);
CREATE TRIGGER users_conversations_timestamp BEFORE UPDATE ON users_conversations FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- pages: a lightweight cms
CREATE TABLE pages (
  id              BIGSERIAL NOT NULL,
  site_id         BIGINT NOT NULL REFERENCES sites(id),
  title           VARCHAR(128) NOT NULL DEFAULT '',
  path            VARCHAR(256) NOT NULL,
  config          JSON NOT NULL DEFAULT '{}',
  created         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated         TIMESTAMP,
  UNIQUE (site_id, path),
  PRIMARY KEY (id)
);
CREATE TRIGGER pages_timestamp BEFORE UPDATE ON pages FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- purchases: track each distinct purchase
CREATE TABLE purchases (
  id      BIGSERIAL NOT NULL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  cart    JSON NOT NULL, -- list of products [{id,description,price}, ...]
  receipt JSON NOT NULL, -- stripe charge response metadata which we store
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP
);
CREATE TRIGGER purchases_timestamp BEFORE UPDATE ON purchases FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

-- products: track each product
CREATE TABLE products (
  id VARCHAR(64) NOT NULL PRIMARY KEY,
  description TEXT NOT NULL,
  price BIGINT NOT NULL, -- USD
  config JSON NOT NULL DEFAULT '{}',
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated TIMESTAMP
);
CREATE TRIGGER products_timestamp BEFORE UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();

CREATE TABLE subscriptions (
  site_id     BIGINT NOT NULL REFERENCES sites(id),
  product_id  VARCHAR(64) NOT NULL REFERENCES products(id),
  description TEXT NOT NULL,
  price       BIGINT NOT NULL, -- USD
  created     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated     TIMESTAMP,
  UNIQUE (site_id, product_id)
);
CREATE TRIGGER subscriptions_timestamp BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE PROCEDURE upd_timestamp();
