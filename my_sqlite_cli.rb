#!/usr/bin/env ruby
require "readline"
require_relative "my_sqlite_request"

# MySqliteCli - Interactive Command Line Interface for MySQLite.
#
# This class implements a REPL (Read-Eval-Print Loop) that accepts SQL-like syntax,
# parses it into MySqliteRequest objects using strict validation, and displays results.
#
# @author Saber Yassine
# @version 0.3 (Secure)
class MySqliteCli
  VERSION = "0.3 (Secure)"

  # Initializes the CLI session.
  # @param database_name [String, nil] Optional default database name
  def initialize(database_name = nil)
    @database_name = database_name
    @running = true
    @query_buffer = ""
    display_welcome
  end

  # Prints the version and welcome message.
  def display_welcome
    puts "MySQLite version #{VERSION} #{Time.now.strftime("%Y-%m-%d")}"
    puts "Enter SQL commands (end with ;). Type 'quit' to exit."
  end

  # Starts the main input loop.
  # Handles multi-line input, history, and command dispatching.
  def start
    while @running
      begin
        prompt = @query_buffer.empty? ? "my_sqlite_cli> " : "            ...> "
        input = Readline.readline(prompt, true)

        if input.nil?
          puts "\nBye!"
          @running = false
          next
        end

        if input.strip.empty?
          next if @query_buffer.empty?
        end

        # Manage history: Remove duplicates
        if Readline::HISTORY.length > 1 && Readline::HISTORY[-1] == Readline::HISTORY[-2]
          Readline::HISTORY.pop
        end

        if ["quit", "exit"].include?(input.strip.downcase)
          @running = false
          next
        end

        @query_buffer += " " unless @query_buffer.empty?
        @query_buffer += input.strip

        if @query_buffer.end_with?(";")
          complete_query = @query_buffer.chomp(";").strip
          @query_buffer = ""
          process_command(complete_query)
        end
      rescue Interrupt
        puts "\nQuery cancelled"
        @query_buffer = ""
      rescue => e
        puts "System Error: #{e.message}"
        @query_buffer = ""
      end
    end
  end

  # Dispatches the parsed command to the specific handler.
  # @param input [String] The full SQL command string
  def process_command(input)
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

  # Parses and executes a SELECT query.
  # Support: SELECT columns FROM table [JOIN] [WHERE] [ORDER BY]
  def execute_select(input)
    request = MySqliteRequest.new

    # 1. Extract Columns
    if input =~ /SELECT\s+(.+?)\s+FROM/i
      columns = $1.strip
      if columns == "*"
        request.select("*")
      else
        column_list = columns.split(",").map(&:strip)
        request.select(column_list)
      end
    else
      puts "Error: Invalid SELECT syntax. Expected: SELECT columns FROM table"
      return
    end

    # 2. Extract Table
    if input =~ /FROM\s+(\w+)/i
      table_name = $1
      request.from(table_name)
    else
      puts "Error: Missing FROM clause"
      return
    end

    # 3. Extract JOIN
    if input =~ /JOIN\s+(\w+)\s+ON\s+(\w+)\s*=\s*(\w+)/i
      request.join($2, $1, $3)
    elsif input.match?(/JOIN/i)
      puts "Error: Invalid JOIN syntax. Expected: JOIN table ON col1 = col2"
      return
    end

    # 4. Extract WHERE
    begin
      where_info = extract_where_clause(input)
      request.where(where_info[:column], where_info[:value]) if where_info
    rescue => e
      puts "Error: #{e.message}"
      return
    end

    # 5. Extract ORDER BY
    if input =~ /ORDER\s+BY\s+(\w+)\s+(ASC|DESC)/i
      request.order($2.downcase.to_sym, $1)
    end

    # Execute
    begin
      results = request.run
      display_results(results)
    rescue => e
      puts "Error executing query: #{e.message}"
    end
  end

  # ==================== INSERT PARSER ====================

  # Parses and executes an INSERT query.
  # Supports explicit columns: INSERT INTO table (a,b) VALUES (1,2)
  # Supports implicit columns: INSERT INTO table VALUES (1,2)
  # Does not allow WHERE clauses.
  def execute_insert(input)
    # Regex anchors ^...$ enforce strict matching to prevent garbage (like WHERE) at end
    if input =~ /^INSERT\s+INTO\s+(\w+)(?:\s*\(([^)]+)\))?\s+VALUES\s*\((.+)\)\s*$/i
      table_name = $1
      columns_part = $2
      values_part = $3

      values_list = parse_values_list(values_part)
      data_hash = {}

      if columns_part
        # Case A: Explicit columns provided
        columns_list = columns_part.split(",").map(&:strip)
        if columns_list.size != values_list.size
          puts "Error: Column count (#{columns_list.size}) does not match value count (#{values_list.size})."
          return
        end
        columns_list.each_with_index do |col, idx|
          data_hash[col] = values_list[idx]
        end
      else
        # Case B: Implicit columns (Read from file)
        file_path = "#{table_name}.csv"
        headers = MyCSV.header(file_path)
        if headers.empty?
          puts "Error: Table '#{table_name}' not found or is empty."
          return
        end
        # Exclude ID from data columns
        target_headers = headers.reject { |h| h.downcase == "id" }
        if target_headers.size != values_list.size
          puts "Error: Table has #{target_headers.size} data columns (excluding ID), but you provided #{values_list.size} values."
          return
        end
        target_headers.each_with_index do |col, idx|
          data_hash[col] = values_list[idx]
        end
      end

      begin
        request = MySqliteRequest.new
        request.insert(table_name).values(data_hash)
        result = request.run
        puts "Inserted 1 row (ID: #{result[0]["id"]})"
      rescue => e
        puts "Error: #{e.message}"
      end
    else
      puts "Error: Invalid INSERT syntax."
      puts "Hint: INSERT statements do not support WHERE clauses." if input.match?(/where/i)
      puts "Expected: INSERT INTO table (col1, col2) VALUES (val1, val2)"
    end
  end

  # ==================== UPDATE PARSER ====================

  # Parses and executes an UPDATE query.
  # Uses strict validation to separate SET and WHERE clauses to prevent
  # unintentional "Update All" operations caused by typos.
  def execute_update(input)
    if input =~ /^UPDATE\s+(\w+)\s+SET\s+(.+)$/i
      table_name = $1
      rest_of_string = $2

      # Robust logic to split SET and WHERE
      match = rest_of_string.match(/^(.*?)\s+WHERE\s+(.*)$/i)
      if match
        set_part = match[1]
        where_part_raw = match[2]
        has_where = true
      else
        set_part = rest_of_string
        has_where = false
      end

      # Security Check: Detect typo 'whre' inside SET clause
      if set_part.match?(/\s(whre|where|wher)\b/i) && !set_part.match?(/'.*where.*'/i)
        puts "Error: Invalid syntax. Found unexpected 'where' inside SET clause. Check for typos."
        return
      end

      begin
        data_hash = parse_set_clause(set_part)
      rescue => e
        puts "Error in SET clause: #{e.message}"
        return
      end

      request = MySqliteRequest.new
      request.update(table_name).set(data_hash)

      if has_where
        unless valid_assignment_syntax?(where_part_raw)
          puts "Error: Invalid WHERE syntax: '#{where_part_raw}'. Expected: WHERE column = value"
          return
        end

        if where_part_raw =~ /^(\w+)\s*=\s*(?:'([^']*)'|([^\s]+))$/
          col = $1
          val = $2 || $3
          request.where(col, val)
        end
      end

      begin
        result = request.run
        puts "Updated #{result[0]["updated_rows"]} row(s)"
      rescue => e
        puts "Error: #{e.message}"
      end
    else
      puts "Error: Invalid UPDATE syntax. Expected: UPDATE table SET col=val [WHERE col=val]"
    end
  end

  # ==================== DELETE PARSER ====================

  # Parses and executes a DELETE query.
  # Strictly enforces that if text follows the table name, it MUST be a valid WHERE clause.
  def execute_delete(input)
    if input =~ /^DELETE\s+FROM\s+(\w+)(?:\s+(.*))?$/i
      table_name = $1
      rest_of_string = $2

      request = MySqliteRequest.new
      request.from(table_name).delete

      if rest_of_string && !rest_of_string.strip.empty?
        begin
          # Use common extractor with spacing hack to match regex expectation
          where_info = extract_where_clause(" " + rest_of_string)
          if where_info
            request.where(where_info[:column], where_info[:value])
          else
            puts "Error: Invalid syntax after table name. Expected: WHERE column = value"
            return
          end
        rescue => e
          puts "Error: #{e.message}"
          return
        end
      end

      begin
        result = request.run
        puts "Deleted #{result[0]["deleted_rows"]} row(s)"
      rescue => e
        puts "Error: #{e.message}"
      end
    else
      puts "Error: Invalid DELETE syntax. Expected: DELETE FROM table [WHERE col=val]"
    end
  end

  private

  # Validates that a string strictly follows "column = value" syntax.
  # Used to prevent "WHERE id" (missing value) from executing.
  # @param str [String] The string to check
  def valid_assignment_syntax?(str)
    str.match?(/^\s*\w+\s*=\s*(?:'[^']*'|[^,\s]+)\s*$/)
  end

  # Extracts and validates the WHERE clause from a query string.
  # @raise [RuntimeError] If typos ('whre') or incomplete clauses are found.
  def extract_where_clause(input_str)
    if input_str.match?(/\s+(whre|were|wher)\s+/i)
      raise "Possible typo detected: Did you mean 'WHERE'?"
    end
    if input_str =~ /\s+WHERE\s+(.+)$/i
      raw_condition = $1.strip
      unless valid_assignment_syntax?(raw_condition)
        raise "Invalid WHERE syntax: '#{raw_condition}'. Expected: WHERE column = value"
      end
      if raw_condition =~ /^(\w+)\s*=\s*(?:'([^']*)'|([^\s]+))$/
        return {column: $1, value: $2 || $3}
      end
    elsif input_str.match?(/\s+WHERE\s*$/i)
      raise "Incomplete WHERE clause."
    end
    nil
  end

  # Parses the SET clause of an UPDATE statement.
  # @param set_clause [String] "col1=val1, col2='val2'"
  # @return [Hash] parsed data
  def parse_set_clause(set_clause)
    data_hash = {}
    pairs = set_clause.split(",").map(&:strip)
    pairs.each do |pair|
      if pair =~ /^(\w+)\s*=\s*(?:'([^']*)'|([^\s]+))$/
        column = $1
        value = $2 || $3
        data_hash[column] = value
      else
        raise "Invalid assignment: '#{pair}'. Expected: column='value'"
      end
    end
    data_hash
  end

  # Parses comma-separated values, respecting quoted strings.
  # @param values_str [String] "1, 'John Doe', 'A'"
  # @return [Array<String>]
  def parse_values_list(values_str)
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

  # Formats and prints results to STDOUT.
  def display_results(results)
    if results.nil? || results.empty?
      puts "(0 rows)"
      return
    end
    results.each { |row| puts row.values.join("|") }
    puts "(#{results.count} row#{"s" if results.count != 1})"
  end
end

# Entry point
if __FILE__ == $PROGRAM_NAME
  database_name = ARGV[0]&.gsub(".db", "")
  cli = MySqliteCli.new(database_name)
  cli.start
end
