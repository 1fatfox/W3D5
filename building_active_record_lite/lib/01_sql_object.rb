require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
attr_accessor :table_name, :attributes, :columns

  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    final = []
    @columns.first.each do |column|
      final << column.to_sym
    end
    final
  end

  def self.finalize!
    columns = self.columns
    columns.each do |c|
      define_method("#{c}=") { |val| self.attributes[c] = val }
      define_method(c) { self.attributes[c] }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    low = "#{self}"
    @table_name = "#{low.downcase}s"
  end

  def self.all
    result = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL
    self.parse_all(result)
  end

  def self.parse_all(results)
    class_name = self.table_name.capitalize.singularize.constantize
    results.map do |h|
      class_name.new(h)
    end
  end

  def self.find(id)
    self.all.each do |obj|
      return obj if obj.id == id
    end
    nil
  end

  def initialize(params = {})
    params.each do |param, val|
      raise "unknown attribute '#{param}'" unless self.class.columns.include?(param.to_sym)
      self.send("#{param}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    final = []
    self.class.columns.each do |col|
      final << self.attributes[col]
    end
    final
  end

  def insert
    n = self.attribute_values.length
    qs = ""
    n.times do
      qs += "?"
    end

    DBConnection.execute(<<-SQL, self.attribute_values)
      INSERT INTO
        #{self.class.table_name}
      VALUES
        #{qs}
    SQL
    self.id = last_insert_row_id
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
