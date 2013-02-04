(require 'build-homepage)
(require 'next-in-sequence)
(require 'defproc)
(require 'u)

(defproc add-post2
  [long long String String] long
  [this user-id forum-id title body]
  (merge (next-in-sequence/statements) (build-homepage/statements)
    {"insert-post"
       (stmt "INSERT INTO posts (id, created, user_id, forum_id, title, body)
              VALUES (?, ?, ?, ?, ?, ?)")})

  (let [now (new java.util.Date)
        id (next-in-sequence/run this "posts")]
    (u/queue this "insert-post" id now user-id forum-id title body)
    (u/execute this)
    (build-homepage/run this now)
    id))
