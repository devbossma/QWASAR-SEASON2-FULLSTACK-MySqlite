require "csv"
# Helper class for direct CSV file manipulation.
# Handles reading, writing, filtering, and raw data storage.
class MyCSV
  attr_reader :file_path, :header, :rows

  # @param file_path [String] Path to the .csv file
  # @raise [IOError] If file does not exist
  def initialize(file_path)
    @file_path = file_path
    unless File.exist?(@file_path)
      raise IOError, "Table '#{@file_path.gsub(".csv", "")}' does not exist"
    end
    load_data
  end

  # Loads CSV content into memory.
  def load_data
    return unless File.exist?(@file_path)
    table = CSV.read(@file_path)
    @header = table[0] || []
    @rows = table[1..] || []
  end

  # Filters columns from the dataset.
  #
  # @param rows [Array<Array>] The dataset rows
  # @param columns [String, Array<String>] Columns to keep
  # @param custom_header [Array<String>] Optional header if different from instance header
  # @return [Array<Array>] Rows containing only selected columns
  def select_columns(rows, columns, custom_header = nil)
    return rows if columns == "*" || columns.nil?
    working_header = custom_header || @header
    column_list = columns.is_a?(Array) ? columns : [columns]

    column_list.each do |col|
      unless working_header.include?(col)
        raise ArgumentError, "Column '#{col}' does not exist in table"
      end
    end

    indices = column_list.map { |col| working_header.index(col) }
    rows.map { |row| indices.map { |idx| row[idx] } }
  end

  # Sorts rows based on a column value.
  # Handles mixed types (Integer vs String) intelligently.
  #
  # @param rows [Array<Array>] Dataset to sort
  # @param column_name [String] Column to sort by
  # @param direction [Symbol] :asc or :desc
  # @param custom_header [Array<String>] Optional header
  # @return [Array<Array>] Sorted rows
  def sort_rows(rows, column_name, direction = :asc, custom_header = nil)
    working_header = custom_header || @header
    unless working_header.include?(column_name)
      raise ArgumentError, "Column '#{column_name}' does not exist in table"
    end

    col_index = working_header.index(column_name)
    sorted = rows.sort_by do |row|
      value = row[col_index]
      # Custom sorting: Empty strings last, numbers numerically, strings alphabetically
      if value.nil? || value.to_s.strip.empty?
        [1, ""]
      elsif value.to_i.to_s == value
        [0, value.to_i]
      else
        [0, value]
      end
    end
    (direction == :desc) ? sorted.reverse : sorted
  end

  # Performs an INNER JOIN between this CSV and another.
  # Handles duplicate column names by appending '_b'.
  #
  # @param other_csv [MyCSV] The other CSV instance
  # @param col_a [String] Join column in this table
  # @param col_b [String] Join column in other table
  # @return [Hash] { rows: Array, header: Array }
  def join(other_csv, col_a, col_b)
    unless column_exists?(col_a)
      raise ArgumentError, "Column '#{col_a}' does not exist in first table"
    end
    unless other_csv.column_exists?(col_b)
      raise ArgumentError, "Column '#{col_b}' does not exist in second table"
    end

    col_a_index = @header.index(col_a)
    col_b_index = other_csv.header.index(col_b)
    merged_header = build_merged_header(other_csv.header)
    result_rows = []

    @rows.each do |row_a|
      other_csv.rows.each do |row_b|
        if row_a[col_a_index] == row_b[col_b_index]
          result_rows << merge_rows(row_a, row_b, other_csv.header, merged_header)
        end
      end
    end
    {rows: result_rows, header: merged_header}
  end

  # Inserts a new row into the CSV.
  #
  # @param data_hash [Hash] Column => Value map
  # @return [Integer] The new generated ID
  # @raise [ArgumentError] If unknown columns are provided
  def insert(data_hash)
    # VALIDATION: Check if all provided columns exist in the table
    data_hash.keys.each do |key|
      unless @header.include?(key.to_s)
        raise ArgumentError, "Column '#{key}' does not exist in table"
      end
    end

    new_id = generate_next_id
    new_row = @header.map do |col|
      if col == "id"
        new_id.to_s
      else
        data_hash[col] || data_hash[col.to_sym] || ""
      end
    end

    @rows << new_row
    save_to_file
    new_id
  end

  # Updates rows matching criteria.
  #
  # @param data_hash [Hash] Data to update
  # @param column_name [String, nil] Where column
  # @param value [String, nil] Where value
  # @return [Integer] Count of updated rows
  def update(data_hash, column_name = nil, value = nil)
    data_hash.each do |key, _|
      unless column_exists?(key.to_s)
        raise ArgumentError, "Column '#{key}' does not exist in table"
      end
    end

    if column_name && !column_exists?(column_name)
      raise ArgumentError, "Column '#{column_name}' does not exist in table"
    end

    updated_count = 0
    col_idx_filter = column_name ? @header.index(column_name) : nil

    @rows.each do |row|
      should_update = column_name.nil? || row[col_idx_filter] == value

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

  # Deletes rows matching criteria.
  #
  # @param column_name [String, nil] Where column
  # @param value [String, nil] Where value
  # @return [Integer] Count of deleted rows
  def delete(column_name = nil, value = nil)
    if column_name && !column_exists?(column_name)
      raise ArgumentError, "Column '#{column_name}' does not exist in table"
    end

    original_count = @rows.length
    if column_name.nil?
      @rows = []
    else
      col_index = @header.index(column_name)
      @rows.reject! { |row| row[col_index] == value }
    end

    deleted_count = original_count - @rows.length
    save_to_file if deleted_count > 0
    deleted_count
  end

  def column_exists?(column_name)
    @header.include?(column_name.to_s)
  end

  # Writes the current state of @rows back to the CSV file.
  def save_to_file
    CSV.open(@file_path, "w") do |csv|
      csv << @header
      @rows.each { |row| csv << row }
    end
  end

  # Converts array of rows to array of hashes (Result format).
  def rows_to_hash(rows, columns = "*", custom_header = nil)
    return [] if rows.empty?
    working_header = custom_header || @header

    if columns == "*"
      rows.map do |row|
        hash = {}
        row.each_with_index do |value, idx|
          hash[working_header[idx]] = value if idx < working_header.length
        end
        hash
      end
    else
      column_list = columns.is_a?(Array) ? columns : [columns]
      rows.map do |row|
        hash = {}
        row.each_with_index do |value, idx|
          hash[column_list[idx]] = value if idx < column_list.length
        end
        hash
      end
    end
  end

  # Static method: Reads just the header line of a file.
  # @return [Array<String>] Header columns
  def self.header(file_path)
    return [] unless File.exist?(file_path)
    CSV.open(file_path, &:readline)
  rescue
    []
  end

  private

  # Auto-increments ID based on max existing ID.
  def generate_next_id
    return 1 if @rows.empty?
    ids = @rows.map { |row| row[0].to_i }
    ids.max + 1
  end

  def build_merged_header(header_b)
    merged = @header.dup
    header_b.each do |col|
      merged << (@header.include?(col) ? "#{col}_b" : col)
    end
    merged
  end

  def merge_rows(row_a, row_b, header_b, merged_header)
    row_a + row_b
  end
end
