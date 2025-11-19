#!/usr/bin/env ruby

require "readline"
require_relative "my_sqlite_request"

class MySqliteCli
  VERSION = "0.1"

  def initialize(database_name = nil)
    @database_name = database_name
    @running = true
    @query_buffer = ""  # Store incomplete queries
    display_welcome
  end

  def display_welcome
    puts "MySQLite version #{VERSION} #{Time.now.strftime("%Y-%m-%d")}"
  end

  def start
    while @running
      begin
        # Change prompt based on whether we're continuing a query
        prompt = @query_buffer.empty? ? "my_sqlite_cli> " : "            ...> "

        input = Readline.readline(prompt, true)

        # Handle Ctrl+D (EOF)
        if input.nil?
          puts "\nBye!"
          @running = false
          next
        end

        # Skip empty lines
        if input.strip.empty?
          # If we have a buffer, keep it; otherwise skip
          next if @query_buffer.empty?
        end

        # Remove from history if it's the same as previous
        if Readline::HISTORY.length > 1 &&
            Readline::HISTORY[-1] == Readline::HISTORY[-2]
          Readline::HISTORY.pop
        end

        # Check for quit command (can be entered anytime)
        if input.strip.downcase == "quit" || input.strip.downcase == "exit"
          @running = false
          next
        end

        # Add input to buffer
        @query_buffer += " " unless @query_buffer.empty?
        @query_buffer += input.strip

        # Check if query is complete (ends with semicolon)
        if @query_buffer.end_with?(";")
          # Remove semicolon and process
          complete_query = @query_buffer.chomp(";").strip
          @query_buffer = ""  # Clear buffer

          process_command(complete_query)
        end
        # If no semicolon, loop continues and prompts for more input
      rescue Interrupt
        puts "\nQuery cancelled"
        @query_buffer = ""  # Clear buffer on Ctrl+C
      rescue => e
        puts "Error: #{e.message}"
        puts e.backtrace.first(3) if ENV["DEBUG"]
        @query_buffer = ""  # Clear buffer on error
      end
    end
  end

  def process_command(input)
    # Input has already been stripped and semicolon removed

    # Determine command type
    command_type = input.split.first&.upcase

    case command_type
    when "SELECT"
      execute_select(input)
    when "INSERT"
      execute_insert(input)
    when "UPDATE"
      execute_update(input)
    when "DELETE"
      execute_delete(input)
    else
      puts "Unknown command: #{command_type}"
      puts "Supported: SELECT, INSERT, UPDATE, DELETE, quit"
    end
  end

  # ==================== SELECT PARSER ====================
  def execute_select(input)
    # Parse: SELECT columns FROM table [WHERE col = val] [JOIN table2 ON col1 = col2] [ORDER BY col ASC/DESC]

    request = MySqliteRequest.new

    # Extract columns (between SELECT and FROM)
    if input =~ /SELECT\s+(.+?)\s+FROM/i
      columns = $1.strip
      if columns == "*"
        request.select("*")
      else
        # Split by comma and trim
        column_list = columns.split(",").map(&:strip)
        request.select(column_list)
      end
    else
      puts "Error: Invalid SELECT syntax. Expected: SELECT columns FROM table"
      return
    end

    # Extract table name (between FROM and WHERE/JOIN/ORDER/end)
    if input =~ /FROM\s+(\w+)/i
      table_name = $1
      request.from(table_name)
    else
      puts "Error: Missing FROM clause"
      return
    end

    # Extract WHERE clause
    if input =~ /WHERE\s+(\w+)\s*=\s*'?([^',;]+)'?/i
      column = $1
      value = $2.strip
      request.where(column, value)
    end

    # Extract JOIN clause
    if input =~ /JOIN\s+(\w+)\s+ON\s+(\w+)\s*=\s*(\w+)/i
      table_b = $1
      col_a = $2
      col_b = $3
      request.join(col_a, table_b, col_b)
    end

    # Extract ORDER BY clause
    if input =~ /ORDER\s+BY\s+(\w+)\s+(ASC|DESC)/i
      column = $1
      direction = $2.downcase.to_sym
      request.order(direction, column)
    end

    # Execute and display results
    begin
      results = request.run
      display_results(results)
    rescue => e
      puts "Error executing query: #{e.message}"
    end
  end

  # ==================== INSERT PARSER ====================
  def execute_insert(input)
    # Parse: INSERT INTO table VALUES (val1, val2, val3, ...)

    if input =~ /INSERT\s+INTO\s+(\w+)\s+VALUES\s*\((.+)\)/i
      table_name = $1
      values_str = $2

      # Split values by comma (handle quoted strings)
      values = parse_values(values_str)

      # Read table headers to map values
      begin
        csv = MyCSV.new("#{table_name}.csv")
        headers = csv.header

        # Skip 'id' column as it's auto-generated
        data_headers = headers.reject { |h| h.downcase == "id" }

        # Map values to headers
        data_hash = {}
        data_headers.each_with_index do |header, idx|
          data_hash[header] = values[idx] if values[idx]
        end

        # Execute insert
        request = MySqliteRequest.new
        request.insert(table_name).values(data_hash)
        result = request.run

        puts "Inserted 1 row (ID: #{result[0]["id"]})"
      rescue => e
        puts "Error: #{e.message}"
      end
    else
      puts "Error: Invalid INSERT syntax. Expected: INSERT INTO table VALUES (val1, val2, ...)"
    end
  end

  # ==================== UPDATE PARSER ====================
  def execute_update(input)
    # Parse: UPDATE table SET col1 = val1, col2 = val2 [WHERE col = val]

    if input =~ /UPDATE\s+(\w+)\s+SET\s+(.+?)(?:\s+WHERE\s+(.+))?$/i
      table_name = $1
      set_clause = $2.strip
      where_clause = $3

      # Parse SET clause
      data_hash = parse_set_clause(set_clause)

      # Build request
      request = MySqliteRequest.new
      request.update(table_name).set(data_hash)

      # Parse WHERE clause if present
      if where_clause && where_clause =~ /(\w+)\s*=\s*'?([^',;]+)'?/
        column = $1
        value = $2.strip
        request.where(column, value)
      end

      # Execute
      begin
        result = request.run
        puts "Updated #{result[0]["updated_rows"]} row(s)"
      rescue => e
        puts "Error: #{e.message}"
      end
    else
      puts "Error: Invalid UPDATE syntax. Expected: UPDATE table SET col=val WHERE col=val"
    end
  end

  # ==================== DELETE PARSER ====================
  def execute_delete(input)
    # Parse: DELETE FROM table [WHERE col = val]

    if input =~ /DELETE\s+FROM\s+(\w+)(?:\s+WHERE\s+(.+))?$/i
      table_name = $1
      where_clause = $2

      # Build request
      request = MySqliteRequest.new
      request.from(table_name).delete

      # Parse WHERE clause if present
      if where_clause && where_clause =~ /(\w+)\s*=\s*'?([^',;]+)'?/
        column = $1
        value = $2.strip
        request.where(column, value)
      end

      # Execute
      begin
        result = request.run
        puts "Deleted #{result[0]["deleted_rows"]} row(s)"
      rescue => e
        puts "Error: #{e.message}"
      end
    else
      puts "Error: Invalid DELETE syntax. Expected: DELETE FROM table WHERE col=val"
    end
  end

  # ==================== HELPER METHODS ====================

  def parse_values(values_str)
    # Parse comma-separated values, handling quoted strings
    values = []
    current = ""
    in_quotes = false

    values_str.each_char do |char|
      case char
      when "'"
        in_quotes = !in_quotes
      when ","
        if in_quotes
          current += char
        else
          values << current.strip
          current = ""
        end
      else
        current += char
      end
    end

    values << current.strip unless current.empty?
    values
  end

  def parse_set_clause(set_clause)
    # Parse: col1 = val1, col2 = val2, ...
    data_hash = {}

    # Split by comma (not inside quotes)
    pairs = set_clause.split(",").map(&:strip)

    pairs.each do |pair|
      if pair =~ /(\w+)\s*=\s*'?([^']+)'?/
        column = $1.strip
        value = $2.strip
        data_hash[column] = value
      end
    end

    data_hash
  end

  def display_results(results)
    if results.nil? || results.empty?
      puts "(0 rows)"
      return
    end

    # Display each row as pipe-separated values
    results.each do |row|
      puts row.values.join("|")
    end

    puts "(#{results.count} row#{"s" if results.count != 1})"
  end
end

# ==================== MAIN ENTRY POINT ====================

if __FILE__ == $PROGRAM_NAME
  database_name = ARGV[0]

  if database_name
    # Strip .db extension if provided
    database_name = database_name.gsub(".db", "")
  end

  cli = MySqliteCli.new(database_name)
  cli.start
end
