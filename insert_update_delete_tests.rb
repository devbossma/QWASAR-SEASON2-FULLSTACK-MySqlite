require_relative "my_sqlite_request"
require_relative "my_csv"

# Create a test CSV file
def create_test_file
  File.open("test_students.csv", "w") do |f|
    f.puts "id,name,email,state,grade"
    f.puts "1,Alice,alice@test.com,California,A"
    f.puts "2,Bob,bob@test.com,Texas,B"
    f.puts "3,Charlie,charlie@test.com,New York,A"
  end
  puts "✅ Test file created: test_students.csv\n\n"
end

# Helper to display table contents
def show_table(message)
  puts "=" * 60
  puts message
  puts "=" * 60
  result = MySqliteRequest.new("test_students").select("*").run
  result.each do |row|
    puts row.inspect
  end
  puts "\nTotal rows: #{result.count}\n\n"
end

# Clean up
File.delete("test_students.csv") if File.exist?("test_students.csv")

puts "\n🧪 TESTING INSERT, UPDATE, DELETE OPERATIONS\n"
puts "=" * 60

# ==================== INSERT TESTS ====================
puts "\n📝 TEST 1: INSERT - Add a new student"
puts "-" * 60

create_test_file
show_table("BEFORE INSERT:")

puts "Executing: INSERT INTO test_students VALUES (David, david@test.com, Florida, B)"
result = MySqliteRequest.new
  .insert("test_students")
  .values({
    "name" => "David",
    "email" => "david@test.com",
    "state" => "Florida",
    "grade" => "B"
  })
  .run

puts "Insert result: #{result.inspect}"
show_table("AFTER INSERT:")

# ==================== INSERT TEST 2 ====================
puts "\n📝 TEST 2: INSERT - Add another student"
puts "-" * 60

puts "Executing: INSERT INTO test_students VALUES (Eve, eve@test.com, Oregon, A)"
result = MySqliteRequest.new
  .insert("test_students")
  .values({
    "name" => "Eve",
    "email" => "eve@test.com",
    "state" => "Oregon",
    "grade" => "A"
  })
  .run

puts "Insert result: #{result.inspect}"
show_table("AFTER SECOND INSERT:")

# ==================== UPDATE TESTS ====================
puts "\n✏️  TEST 3: UPDATE with WHERE - Change Bob's email"
puts "-" * 60

show_table("BEFORE UPDATE:")

puts "Executing: UPDATE test_students SET email = 'robert@test.com' WHERE name = 'Bob'"
result = MySqliteRequest.new
  .update("test_students")
  .set({"email" => "robert@test.com"})
  .where("name", "Bob")
  .run

puts "Update result: #{result.inspect}"
show_table("AFTER UPDATE:")

# Verify Bob's email changed
bob = MySqliteRequest.new("test_students").select("*").where("name", "Bob").run
puts "✓ Bob's new email: #{bob[0]["email"]}"
puts ""

# ==================== UPDATE TEST 2 ====================
puts "\n✏️  TEST 4: UPDATE with WHERE - Change all A grades to A+"
puts "-" * 60

show_table("BEFORE UPDATE:")

puts "Executing: UPDATE test_students SET grade = 'A+' WHERE grade = 'A'"
result = MySqliteRequest.new
  .update("test_students")
  .set({"grade" => "A+"})
  .where("grade", "A")
  .run

puts "Update result: #{result.inspect}"
show_table("AFTER UPDATE:")

# Count A+ grades
a_plus = MySqliteRequest.new("test_students").select("*").where("grade", "A+").run
puts "✓ Students with A+ grade: #{a_plus.count}"
puts ""

# ==================== UPDATE TEST 3 ====================
puts "\n✏️  TEST 5: UPDATE without WHERE - Change all states to 'Unknown'"
puts "-" * 60

show_table("BEFORE UPDATE (no WHERE):")

puts "Executing: UPDATE test_students SET state = 'Unknown'"
result = MySqliteRequest.new
  .update("test_students")
  .set({"state" => "Unknown"})
  .run

puts "Update result: #{result.inspect}"
show_table("AFTER UPDATE (all rows affected):")

