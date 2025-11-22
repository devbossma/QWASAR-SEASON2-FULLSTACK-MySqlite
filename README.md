# Welcome to My Sqlite

---

## Task

**The Challenge:** Build a simplified SQLite-like database system from scratch that operates on CSV files instead of binary database files. The core challenge is to implement SQL query parsing, execution, and data manipulation without using any existing database libraries.

**Key Problems to Solve:**
- **Query Building Pattern:** Implement a fluent interface that allows method chaining (like ActiveRecord or LINQ)
- **SQL Parsing:** Parse SQL-like syntax from command-line input into executable operations
- **Data Persistence:** Read from and write to CSV files while maintaining data integrity
- **Join Operations:** Implement INNER JOIN logic with proper column merging and duplicate handling
- **Multi-line Query Support:** Handle incomplete queries that span multiple lines, only executing when semicolon is encountered

**Technical Challenges:**
- CSV file handling with proper header/row separation
- Regular expression patterns for SQL syntax parsing
- State management in the query builder pattern
- Error handling for invalid queries, missing tables, and non-existent columns
- Sorting with mixed data types (numbers, strings, nil values)

## Description

**Solution Architecture:**

This project implements a three-layer architecture:

### 1. **Data Layer (MyCSV)**
Handles all low-level CSV operations:
- Reads and parses CSV files into memory (header + data rows)
- Implements filtering, sorting, and joining algorithms
- Manages data persistence (INSERT, UPDATE, DELETE)
- Validates column existence and handles errors
- Supports custom headers for joined tables

### 2. **Query Builder Layer (MySqliteRequest)**
Implements the query builder pattern:
- Fluent interface with method chaining (each method returns `self`)
- Stores query state (table, columns, filters, joins, sort order)
- Lazy execution - builds query structure without executing until `run()` is called
- Orchestrates correct operation order: JOIN → WHERE → ORDER BY → SELECT
- Translates high-level operations into MyCSV method calls

### 3. **Interface Layer (MySqliteCli)**
Provides interactive command-line interface:
- REPL (Read-Eval-Print Loop) with readline support
- Multi-line query support (buffers input until semicolon)
- Regex-based SQL parsing for SELECT, INSERT, UPDATE, DELETE
- Formats and displays results in pipe-separated format
- Comprehensive error handling with user-friendly messages

**Key Design Decisions:**

1. **Query Builder Pattern:** Chosen for its flexibility and SQL-like syntax
2. **CSV as Storage:** Simple, human-readable, no binary parsing needed
3. **INNER JOIN Only:** Sufficient for requirements, easier to implement than OUTER joins
4. **Duplicate Column Handling:** Suffix `_b` for columns from second table in joins
5. **Defense in Depth:** Validation at multiple levels (CLI parsing, request building, CSV operations)

---

## Installation

### Prerequisites
- Ruby 2.7 or higher
- Standard Ruby libraries (CSV, Readline)

### Setup Instructions

1. **Clone or download the project files:**
```bash
my_sqlite/
├── my_sqlite_request.rb    # Query builder class + CSV handler class
├── my_sqlite_cli.rb         # Command-line interface
└── *.csv                     # Your CSV data files
```

2. **No external dependencies required** - uses only Ruby standard library

3. **Make the CLI executable (optional):**
```bash
chmod +x my_sqlite_cli.rb
```

4. **Verify installation:**
```bash
ruby my_sqlite_cli.rb
# Should display: MySQLite version 0.1 YYYY-MM-DD
```

---

## Usage

### Command-Line Interface

**Start the interactive CLI:**
```bash
ruby my_sqlite_cli.rb
```

or with a database name (optional):
```bash
ruby my_sqlite_cli.rb students.db
```

### Programmatic Usage

**Using the Query Builder directly in Ruby:**

```ruby
require_relative 'my_sqlite_request'

# Basic SELECT query
results = MySqliteRequest.new
  .from('students')
  .select('name')
  .where('state', 'California')
  .run

# Complex query with JOIN and ORDER
results = MySqliteRequest.new
  .from('students')
  .join('id', 'courses', 'student_id')
  .select(['name', 'course_name', 'gpa'])
  .where('state', 'Texas')
  .order(:desc, 'gpa')
  .run

# INSERT operation
MySqliteRequest.new
  .insert('students')
  .values({
    "name" => "Alice Johnson",
    "email" => "alice@university.edu",
    "state" => "California",
    "gpa" => "3.8"
  })
  .run

# UPDATE operation
MySqliteRequest.new
  .update('students')
  .set({ "gpa" => "4.0" })
  .where('name', 'Alice Johnson')
  .run

# DELETE operation
MySqliteRequest.new
  .from('students')
  .delete
  .where('state', 'Texas')
  .run
```

### SQL Commands in CLI

#### **SELECT Queries**

```sql
-- Select all columns
my_sqlite_cli> SELECT * FROM students;

-- Select specific columns
my_sqlite_cli> SELECT name, email, gpa FROM students;

-- With WHERE filter
my_sqlite_cli> SELECT * FROM students WHERE state = 'California';

-- With ORDER BY
my_sqlite_cli> SELECT name, gpa FROM students ORDER BY gpa DESC;

-- With JOIN
my_sqlite_cli> SELECT name, course_name 
            ...> FROM students 
            ...> JOIN courses ON id = student_id;

-- Complex multi-line query
my_sqlite_cli> SELECT name, course_name, gpa
            ...> FROM students
            ...> JOIN courses ON id = student_id
            ...> WHERE state = 'California'
            ...> ORDER BY gpa DESC;
```

