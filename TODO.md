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

- [ ] Implement `order(direction, column_name)` method
  - [ ] Handle `:asc` direction
  - [ ] Handle `:desc` direction
  - [ ] Return `self` for chaining
- [ ] Update `run()` to sort results
  - [ ] Sort after filtering, before returning
  - [ ] Handle numeric vs string sorting
- [ ] **TEST:** `...where('state', 'Indiana').order(:asc, 'name').run`

### Add JOIN

- [ ] Implement `join(column_on_db_a, filename_db_b, column_on_db_b)` method
  - [ ] Load second CSV file
  - [ ] Store join configuration
  - [ ] Return `self` for chaining
- [ ] Update `run()` to perform join
  - [ ] Match rows where join columns are equal
  - [ ] Merge column data from both tables
  - [ ] Handle duplicate column names
- [ ] **TEST:** `...from('players.csv').join('team_id', 'teams.csv', 'id').run`

---

## ✏️ Phase 4: Write Operations

### INSERT

- [ ] Implement `insert(table_name)` method
  - [ ] Set operation type to INSERT
  - [ ] Store table name
  - [ ] Return `self` for chaining
- [ ] Implement `values(data)` method
  - [ ] Accept hash/object of column => value pairs
  - [ ] Store insert data
  - [ ] Return `self` for chaining
- [ ] Update `run()` for INSERT
  - [ ] Generate new ID for row
  - [ ] Append row to CSV file
  - [ ] Return success confirmation
- [ ] **TEST:** `MySqliteRequest.new.insert('students').values({name: 'John', email: 'john@test.com'}).run`

### UPDATE

- [ ] Implement `update(table_name)` method
  - [ ] Set operation type to UPDATE
  - [ ] Store table name
  - [ ] Return `self` for chaining
- [ ] Implement `set(data)` method
  - [ ] Accept hash/object of column => value pairs
  - [ ] Store update data
  - [ ] Return `self` for chaining
- [ ] Update `run()` for UPDATE
  - [ ] Read all rows
  - [ ] Apply WHERE filter to find matching rows
  - [ ] Update matching rows with new values
  - [ ] Write back to CSV
  - [ ] Return count of updated rows
- [ ] **TEST:** `MySqliteRequest.new.update('students').set({email: 'new@test.com'}).where('name', 'John').run`

### DELETE

- [ ] Implement `delete()` method
  - [ ] Set operation type to DELETE
  - [ ] Return `self` for chaining
- [ ] Update `run()` for DELETE
  - [ ] Read all rows
  - [ ] Apply WHERE filter to find matching rows
  - [ ] Remove matching rows
  - [ ] Write remaining rows back to CSV
  - [ ] Return count of deleted rows
- [ ] **TEST:** `MySqliteRequest.new.from('students').delete.where('name', 'John').run`

---

## 💻 Phase 5: Command Line Interface (CLI)

### REPL Setup

- [ ] Set up readline/input loop
- [ ] Display welcome message with version
- [ ] Display prompt: `my_sqlite_cli> `
- [ ] Read user input
- [ ] Handle `quit` command to exit
- [ ] Loop until quit

### SQL Parser Foundation

- [ ] Create function to identify command type (SELECT/INSERT/UPDATE/DELETE)
- [ ] Test with simple commands

### SELECT Parser

- [ ] Parse `SELECT columns FROM table`
- [ ] Extract column names (handle `*`, single, multiple)
- [ ] Extract table name
- [ ] Parse `WHERE column = value` clause
- [ ] Parse `JOIN table2 ON col1 = col2` clause
- [ ] Build MySqliteRequest chain from parsed data
- [ ] Execute and display results
- [ ] **TEST:** `SELECT * FROM students;`
- [ ] **TEST:** `SELECT name FROM students WHERE state = 'Indiana';`

### INSERT Parser

- [ ] Parse `INSERT INTO table VALUES (val1, val2, val3)`
- [ ] Extract table name
- [ ] Extract values from parentheses
- [ ] Map values to columns (read CSV headers)
- [ ] Build MySqliteRequest chain
- [ ] Execute and display success message
- [ ] **TEST:** `INSERT INTO students VALUES (John, john@test.com, A, https://blog.com);`

