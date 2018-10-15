require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end

end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.send("primary_key=", options[:primary_key] || :id)
    self.send("foreign_key=", options[:foreign_key] || "#{name}_id".to_sym)
    self.send("class_name=", options[:class_name] || "#{name}".camelcase)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.send("primary_key=", options[:primary_key] || :id)
    self.send("foreign_key=", options[:foreign_key] || "#{self_class_name}Id".underscore.to_sym)
    self.send("class_name=", options[:class_name] || "#{name}".singularize.camelcase)
  end
end

# class User
#
#   belongs_to :location,
#     primary_key: :hjk,
#     foregn_key: :location_id,
#     class_name: :Location
#
#   has_many :reviews
#     primary_key: :id,
#     foreign_key: :user_id,
#     class_name: :Review
# end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options
    @ass_options["#{name}".to_sym] = options

    define_method(name.to_s) do
      foreign_key_val = self.send("#{options.foreign_key}")
      class_name = options.model_class #Human

      result = class_name.where({
        options.primary_key => foreign_key_val
      })

      result.first
    end
  end

  def has_many(name, options = {})
    self_class_name = self
    options = HasManyOptions.new(name, self_class_name, options)

    define_method(name) do
      primary_key_val = self.send("#{options.primary_key}")
      class_name = options.model_class

      class_name.where({
        options.foreign_key => primary_key_val
      })
    end
  end

  def assoc_options
    @ass_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
