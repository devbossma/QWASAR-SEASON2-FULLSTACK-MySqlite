# MySQLite Project TODO List

## 🎯 Project Overview

Building a SQLite-like query system with CSV file storage and a command-line interface.

---

## 📋 Phase 1: Project Setup

- [x] Create project directory structure
- [x] Create `my_sqlite_request` file (with appropriate extension for your language)
- [x] Create `my_sqlite_cli` file (with appropriate extension)
- [x] Download test CSV files (nba_player_data.csv, etc.)
- [x] Set up basic file reading capability (CSV parser/library)
- [x] Create test CSV with simple data for initial testing

---

## 🏗️ Phase 2: MySqliteRequest Class - Basic Structure

### Class Foundation

- [x] Create MySqliteRequest class
- [x] Implement `initialize/constructor` method
- [x] Set up instance variables for storing query state:
  - [x] `@from_table` (or equivalent)
  - [x] `@select_columns`
  - [x] `@where_conditions`
  - [x] `@join_info`
  - [x] `@order_config`
  - [x] `@operation_type` (SELECT, INSERT, UPDATE, DELETE)
  - [x] `@insert_data`
  - [x] `@update_data`

---

## 🔍 Phase 3: SELECT Operations

### Basic SELECT

- [x] Implement `from(table_name)` method
  - [x] Store table name
  - [x] Return `self` for chaining
- [x] Implement `select(column_name)` method
  - [x] Handle single column (string)
  - [x] Handle multiple columns (array)
  - [x] Handle `*` for all columns
  - [x] Return `self` for chaining
- [x] Implement basic `run()` method
  - [x] Read CSV file
  - [x] Parse into array of hashes
  - [x] Return selected columns only
- [x] **TEST:** `MySqliteRequest.new.from('data.csv').select('name').run`

### Add WHERE Filtering

- [x] Implement `where(column_name, value)` method
  - [x] Store filter condition
  - [x] Return `self` for chaining
- [x] Update `run()` to filter results
  - [x] Apply WHERE condition before returning
  - [x] Handle case when column doesn't exist
- [x] **TEST:** `...select('name').where('state', 'Indiana').run`

### Add ORDER Sorting

- [x] Implement `order(direction, column_name)` method
  - [x] Handle `:asc` direction
  - [x] Handle `:desc` direction
  - [x] Return `self` for chaining
- [x] Update `run()` to sort results
  - [x] Sort after filtering, before returning
  - [x] Handle numeric vs string sorting
- [x] **TEST:** `...where('state', 'Indiana').order(:asc, 'name').run`

### Add JOIN

- [x] Implement `join(column_on_db_a, filename_db_b, column_on_db_b)` method
  - [x] Load second CSV file
  - [x] Store join configuration
  - [x] Return `self` for chaining
- [x] Update `run()` to perform join
  - [x] Match rows where join columns are equal
  - [x] Merge column data from both tables
  - [x] Handle duplicate column names
- [x] **TEST:** `...from('players.csv').join('team_id', 'teams.csv', 'id').run`

---

## ✏️ Phase 4: Write Operations

### INSERT

- [x] Implement `insert(table_name)` method
  - [x] Set operation type to INSERT
  - [x] Store table name
  - [x] Return `self` for chaining
- [x] Implement `values(data)` method
  - [x] Accept hash/object of column => value pairs
  - [x] Store insert data
  - [x] Return `self` for chaining
- [x] Update `run()` for INSERT
  - [x] Generate new ID for row
  - [x] Append row to CSV file
  - [x] Return success confirmation
- [x] **TEST:** `MySqliteRequest.new.insert('students').values({name: 'John', email: 'john@test.com'}).run`

### UPDATE

- [x] Implement `update(table_name)` method
  - [x] Set operation type to UPDATE
  - [x] Store table name
  - [x] Return `self` for chaining
- [x] Implement `set(data)` method
  - [x] Accept hash/object of column => value pairs
  - [x] Store update data
  - [x] Return `self` for chaining
- [x] Update `run()` for UPDATE
  - [x] Read all rows
  - [x] Apply WHERE filter to find matching rows
  - [x] Update matching rows with new values
  - [x] Write back to CSV
  - [x] Return count of updated rows
- [x] **TEST:** `MySqliteRequest.new.update('students').set({email: 'new@test.com'}).where('name', 'John').run`

### DELETE

- [x] Implement `delete()` method
  - [x] Set operation type to DELETE
  - [x] Return `self` for chaining
- [x] Update `run()` for DELETE
  - [x] Read all rows
  - [x] Apply WHERE filter to find matching rows
  - [x] Remove matching rows
  - [x] Write remaining rows back to CSV
  - [x] Return count of deleted rows
- [x] **TEST:** `MySqliteRequest.new.from('students').delete.where('name', 'John').run`

---

## 💻 Phase 5: Command Line Interface (CLI)

### REPL Setup

- [x] Set up readline/input loop
- [x] Display welcome message with version
- [x] Display prompt: `my_sqlite_cli> `
- [x] Read user input
- [x] Handle `quit` command to exit
- [x] Loop until quit

### SQL Parser Foundation

- [x] Create function to identify command type (SELECT/INSERT/UPDATE/DELETE)
- [x] Test with simple commands

