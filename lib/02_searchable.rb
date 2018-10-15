require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'

module Searchable
  def where(params)
    question_marks = []
    vals = []
    params.each do |k, v|
      question_marks << "#{k} = ?"
      vals << v
    end

    result = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{question_marks.join(" AND ")}
    SQL

    self.parse_all(result)
  end

end

class SQLObject
  extend Searchable
end
