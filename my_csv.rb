require "csv"

class MyCSV
  attr_reader :file_path, :header, :rows

  def initialize(file_path)
    @file_path = file_path

    unless File.exist?(@file_path)
      raise IOError, "Table '#{@file_path.gsub(".csv", "")}' does not exist"
    end
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
      raise ArgumentError, "Column '#{column_name}' does not exist in table"
    end

    col_index = @header.index(column_name)
    @rows.select { |row| row[col_index] == value }
  end

  # Select specific columns from rows
  # Supports custom header for joined tables
  def select_columns(rows, columns, custom_header = nil)
    return rows if columns == "*" || columns.nil?

    # Use custom header if provided (for joined tables), otherwise use instance header
    working_header = custom_header || @header

    # Handle both string and array input
    column_list = columns.is_a?(Array) ? columns : [columns]

    # Validate all columns exist
    column_list.each do |col|
      unless working_header.include?(col)
        raise ArgumentError, "Column '#{col}' does not exist in table"
      end
    end

    # Get indices of requested columns
    indices = column_list.map { |col| working_header.index(col) }

    # Return rows with only selected columns
    rows.map do |row|
      indices.map { |idx| row[idx] }
    end
  end

  # Sort rows by column
  # Supports custom header for joined tables
  def sort_rows(rows, column_name, direction = :asc, custom_header = nil)
    # Use custom header if provided (for joined tables), otherwise use instance header
    working_header = custom_header || @header

    unless working_header.include?(column_name)
      raise ArgumentError, "Column '#{column_name}' does not exist in table"
    end

    col_index = working_header.index(column_name)
    sorted = rows.sort_by do |row|
      value = row[col_index]

      # Handle nil and empty values - treat them as lowest priority
      if value.nil? || value.to_s.strip.empty?
        # Return a tuple: [1, ""] means "sort these last, then by empty string"
        [1, ""]
      elsif value.to_i.to_s == value
        # Try to convert to number for proper numeric sorting
        # It's a number - return tuple [0, number] to sort numbers before nils
        [0, value.to_i]
      else
        # It's a string - return tuple [0, string] to sort strings before nils
        [0, value]
      end
    end

    (direction == :desc) ? sorted.reverse : sorted
  end

  # Join with another CSV file
  # Returns: { rows: merged_rows, header: merged_header }
  def join(other_csv, col_a, col_b)
    unless column_exists?(col_a)
      raise ArgumentError, "Column '#{col_a}' does not exist in first table"
    end
    unless other_csv.column_exists?(col_b)
      raise ArgumentError, "Column '#{col_b}' does not exist in second table"
    end

    col_a_index = @header.index(col_a)
    col_b_index = other_csv.header.index(col_b)

    # Build merged header with duplicate handling
    merged_header = build_merged_header(other_csv.header)

    result_rows = []

    @rows.each do |row_a|
      other_csv.rows.each do |row_b|
        if row_a[col_a_index] == row_b[col_b_index]
          # Merge rows with all columns from both tables
          merged = merge_rows(row_a, row_b, other_csv.header, merged_header)
          result_rows << merged
        end
      end
    end

    # Return both rows and header for proper handling
    {rows: result_rows, header: merged_header}
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
  # Supports custom header for joined tables
  def rows_to_hash(rows, columns = "*", custom_header = nil)
    return [] if rows.empty?

    # Use custom header if provided (for joined tables), otherwise use instance header
    working_header = custom_header || @header

    if columns == "*"
      # Return all columns
      rows.map do |row|
        hash = {}
        row.each_with_index do |value, idx|
          hash[working_header[idx]] = value if idx < working_header.length
        end
        hash
      end
    else
      # Return only selected columns
      column_list = columns.is_a?(Array) ? columns : [columns]

      rows.map do |row|
        hash = {}
        row.each_with_index do |value, idx|
          # row is ALREADY filtered to only have selected columns
          # so map row[0] to column_list[0], row[1] to column_list[1], etc.
          hash[column_list[idx]] = value if idx < column_list.length
        end
        hash
      end
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

  # Build merged header, handling duplicate column names
  def build_merged_header(header_b)
    merged = @header.dup

    header_b.each do |col|
      merged << if @header.include?(col)
        # Duplicate column - add with _b suffix
        "#{col}_b"
      else
        col
      end
    end

    merged
  end

  # Merge two rows, handling duplicate column names
  def merge_rows(row_a, row_b, header_b, merged_header)
    merged = row_a.dup

    # Add all columns from row_b
    row_b.each do |value|
      merged << value
    end

    merged
  end
end