### SELECT Parser

- [x] Parse `SELECT columns FROM table`
- [x] Extract column names (handle `*`, single, multiple)
- [x] Extract table name
- [x] Parse `WHERE column = value` clause
- [x] Parse `JOIN table2 ON col1 = col2` clause
- [x] Build MySqliteRequest chain from parsed data
- [x] Execute and display results
- [x] **TEST:** `SELECT * FROM students;`
- [x] **TEST:** `SELECT name FROM students WHERE state = 'Indiana';`

### INSERT Parser

- [x] Parse `INSERT INTO table VALUES (val1, val2, val3)`
- [x] Extract table name
- [x] Extract values from parentheses
- [x] Map values to columns (read CSV headers)
- [x] Build MySqliteRequest chain
- [x] Execute and display success message
- [x] **TEST:** `INSERT INTO students VALUES (John, john@test.com, A, https://blog.com);`

### UPDATE Parser

- [x] Parse `UPDATE table SET col1 = val1, col2 = val2 WHERE col = value`
- [x] Extract table name
- [x] Parse SET clause into hash/object
- [x] Parse WHERE clause
- [x] Build MySqliteRequest chain
- [x] Execute and display rows affected
- [x] **TEST:** `UPDATE students SET email = 'new@test.com' WHERE name = 'John';`

### DELETE Parser

- [x] Parse `DELETE FROM table WHERE col = value`
- [x] Extract table name
- [x] Parse WHERE clause
- [x] Build MySqliteRequest chain
- [x] Execute and display rows affected
- [x] **TEST:** `DELETE FROM students WHERE name = 'John';`

### Output Formatting

- [x] Format SELECT results (pipe-separated values)
- [x] Format INSERT/UPDATE/DELETE confirmations
- [x] Handle empty results gracefully
- [x] Handle errors with clear messages

---

## 🐛 Phase 6: Testing & Edge Cases

### Core Functionality Tests

- [x] Test with empty CSV file
- [x] Test with non-existent table/file
- [x] Test with non-existent column in WHERE
- [x] Test with non-existent column in SELECT
- [x] Test SELECT with no WHERE
- [x] Test UPDATE with no WHERE (updates all rows)
- [x] Test DELETE with no WHERE (deletes all rows)
- [x] Test JOIN with no matches

### CLI Tests

- [x] Test invalid SQL syntax
- [x] Test malformed commands
- [x] Test missing semicolons
- [x] Test case sensitivity
- [x] Test extra whitespace
- [x] Test empty input
- [x] Test very long queries

### Data Integrity Tests

- [x] Verify IDs are unique after INSERT
- [x] Verify CSV format is maintained after write operations
- [x] Verify data types are preserved (numbers, strings)
- [x] Test with special characters in data
- [x] Test with quotes in string values

---

## 🎨 Phase 7: Polish & Documentation

### Code Quality

- [x] Add comments to complex logic
- [x] Refactor duplicate code
- [x] Ensure consistent naming conventions
- [x] Handle errors gracefully (try-catch blocks)
- [x] Add input validation

### Documentation

- [x] Write README with usage examples
- [x] Document all public methods
- [x] Add examples for each operation type
- [x] Document limitations (max 1 WHERE, max 1 JOIN)
- [x] Add notes about CSV format requirements

### Optional Enhancements

- [x] Add support for multiple WHERE conditions
- [x] Add ORDER BY to CLI
- [x] Add support for aggregate functions (COUNT, SUM, AVG)
- [x] Add basic index structure for faster lookups
- [x] Add transaction support (rollback on error)

---

## 📚 Learning & Research

### Concepts to Study

- [x] Read about B-Tree data structure
  - [x] Understand how it differs from Binary Tree
  - [x] Learn why databases use B-Trees
- [x] Read about TRIE (Prefix Tree)
  - [x] Understand use cases for string searching
  - [x] Consider applications in query optimization
- [x] Read about Reverse Index
  - [x] Understand value → row ID mapping
  - [x] Consider how to implement for your project

### Optional Deep Dives

- [x] Study how real SQLite stores data
- [x] Learn about query optimization
- [x] Research database indexing strategies
- [x] Explore ACID properties in databases

---

## ✅ Definition of Done

### Minimum Requirements

- [x] All methods in MySqliteRequest class work correctly
- [x] Method chaining works properly (returns self)
- [x] CLI accepts and executes all four operation types
- [x] CSV files are read and written correctly
- [x] Each row has a unique ID
- [x] Code follows language conventions and best practices

### Success Criteria

- [x] Can execute example commands from assignment
- [x] Tests pass for basic operations
- [x] CLI is user-friendly and handles errors
- [x] Code is clean, readable, and well-organized
- [x] Project is ready for submission

---

## 🎯 Priority Order (Recommended)

1. **Phase 2** → Class structure
2. **Phase 3** → SELECT (basic → where → order → join)
3. **Phase 4** → Write operations (insert → update → delete)
4. **Phase 5** → CLI (REPL → parsers → formatting)
5. **Phase 6** → Testing
6. **Phase 7** → Polish

**Estimated Timeline:** 2-4 weeks depending on experience level

Good luck! Check off items as you complete them. 🚀