# Reset for delete tests
File.delete("test_students.csv")
create_test_file

# ==================== DELETE TESTS ====================
puts "\n🗑️  TEST 6: DELETE with WHERE - Remove Charlie"
puts "-" * 60

show_table("BEFORE DELETE:")

puts "Executing: DELETE FROM test_students WHERE name = 'Charlie'"
result = MySqliteRequest.new
  .from("test_students")
  .delete
  .where("name", "Charlie")
  .run

puts "Delete result: #{result.inspect}"
show_table("AFTER DELETE:")

# Verify Charlie is gone
charlie = MySqliteRequest.new("test_students").select("*").where("name", "Charlie").run
puts "✓ Charlie in database: #{(charlie.count == 0) ? "NO (deleted)" : "YES (still there)"}"
puts ""

# ==================== DELETE TEST 2 ====================
puts "\n🗑️  TEST 7: DELETE with WHERE - Remove all Texas students"
puts "-" * 60

show_table("BEFORE DELETE:")

puts "Executing: DELETE FROM test_students WHERE state = 'Texas'"
result = MySqliteRequest.new
  .from("test_students")
  .delete
  .where("state", "Texas")
  .run

puts "Delete result: #{result.inspect}"
show_table("AFTER DELETE:")

# ==================== DELETE TEST 3 ====================
puts "\n🗑️  TEST 8: DELETE without WHERE - Remove all remaining rows"
puts "-" * 60

show_table("BEFORE DELETE (no WHERE):")

puts "Executing: DELETE FROM test_students (no WHERE - deletes ALL)"
result = MySqliteRequest.new
  .from("test_students")
  .delete
  .run

puts "Delete result: #{result.inspect}"
show_table("AFTER DELETE (should be empty):")

# ==================== EDGE CASE TESTS ====================
puts "\n⚠️  TEST 9: UPDATE non-existent column (should raise error)"
puts "-" * 60

# Recreate file
File.delete("test_students.csv")
create_test_file

begin
  MySqliteRequest.new
    .update("test_students")
    .set({"nonexistent_column" => "value"})
    .where("name", "Alice")
    .run
  puts "❌ ERROR: Should have raised ArgumentError!"
rescue ArgumentError => e
  puts "✅ PASS: Correctly raised error: #{e.message}"
end
puts ""

# ==================== EDGE CASE TEST 2 ====================
puts "\n⚠️  TEST 10: DELETE with non-existent column (should raise error)"
puts "-" * 60

begin
  MySqliteRequest.new
    .from("test_students")
    .delete
    .where("nonexistent_column", "value")
    .run
  puts "❌ ERROR: Should have raised ArgumentError!"
rescue ArgumentError => e
  puts "✅ PASS: Correctly raised error: #{e.message}"
end
puts ""

# ==================== EDGE CASE TEST 3 ====================
puts "\n⚠️  TEST 11: INSERT into non-existent table (should raise error)"
puts "-" * 60

begin
  MySqliteRequest.new
    .insert("nonexistent_table")
    .values({"name" => "Test"})
    .run
  puts "❌ ERROR: Should have raised error!"
rescue => e
  puts "✅ PASS: Correctly raised error: #{e.class} - #{e.message}"
end
puts ""

# ==================== SUMMARY ====================
puts "\n" + "=" * 60
puts "🎯 TEST SUMMARY"
puts "=" * 60
puts "Run all tests above and check:"
puts "1. ✅ INSERT adds new rows with auto-generated IDs"
puts "2. ✅ UPDATE with WHERE modifies only matching rows"
puts "3. ✅ UPDATE without WHERE modifies all rows"
puts "4. ✅ DELETE with WHERE removes only matching rows"
puts "5. ✅ DELETE without WHERE removes all rows"
puts "6. ✅ Errors are raised for non-existent columns"
puts "7. ✅ Table contents are properly saved to CSV"
puts "=" * 60

# Cleanup
File.delete("test_students.csv") if File.exist?("test_students.csv")
puts "\n🧹 Cleanup: test_students.csv deleted\n"
