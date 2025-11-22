require_relative "my_csv"

# The Query Builder class for MySqlite.
# It implements the Builder Pattern to construct SQL-like requests method by method,
# and executes them against CSV files using the {MyCSV} helper class.
#
# @author Saber Yassine
# @version 0.3
class MySqliteRequest
  # @!attribute [r] file_path
  #   @return [String] The full path to the CSV file
  # @!attribute [r] result
  #   @return [Array<Hash>] The result set after running the query
  attr_reader :file_path, :from_table, :select_columns, :where_conditions,
    :join_info, :order_config, :operation_type, :insert_data,
    :update_data, :result

  # Initializes a new request instance.
  #
  # @param table_name [String, nil] Optional table name to start the request
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

    from(table_name) if table_name
  end

  # Sets the table (CSV file) to query from.
  # Adds .csv extension if missing and validates file existence.
  #
  # @param table_name [String] The name of the table/file
  # @return [self] Returns self for method chaining
  # @raise [IOError] If the file does not exist
  def from(table_name)
    return self if table_name.nil? || table_name.empty?
    @file_path = table_name.end_with?(".csv") ? table_name : "#{table_name}.csv"
    @from_table = table_name.gsub(".csv", "")

    unless File.exist?(@file_path)
      raise IOError, "Table '#{@from_table}' does not exist"
    end
    self
  end

  # Sets the columns to select.
  #
  # @param columns [String, Array<String>] Single column name, array of names, or '*'
  # @return [self]
  def select(columns)
    @select_columns = columns
    self
  end

  # Sets a WHERE condition (Equality only).
  #
  # @param column_name [String] The column to filter by
  # @param value [String, Integer] The value to match
  # @return [self]
  # @raise [ArgumentError] If column_name is empty or value is nil
  def where(column_name, value)
    if column_name.nil? || column_name.to_s.strip.empty?
      raise ArgumentError, "Column name cannot be empty"
    end
    if value.nil?
      raise ArgumentError, "Value cannot be nil for WHERE clause"
    end

    @where_conditions = {column: column_name, value: value}
    self
  end

  # Sets the sorting order.
  #
  # @param order [Symbol] :asc or :desc
  # @param column_name [String] The column to sort by
  # @return [self]
  def order(order, column_name)
    @order_config = {
      direction: order,
      column: column_name
    }
    self
  end

  # Configures an INNER JOIN with another CSV file.
  #
  # @param column_on_db_a [String] Column from the primary table
  # @param filename_db_b [String] The filename of the table to join
  # @param column_on_db_b [String] Column from the second table
  # @return [self]
  def join(column_on_db_a, filename_db_b, column_on_db_b)
    @join_info = {
      column_a: column_on_db_a,
      table_b: filename_db_b,
      column_b: column_on_db_b
    }
    self
  end

  # Prepares an INSERT operation.
  #
  # @param table_name [String] The target table
  # @return [self]
  def insert(table_name)
    @operation_type = :insert
    from(table_name)
    self
  end

  # Sets the data for INSERT.
  #
  # @param data [Hash] Key-value pairs of column_name => value
  # @return [self]
  def values(data)
    @insert_data = data
    self
  end

  # Prepares an UPDATE operation.
  #
  # @param table_name [String] The target table
  # @return [self]
  def update(table_name)
    @operation_type = :update
    from(table_name)
    self
  end

  # Sets the data for UPDATE.
  #
  # @param data [Hash] Key-value pairs of columns to update
  # @return [self]
  def set(data)
    @update_data = data
    self
  end

  # Prepares a DELETE operation.
  #
  # @return [self]
  def delete
    @operation_type = :delete
    self
  end

  # Executes the constructed request.
  #
  # @return [Array<Hash>] The result of the query.
  #   For SELECT: Returns rows.
  #   For INSERT/UPDATE/DELETE: Returns a status hash (e.g., { "updated_rows" => 5 }).
  # @raise [StandardError] If the operation type is unknown or request is invalid.
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
      raise StandardError, "Unknown Query"
    end
  end

  private

  # Validates if the request has minimum required components.
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

  def execute_select
    csv = MyCSV.new(@file_path)
    rows = csv.rows
    current_header = csv.header

    if @join_info
      csv_b = MyCSV.new(normalize_filename(@join_info[:table_b]))
      join_result = csv.join(csv_b, @join_info[:column_a], @join_info[:column_b])
      rows = join_result[:rows]
      current_header = join_result[:header]
    end

    if @where_conditions
      col_index = current_header.index(@where_conditions[:column])
      unless col_index
        raise ArgumentError, "Column '#{@where_conditions[:column]}' does not exist in table"
      end
      rows = rows.select { |row| row[col_index] == @where_conditions[:value] }
    end

    if @order_config
      rows = csv.sort_rows(rows, @order_config[:column], @order_config[:direction], current_header)
    end

    rows = csv.select_columns(rows, @select_columns, current_header)
    csv.rows_to_hash(rows, @select_columns, current_header)
  end

  def normalize_filename(file_name)
    file_name.end_with?(".csv") ? file_name : "#{file_name}.csv"
  end

  def execute_insert
    csv = MyCSV.new(@file_path)
    new_id = csv.insert(@insert_data)
    [{"id" => new_id, "status" => "inserted"}]
  end

  def execute_update
    csv = MyCSV.new(@file_path)
    column = @where_conditions ? @where_conditions[:column] : nil
    value = @where_conditions ? @where_conditions[:value] : nil
    updated_count = csv.update(@update_data, column, value)
    [{"updated_rows" => updated_count}]
  end

  def execute_delete
    csv = MyCSV.new(@file_path)
    column = @where_conditions ? @where_conditions[:column] : nil
    value = @where_conditions ? @where_conditions[:value] : nil
    deleted_count = csv.delete(column, value)
    [{"deleted_rows" => deleted_count}]
  end
end
