require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'

# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    result = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    
    @columns = result.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ? @table_name : self.to_s.tableize
  end

  def self.all
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    self.parse_all(result)
  end

  def self.parse_all(results)
    mapped_results = results.map do |obj|
      self.new(obj)
    end

    mapped_results
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL

    self.parse_all(result).first
  end

  def initialize(params = {})
    params.each do |k, v|
      k = k.to_sym
      if !self.class.columns.include?(k)
        raise "unknown attribute '#{k}'"
      else
        self.send("#{k}=", v)
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.attributes.values
  end

  def insert
    num_times = self.class.columns.drop(1).length
    question_marks = (["?"] * num_times).join(",")
    col_names = self.class.columns.drop(1).join(",")

    result = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.send('id=', DBConnection.last_insert_row_id)
  end

  def update

    num_times = self.class.columns.drop(1).length
    col_names = self.class.columns.drop(1)
    question_marks = col_names.map do |name|
      "#{name} = ?"
    end.join(",")

    id = self.send("id")

    result = DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      UPDATE
        #{self.class.table_name}
      SET
        #{question_marks}
      WHERE
        id = #{id}
    SQL

  end

  def save
    self.send('id') ? self.update : self.insert
  end
end
