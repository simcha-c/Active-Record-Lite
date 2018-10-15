require_relative '03_associatable'
require 'byebug'
# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      through_foreign_key = self.attributes[through_options.foreign_key]

      source_options = through_options.model_class.assoc_options[source_name]
      debugger
      result = DBConnection.execute(<<-SQL)
        SELECT
          #{source_options.table_name}.*
        FROM
          #{through_options.table_name}
        JOIN
          #{source_options.table_name} ON #{through_options.table_name}.#{source_options.foreign_key} = #{source_options.table_name}.#{through_options.primary_key}
        WHERE
          #{through_options.table_name}.#{through_options.primary_key} = #{through_foreign_key}
      SQL

      source_options.model_class.parse_all(result).first
    end
  end
end

# self cat
# through_options = human
# source_options = house
