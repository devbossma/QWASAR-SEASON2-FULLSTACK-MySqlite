require "csv" # Assuming MyCSV class is in my_csv.rb

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
      p execute_select
    when :insert
      p execute_insert
    when :update
      p execute_update
    when :delete
      p execute_delete
    else
      nil
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

    # Apply WHERE filter
    if @where_conditions
      rows = csv.filter(@where_conditions[:column], @where_conditions[:value])
    end

    # Apply JOIN
    if @join_info
      csv_b = MyCSV.new(normalize_filename(@join_info[:table_b]))
      rows = perform_join(csv, csv_b, rows)
      # After join, we need to update the header context
      csv = build_joined_csv(csv, csv_b)
    end

    # Apply ORDER
    if @order_config
      rows = csv.sort_rows(rows, @order_config[:column], @order_config[:direction])
    end

    # Apply SELECT columns
    rows = csv.select_columns(rows, @select_columns)

    # Convert to hash format for output
    csv.rows_to_hash(rows, @select_columns)
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

  # Perform join operation between two CSVs
  def perform_join(csv_a, csv_b, rows_a)
    col_a_index = csv_a.header.index(@join_info[:column_a])
    col_b_index = csv_b.header.index(@join_info[:column_b])

    return [] if col_a_index.nil? || col_b_index.nil?

    result = []

    rows_a.each do |row_a|
      csv_b.rows.each do |row_b|
        if row_a[col_a_index] == row_b[col_b_index]
          # Merge rows
          merged = row_a.dup

          # Add columns from table B that don't exist in table A
          csv_b.header.each_with_index do |col, idx|
            unless csv_a.header.include?(col)
              merged << row_b[idx]
            end
          end

          result << merged
        end
      end
    end

    result
  end

  # Build a virtual CSV object that represents the joined result
  def build_joined_csv(csv_a, csv_b)
    # Create a new CSV-like object with combined headers
    joined_header = csv_a.header.dup

    csv_b.header.each do |col|
      joined_header << col unless csv_a.header.include?(col)
    end

    # Return a mock CSV object with the joined header
    OpenStruct.new(
      header: joined_header,
      select_columns: csv_a.method(:select_columns),
      sort_rows: csv_a.method(:sort_rows),
      rows_to_hash: ->(rows, cols) {
        rows.map do |row|
          hash = {}
          row.each_with_index do |value, idx|
            hash[joined_header[idx]] = value if idx < joined_header.length
          end
          hash
        end
      }
    )
  end

  # Normalize filename to include .csv extension
  def normalize_filename(filename)
    filename.end_with?(".csv") ? filename : "#{filename}.csv"
  end
end

