PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);


CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  associated_author INTEGER NOT NULL,

  FOREIGN KEY (associated_author) REFERENCES users(id)
);

CREATE TABLE question_follows(
  id INTEGER PRIMARY KEY,
  users_id INTEGER NOT NULL,
  questions_id INTEGER NOT NULL,

  FOREIGN KEY (users_id) REFERENCES users(id),
  FOREIGN KEY (questions_id) REFERENCES questions(id)
);


CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  subject_question_id INTEGER NOT NULL,
  parent_reply INTEGER,
  writer INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (subject_question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply) REFERENCES replies(id),
  FOREIGN KEY (writer) REFERENCES users(id)
);


CREATE TABLE questions_like(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);


INSERT INTO
  users (fname, lname)
VALUES
  ('Adi', 'K'),
  ('Joseph', 'Kung'),
  ('Bob', 'Smith');

INSERT INTO
  questions (title, body, associated_author)
VALUES
  ('How to create table?', 'Please help', 1),
  ('How to create table???', 'Please help more', 2);


INSERT INTO
  question_follows (users_id, questions_id)
VALUES
  (3,1),
  (1,2),
  (3,2),
  (2,1);

INSERT INTO
  replies (subject_question_id, parent_reply, writer, body)
VALUES
  (1, NULL, 3, 'Drop out'),
  (1, 1, 2, 'Write a create statement'),
  (1, 1, 1, 'Yeah that sounds right');

INSERT INTO
  questions_like (question_id, user_id)
VALUES
  (1, 1),
  (1, 2),
  (2, 1),
  (2, 2),
  (1, 3);
