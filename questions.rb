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

####################################################################

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

  def self.most_liked(n)
    QuestionsLike.most_liked_questions(n)
  end

  def likers
    QuestionsLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionsLike.num_likes_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionsFollow.most_followed_questions(n)
  end

  def followers
    QuestionsFollow.followers_for_question_id(@id)
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



####################################################################
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


  def average_karma
    user = QuestionsDatabase.instance.execute(<<-SQL,@id)
      SELECT
        CAST(COUNT(ql.question_id)AS FLOAT) / COUNT(DISTINCT(questions.title))
      FROM
        questions
      LEFT JOIN
        questions_like AS ql on ql.question_id = questions.id
      WHERE
        questions.associated_author = ?;
      SQL
      return user.first.values.first
  end

  def liked_questions
    QuestionsLike.liked_questions_for_user_id(@id)
  end

  def followed_questions
    QuestionsFollow.followed_questions_for_user_id(@id)
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




####################################################################

class Reply
  attr_reader :id, :subject_question_id ,:parent_reply, :writer,:body
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

  def author
    User.find_by_id(self.writer)
  end

  def question
    Question.find_by_id(self.subject_question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_reply)
  end

  def child_replies
    reply = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_reply = ?
    SQL

    return nil if reply.length == 0
    reply.map {|single_reply| Reply.new(single_reply)}
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


####################################################################

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

  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id,
        fname,
        lname
      FROM
        questions_like
      JOIN
        users ON users.id = questions_like.user_id
      WHERE
        question_id = ?
    SQL

    return nil unless users.length > 0
    users.map{|user| User.new(user)}
  end

  def self.num_likes_for_question_id(question_id)
    count = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        count(users.id) AS Num_Likes
      FROM
        questions_like
      JOIN
        users ON users.id = questions_like.user_id
      WHERE
        question_id = ?
    SQL
    return count.first["Num_Likes"]
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id,
        questions.title,
        questions.body,
        questions.associated_author
      FROM
        questions_like
      JOIN
        questions ON questions.id = questions_like.question_id
      WHERE
        user_id = ?
    SQL

    return nil if questions.empty?
    questions.map {|q| Question.new(q)}
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id,
        questions.title,
        questions.body,
        questions.associated_author
      FROM
        questions_like
      JOIN
        questions
      ON
        questions_like.question_id = questions.id
      GROUP BY
        questions_like.question_id
      ORDER BY
        COUNT(questions_like.user_id) DESC
      LIMIT ?;
    SQL

    return nil if questions.empty?
    questions.map {|q| Question.new(q)}
  end
end


####################################################################


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

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id,
        questions.title,
        questions.body,
        questions.associated_author
      FROM
        question_follows
      JOIN
        questions
      ON
        question_follows.questions_id = questions.id
      GROUP BY
        question_follows.questions_id
      ORDER BY
        COUNT(question_follows.users_id) DESC
      LIMIT ?;
    SQL
    return nil if questions.empty?

    questions.map{|q| Question.new(q)}
  end

  def self.followed_questions_for_user_id(users_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, users_id)
    SELECT
      questions.id,
      questions.title,
      questions.body,
      questions.associated_author

    FROM
      question_follows
    JOIN
      questions
    ON question_follows.questions_id = questions.id
    WHERE
      users_id = ?
    SQL
    return nil if questions.empty?
    questions.map {|q| Question.new(q)}
  end

  def initialize(options)
    @id = options['id']
    @users_id = options['users_id']
    @questions_id = options['questions_id']
  end

  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id,
        users.fname,
        users.lname
      FROM
        question_follows
      JOIN
        users
      ON users.id = question_follows.users_id
      WHERE
        questions_id = ?
    SQL
    return nil unless users.length > 0
    users.map {|user| User.new(user)}
  end
end