### UPDATE Parser

- [ ] Parse `UPDATE table SET col1 = val1, col2 = val2 WHERE col = value`
- [ ] Extract table name
- [ ] Parse SET clause into hash/object
- [ ] Parse WHERE clause
- [ ] Build MySqliteRequest chain
- [ ] Execute and display rows affected
- [ ] **TEST:** `UPDATE students SET email = 'new@test.com' WHERE name = 'John';`

### DELETE Parser

- [ ] Parse `DELETE FROM table WHERE col = value`
- [ ] Extract table name
- [ ] Parse WHERE clause
- [ ] Build MySqliteRequest chain
- [ ] Execute and display rows affected
- [ ] **TEST:** `DELETE FROM students WHERE name = 'John';`

### Output Formatting

- [ ] Format SELECT results (pipe-separated values)
- [ ] Format INSERT/UPDATE/DELETE confirmations
- [ ] Handle empty results gracefully
- [ ] Handle errors with clear messages

---

## 🐛 Phase 6: Testing & Edge Cases

### Core Functionality Tests

- [ ] Test with empty CSV file
- [ ] Test with non-existent table/file
- [ ] Test with non-existent column in WHERE
- [ ] Test with non-existent column in SELECT
- [ ] Test SELECT with no WHERE
- [ ] Test UPDATE with no WHERE (updates all rows)
- [ ] Test DELETE with no WHERE (deletes all rows)
- [ ] Test JOIN with no matches

### CLI Tests

- [ ] Test invalid SQL syntax
- [ ] Test malformed commands
- [ ] Test missing semicolons
- [ ] Test case sensitivity
- [ ] Test extra whitespace
- [ ] Test empty input
- [ ] Test very long queries

### Data Integrity Tests

- [ ] Verify IDs are unique after INSERT
- [ ] Verify CSV format is maintained after write operations
- [ ] Verify data types are preserved (numbers, strings)
- [ ] Test with special characters in data
- [ ] Test with quotes in string values

---

## 🎨 Phase 7: Polish & Documentation

### Code Quality

- [ ] Add comments to complex logic
- [ ] Refactor duplicate code
- [ ] Ensure consistent naming conventions
- [ ] Handle errors gracefully (try-catch blocks)
- [ ] Add input validation

### Documentation

- [ ] Write README with usage examples
- [ ] Document all public methods
- [ ] Add examples for each operation type
- [ ] Document limitations (max 1 WHERE, max 1 JOIN)
- [ ] Add notes about CSV format requirements

### Optional Enhancements

- [ ] Add support for multiple WHERE conditions
- [ ] Add ORDER BY to CLI
- [ ] Add support for aggregate functions (COUNT, SUM, AVG)
- [ ] Add basic index structure for faster lookups
- [ ] Add transaction support (rollback on error)

---

## 📚 Learning & Research

### Concepts to Study

- [ ] Read about B-Tree data structure
  - [ ] Understand how it differs from Binary Tree
  - [ ] Learn why databases use B-Trees
- [ ] Read about TRIE (Prefix Tree)
  - [ ] Understand use cases for string searching
  - [ ] Consider applications in query optimization
- [ ] Read about Reverse Index
  - [ ] Understand value → row ID mapping
  - [ ] Consider how to implement for your project

### Optional Deep Dives

- [ ] Study how real SQLite stores data
- [ ] Learn about query optimization
- [ ] Research database indexing strategies
- [ ] Explore ACID properties in databases

---

## ✅ Definition of Done

### Minimum Requirements

- [ ] All methods in MySqliteRequest class work correctly
- [ ] Method chaining works properly (returns self)
- [ ] CLI accepts and executes all four operation types
- [ ] CSV files are read and written correctly
- [ ] Each row has a unique ID
- [ ] Code follows language conventions and best practices

### Success Criteria

- [ ] Can execute example commands from assignment
- [ ] Tests pass for basic operations
- [ ] CLI is user-friendly and handles errors
- [ ] Code is clean, readable, and well-organized
- [ ] Project is ready for submission

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
