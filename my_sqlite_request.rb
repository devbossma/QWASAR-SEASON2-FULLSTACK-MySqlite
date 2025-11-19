require "csv"
require_relative "my_csv"  # Assuming MyCSV class is in my_csv.rb

class MySqliteRequest
  attr_reader :file_path, :from_table, :select_columns, :where_conditions,
    :join_info, :order_config, :operation_type, :insert_data,
    :update_data, :result

  def initialize(table_name = nil)
    @file_path = nil
    @from_table = nil
    @select_columns = "*"
    @where_conditions = nil
    @join_info = nil
    @order_config = nil
    @operation_type = :select
    @insert_data = nil
    @update_data = nil
    @result = []

    # If table name provided in constructor, set it up
    from(table_name) if table_name
  end

  # Set the table to query from
  def from(table_name)
    return self if table_name.nil? || table_name.empty?

    # Add .csv extension if not present
    @file_path = table_name.end_with?(".csv") ? table_name : "#{table_name}.csv"
    @from_table = table_name.gsub(".csv", "")

    # Validate file exists early
    unless File.exist?(@file_path)
      raise IOError, "Table '#{@from_table}' does not exist"
    end

    self  # Return self for chaining
  end

  # Select specific columns (or * for all)
  def select(columns)
    @select_columns = columns
    self
  end

  # Add WHERE condition
  def where(column_name, value)
    @where_conditions = {column: column_name, value: value}
    self
  end

  # Join with another table
  def join(column_on_db_a, filename_db_b, column_on_db_b)
    @join_info = {
      column_a: column_on_db_a,
      table_b: filename_db_b,
      column_b: column_on_db_b
    }
    self
  end

  # Order results
  def order(direction, column_name)
    @order_config = {
      direction: direction,  # :asc or :desc
      column: column_name
    }
    self
  end

  # Set operation to INSERT
  def insert(table_name)
    @operation_type = :insert
    from(table_name)

    # Validate file exists
    unless @file_path && File.exist?(@file_path)
      raise IOError, "Table '#{table_name}' does not exist"
    end

    self
  end

  # Set values for INSERT
  def values(data)
    @insert_data = data
    self
  end

  # Set operation to UPDATE
  def update(table_name)
    @operation_type = :update
    from(table_name)
    self
  end

  # Set values for UPDATE
  def set(data)
    @update_data = data
    self
  end

  # Set operation to DELETE
  def delete
    @operation_type = :delete
    self
  end

  # Execute the built query
  def run
    return nil unless valid_request?

    case @operation_type
    when :select
      execute_select
    when :insert
      execute_insert
    when :update
      execute_update
    when :delete
      execute_delete
    else
      raise StandardError.new("Unknown Query")
    end
  end

  private

  # Validate that we have minimum requirements
  def valid_request?
    case @operation_type
    when :select
      !@file_path.nil? && File.exist?(@file_path)
    when :insert
      !@file_path.nil? && !@insert_data.nil?
    when :update
      !@file_path.nil? && !@update_data.nil?
    when :delete
      !@file_path.nil?
    else
      false
    end
  end

  # Execute SELECT query
  def execute_select
    csv = MyCSV.new(@file_path)
    rows = csv.rows
    current_header = csv.header

    # Apply JOIN first (before WHERE filter)
    if @join_info
      csv_b = MyCSV.new(normalize_filename(@join_info[:table_b]))
      join_result = csv.join(csv_b, @join_info[:column_a], @join_info[:column_b])
      rows = join_result[:rows]
      current_header = join_result[:header]
    end

    # Apply WHERE filter after JOIN
    if @where_conditions
      # Need to manually filter since we might have a custom header now
      col_index = current_header.index(@where_conditions[:column])
      unless col_index
        raise ArgumentError, "Column '#{@where_conditions[:column]}' does not exist in table"
      end
      rows = rows.select { |row| row[col_index] == @where_conditions[:value] }
    end

    # Apply ORDER (pass custom header if we have a join)
    if @order_config
      rows = csv.sort_rows(rows, @order_config[:column], @order_config[:direction], current_header)
    end

    # Apply SELECT columns (pass custom header if we have a join)
    rows = csv.select_columns(rows, @select_columns, current_header)

    # Convert to hash format for output (pass custom header if we have a join)
    csv.rows_to_hash(rows, @select_columns, current_header)
  end

  # Execute INSERT query
  def execute_insert
    csv = MyCSV.new(@file_path)
    new_id = csv.insert(@insert_data)

    # Return confirmation
    [{"id" => new_id, "status" => "inserted"}]
  end

  # Execute UPDATE query
  def execute_update
    csv = MyCSV.new(@file_path)

    # Apply WHERE condition if exists
    column = @where_conditions ? @where_conditions[:column] : nil
    value = @where_conditions ? @where_conditions[:value] : nil

    updated_count = csv.update(@update_data, column, value)

    # Return confirmation
    [{"updated_rows" => updated_count}]
  end

  # Execute DELETE query
  def execute_delete
    csv = MyCSV.new(@file_path)

    # Apply WHERE condition if exists
    column = @where_conditions ? @where_conditions[:column] : nil
    value = @where_conditions ? @where_conditions[:value] : nil

    deleted_count = csv.delete(column, value)

    # Return confirmation
    [{"deleted_rows" => deleted_count}]
  end

  # Normalize filename to include .csv extension
  def normalize_filename(filename)
    filename.end_with?(".csv") ? filename : "#{filename}.csv"
  end
end