#### **INSERT Queries**

```sql
-- Insert new row (ID auto-generated)
my_sqlite_cli> INSERT INTO students VALUES (John Doe, john@test.com, 21, Texas, Computer Science, 3.5, 2023);

-- Result: Inserted 1 row (ID: 11)
```

#### **UPDATE Queries**

```sql
-- Update specific row
my_sqlite_cli> UPDATE students SET gpa = '4.0' WHERE name = 'Alice Johnson';

-- Update multiple columns
my_sqlite_cli> UPDATE students SET email = 'new@test.com', state = 'Nevada' WHERE id = '5';

-- Update all rows (no WHERE)
my_sqlite_cli> UPDATE students SET enrollment_year = '2024';
```

#### **DELETE Queries**

```sql
-- Delete specific rows
my_sqlite_cli> DELETE FROM students WHERE state = 'Texas';

-- Delete all rows (use with caution!)
my_sqlite_cli> DELETE FROM students;
```

#### **Special Commands**

```sql
-- Exit the CLI
my_sqlite_cli> quit
-- or
my_sqlite_cli> exit

-- Cancel incomplete query
my_sqlite_cli> SELECT * FROM
            ...> [Press Ctrl+C]
Query cancelled
```

### CSV File Format

Your CSV files should follow this structure:

**students.csv:**
```csv
id,name,email,age,state,major,gpa,enrollment_year
1,Alice Johnson,alice@test.com,20,California,Computer Science,3.8,2022
2,Bob Smith,bob@test.com,22,Texas,Mathematics,3.5,2020
```

**Important Notes:**
- First row must be headers (column names)
- ID column is recommended for joins and identification
- All values are stored as strings
- No spaces around commas
- Quote values containing commas or special characters

### Features & Limitations

**✅ Supported Features:**
- SELECT, INSERT, UPDATE, DELETE operations
- WHERE filtering (one condition per query)
- INNER JOIN (one join per query)
- ORDER BY (ASC/DESC)
- Multi-line queries with semicolon termination
- Auto-incrementing IDs on INSERT
- Duplicate column handling in JOINs (with `_b` suffix)
- Case-insensitive SQL keywords
- Quoted and unquoted values

**❌ Current Limitations:**
- No support for multiple WHERE conditions (use AND/OR)
- No support for multiple JOINs in single query
- No aggregate functions (COUNT, SUM, AVG, etc.)
- No GROUP BY or HAVING clauses
- No LIKE pattern matching
- No subqueries
- No transactions or rollback
- No indexes (all operations are O(n) scans)

### Error Handling

The system provides clear error messages:

```sql
-- Non-existent table
my_sqlite_cli> SELECT * FROM nonexistent;
Error executing query: Table 'nonexistent' does not exist

-- Non-existent column
my_sqlite_cli> SELECT invalid_column FROM students;
Error executing query: Column 'invalid_column' does not exist in table

-- Invalid WHERE syntax
my_sqlite_cli> SELECT * FROM students WHERE;
Error: Invalid WHERE syntax. Expected: WHERE column = value

-- Missing semicolon (query waits for more input)
my_sqlite_cli> SELECT * FROM students
            ...> [continues on next line]
```

### Examples

**Example 1: Student Course Enrollment Query**
```sql
my_sqlite_cli> SELECT name, course_name, instructor
            ...> FROM students
            ...> JOIN courses ON id = student_id
            ...> WHERE major = 'Computer Science'
            ...> ORDER BY name ASC;

Alice Johnson|Data Structures|Dr. Anderson
Alice Johnson|Database Systems|Dr. Brown
Diana Prince|Algorithms|Dr. Anderson
(3 rows)
```

**Example 2: Batch Update**
```sql
my_sqlite_cli> UPDATE students 
            ...> SET enrollment_year = '2024' 
            ...> WHERE enrollment_year = '2023';

Updated 2 row(s)
```

**Example 3: Data Cleanup**
```sql
my_sqlite_cli> DELETE FROM courses WHERE credits = '3';
Deleted 8 row(s)
```

### Testing

Run the included test files:

```bash
# Test INSERT, UPDATE, DELETE operations
ruby insert_update_delete_tests.rb

# Generate test CSV files
ruby generate_test_data.rb

# Test queries interactively
ruby my_sqlite_cli.rb
```

### Troubleshooting

**"Table does not exist" error:**
- Ensure CSV file exists in the same directory
- Check file name matches (case-sensitive)
- File must have .csv extension

**"Column does not exist" error:**
- Verify column name in CSV header row
- Check for typos or extra spaces
- Column names are case-sensitive

**Query returns 0 rows unexpectedly:**
- Check WHERE condition value matches exactly
- Remember all values are strings (use '5' not 5)
- Verify data exists in CSV file

**Multi-line query not executing:**
- Ensure you end query with semicolon (;)
- Press Ctrl+C to cancel and start over

---

### The Core Team

<span><i>Made at <a href='https://qwasar.io'>Qwasar SV -- Software Engineering School</a></i></span>
<span><img alt='Qwasar SV -- Software Engineering School's Logo' src='https://storage.googleapis.com/qwasar-public/qwasar-logo_50x50.png' width='20px' /></span>
