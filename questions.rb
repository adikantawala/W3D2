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
  attr_reader :id, :title, :body, :associated_author
  def self.find_by_id(id)
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

  def author
    User.find_by_id(self.associated_author)
  end
  def replies
    Reply.find_by_question_id(self.id)
  end

  def self.find_by_author_id(author_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        associated_author = ?
    SQL
    return nil if question.length == 0
    question.map{|single_q| Question.new(single_q)}
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @associated_author = options['associated_author']
  end
end

class User
  attr_reader :id, :fname, :lname

  def self.find_by_id(id)
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

  def self.find_by_name(fname,lname)
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

  def authored_questions
    Question.find_by_author_id(self.id)
  end
  def authored_replies
    Reply.find_by_user_id(self.id)
  end
end

class Reply
  def self.find_by_id(id)
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

  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        writer = ?
    SQL

    return nil if replies.length == 0

    replies.map {|single_reply| Reply.new(single_reply)}
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        subject_question_id = ?
    SQL

    return nil if replies.length == 0

    replies.map {|single_reply| Reply.new(single_reply)}
  end
end

class QuestionsLike
  def self.find_by_id(id)
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
  def self.find_by_id(id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_follows
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
