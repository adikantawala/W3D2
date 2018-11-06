require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end


class Question
  def self.find_by_id
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    return nil unless question.length > 0

    Question.new(question.first)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @associated_author = options['associated_author']
  end
end

class User
  def self.find_by_id
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL

    return nil unless user.length > 0

    User.new(user.first)
  end

  def self.find_by_name
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL

    return nil unless user.length > 0

    user.map { |single_person| User.new(single_person) }
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
end

class Reply
  def self.find_by_id
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    return nil unless reply.length > 0

    Reply.new(reply.first)
  end

  def initialize(options)
    @id = options['id']
    @subject_question_id = options['subject_question_id']
    @parent_reply = options['parent_reply']
    @writer = options['writer']
    @body = options['body']
  end
end

class QuestionsLike
  def self.find_by_id
    questions = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions_like
    WHERE
      id = ?
    SQL
    return nil unless questions.length > 0

    QuestionsLike.new(questions.first)
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
end

class QuestionsFollow
  def self.find_by_id
    questions = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions_follows
    WHERE
      id = ?
    SQL
    return nil unless questions.length > 0

    QuestionsFollow.new(questions.first)
  end

  def initialize(options)
    @id = options['id']
    @users_id = options['users_id']
    @questions_id = options['questions_id']
  end
end