# Example usage:
# request = MySqliteRequest.new
# request.from('nba_player_data.csv')
#        .select('name')
#        .where('birth_state', 'Indiana')
#        .run
#
# Or chained:
# MySqliteRequest.new.from('nba_player_data').select('name').where('birth_state', 'Indiana').run
class MyCSV
  attr_reader :file_path, :header, :rows

  def initialize(file_path)
    @file_path = file_path
    load_data
  end

  # Load CSV data into memory
  def load_data
    return unless File.exist?(@file_path)

    table = CSV.read(@file_path)
    @header = table[0] || []
    @rows = table[1..] || []
  end

  # Convert rows to array of hashes for easier manipulation
  def to_hashes
    @rows.map do |row|
      hash = {}
      @header.each_with_index do |col, idx|
        hash[col] = row[idx]
      end
      hash
    end
  end

  # Filter rows based on WHERE condition
  def filter(column_name, value)
    unless column_exists?(column_name)
      raise "Column '#{column_name}' does not exist in table"
    end

    col_index = @header.index(column_name)
    @rows.select { |row| row[col_index] == value }
  end

  # Select specific columns from rows
  def select_columns(rows, columns)
    return rows if columns == "*" || columns.nil?

    # Handle both string and array input
    column_list = columns.is_a?(Array) ? columns : [columns]

    # Validate all columns exist
    column_list.each do |col|
      unless column_exists?(col)
        raise ArgumentError, "Column '#{col}' does not exist in table"
      end
    end

    # Get indices of requested columns
    indices = column_list.map { |col| @header.index(col) }

    # Return rows with only selected columns
    rows.map do |row|
      indices.map { |idx| row[idx] }
    end
  end

  # Sort rows by column
  def sort_rows(rows, column_name, direction = :asc)
    unless column_exists?(column_name)
      raise ArgumentError, "Column '#{column_name}' does not exist in table"
    end

    col_index = @header.index(column_name)
    sorted = rows.sort_by do |row|
      value = row[col_index]
      # Try to convert to number for proper numeric sorting
      (value.to_i.to_s == value) ? value.to_i : value
    end

    (direction == :desc) ? sorted.reverse : sorted
  end

  # Join with another CSV file
  def join(other_csv, col_a, col_b)
    unless column_exists?(col_a)
      raise ArgumentError, "Column '#{col_a}' does not exist in first table"
    end
    unless other_csv.column_exists?(col_b)
      raise ArgumentError, "Column '#{col_b}' does not exist in second table"
    end

    col_a_index = @header.index(col_a)
    col_b_index = other_csv.header.index(col_b)

    result = []

    @rows.each do |row_a|
      other_csv.rows.each do |row_b|
        if row_a[col_a_index] == row_b[col_b_index]
          # Merge rows, prepending table name to duplicate columns
          merged = merge_rows(row_a, row_b, other_csv.header)
          result << merged
        end
      end
    end

    result
  end

  # Insert a new row
  def insert(data_hash)
    # Generate new ID (assuming first column is 'id')
    new_id = generate_next_id

    # Build row in correct column order
    new_row = @header.map do |col|
      (col == "id") ? new_id.to_s : (data_hash[col] || data_hash[col.to_sym] || "")
    end

    @rows << new_row
    save_to_file

    new_id
  end

  # Update rows that match condition
  def update(data_hash, column_name = nil, value = nil)
    unless File.exist?(@file_path)
      raise IOError, "Table file '#{@file_path}' does not exist"
    end

    # Validate all columns in data_hash exist
    data_hash.each do |key, _|
      col_key = key.to_s
      unless column_exists?(col_key)
        raise ArgumentError, "Column '#{col_key}' does not exist in table"
      end
    end

    # Validate WHERE column if specified
    if column_name && !column_exists?(column_name)
      raise ArgumentError, "Column '#{column_name}' does not exist in table"
    end

    updated_count = 0

    @rows.each do |row|
      # If no condition, update all rows
      should_update = column_name.nil? || row[@header.index(column_name)] == value

      if should_update
        data_hash.each do |key, new_value|
          col_key = key.to_s
          row[@header.index(col_key)] = new_value
        end
        updated_count += 1
      end
    end

    save_to_file if updated_count > 0
    updated_count
  end

  # Delete rows that match condition
  def delete(column_name = nil, value = nil)
    unless File.exist?(@file_path)
      raise IOError, "Table file '#{@file_path}' does not exist"
    end

    # Validate WHERE column if specified
    if column_name && !column_exists?(column_name)
      raise ArgumentError, "Column '#{column_name}' does not exist in table"
    end

    original_count = @rows.length

    if column_name.nil?
      # Delete all rows
      @rows = []
    else
      # Delete matching rows
      col_index = @header.index(column_name)
      @rows.reject! { |row| row[col_index] == value }
    end

    deleted_count = original_count - @rows.length
    save_to_file if deleted_count > 0

    deleted_count
  end

  # Check if column exists
  def column_exists?(column_name)
    @header.include?(column_name.to_s)
  end

  # Save current state back to CSV file
  def save_to_file
    CSV.open(@file_path, "w") do |csv|
      csv << @header
      @rows.each { |row| csv << row }
    end
  end

  # Convert rows to formatted output (pipe-separated)
  def format_rows(rows, columns = "*")
    return [] if rows.empty?

    if columns == "*"
      rows.map { |row| row.join("|") }
    else
      # Already filtered columns, just join
      rows.map { |row| row.is_a?(Array) ? row.join("|") : row }
    end
  end

  # Convert rows to array of hashes with selected columns
  def rows_to_hash(rows, columns = "*")
    return [] if rows.empty?

    if columns == "*"
      header_list = @header
    else
      column_list = columns.is_a?(Array) ? columns : [columns]
      header_list = column_list
    end

    rows.map do |row|
      hash = {}
      row.each_with_index do |value, idx|
        hash[header_list[idx]] = value if idx < header_list.length
      end
      hash
    end
  end

  # Class method: Quick read without instantiating
  def self.read(file_path)
    new(file_path)
  end

  # Class method: Get header only
  def self.header(file_path)
    return [] unless File.exist?(file_path)
    CSV.read(file_path)[0] || []
  end

  # Class method: Check if file exists
  def self.exists?(file_path)
    File.exist?(file_path)
  end

  private

  # Generate next available ID
  def generate_next_id
    return 1 if @rows.empty?

    # Assuming first column is ID
    ids = @rows.map { |row| row[0].to_i }
    ids.max + 1
  end

  # Merge two rows, handling duplicate column names
  def merge_rows(row_a, row_b, header_b)
    merged = row_a.dup

    header_b.each_with_index do |col, idx|
      # Skip if column already exists in table A
      unless @header.include?(col)
        merged << row_b[idx]
      end
    end

    merged
  end
end
