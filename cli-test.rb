require "csv"

# ==================== STUDENTS TABLE ====================
puts "Creating students.csv..."

CSV.open("students.csv", "w") do |csv|
  csv << ["id", "name", "email", "age", "state", "major", "gpa", "enrollment_year"]
  csv << ["1", "Alice Johnson", "alice.j@university.edu", "20", "California", "Computer Science", "3.8", "2022"]
  csv << ["2", "Bob Smith", "bob.smith@university.edu", "22", "Texas", "Mathematics", "3.5", "2020"]
  csv << ["3", "Charlie Brown", "charlie.b@university.edu", "21", "New York", "Physics", "3.9", "2021"]
  csv << ["4", "Diana Prince", "diana.p@university.edu", "19", "California", "Computer Science", "3.7", "2023"]
  csv << ["5", "Eve Davis", "eve.d@university.edu", "23", "Texas", "Biology", "3.6", "2019"]
  csv << ["6", "Frank Miller", "frank.m@university.edu", "20", "New York", "Computer Science", "3.4", "2022"]
  csv << ["7", "Grace Lee", "grace.l@university.edu", "21", "California", "Mathematics", "3.9", "2021"]
  csv << ["8", "Henry Wilson", "henry.w@university.edu", "22", "Florida", "Physics", "3.3", "2020"]
  csv << ["9", "Iris Chen", "iris.c@university.edu", "20", "New York", "Biology", "3.8", "2022"]
  csv << ["10", "Jack Taylor", "jack.t@university.edu", "19", "Texas", "Computer Science", "3.5", "2023"]
end

puts "✅ students.csv created with 10 students"
puts

# ==================== COURSES TABLE ====================
puts "Creating courses.csv..."

CSV.open("courses.csv", "w") do |csv|
  csv << ["id", "course_name", "instructor", "credits", "department", "student_id"]
  csv << ["1", "Data Structures", "Dr. Anderson", "4", "Computer Science", "1"]
  csv << ["2", "Linear Algebra", "Dr. Martinez", "3", "Mathematics", "2"]
  csv << ["3", "Quantum Mechanics", "Dr. Johnson", "4", "Physics", "3"]
  csv << ["4", "Algorithms", "Dr. Anderson", "4", "Computer Science", "4"]
  csv << ["5", "Molecular Biology", "Dr. White", "3", "Biology", "5"]
  csv << ["6", "Database Systems", "Dr. Brown", "3", "Computer Science", "1"]
  csv << ["7", "Calculus III", "Dr. Martinez", "4", "Mathematics", "7"]
  csv << ["8", "Thermodynamics", "Dr. Johnson", "3", "Physics", "8"]
  csv << ["9", "Genetics", "Dr. White", "4", "Biology", "9"]
  csv << ["10", "Web Development", "Dr. Brown", "3", "Computer Science", "10"]
  csv << ["11", "Discrete Math", "Dr. Martinez", "3", "Mathematics", "2"]
  csv << ["12", "Operating Systems", "Dr. Anderson", "4", "Computer Science", "6"]
  csv << ["13", "Cell Biology", "Dr. White", "3", "Biology", "5"]
  csv << ["14", "Statistical Mechanics", "Dr. Johnson", "4", "Physics", "3"]
  csv << ["15", "Machine Learning", "Dr. Brown", "4", "Computer Science", "1"]
end

puts "✅ courses.csv created with 15 courses"
puts

# ==================== DISPLAY SAMPLE DATA ====================
puts "=" * 70
puts "SAMPLE DATA - STUDENTS"
puts "=" * 70
students = CSV.read("students.csv")
students[0..3].each { |row| puts row.join(" | ") }
puts "... (#{students.length - 1} total students)"
puts

puts "=" * 70
puts "SAMPLE DATA - COURSES"
puts "=" * 70
courses = CSV.read("courses.csv")
courses[0..3].each { |row| puts row.join(" | ") }
puts "... (#{courses.length - 1} total courses)"
puts

# ==================== TEST QUERIES GUIDE ====================
puts "=" * 70
puts "🧪 SUGGESTED TEST QUERIES"
puts "=" * 70
puts

puts "📝 SELECT QUERIES:"
puts "-" * 70
puts "1. SELECT * FROM students;"
puts "2. SELECT name, email, gpa FROM students;"
puts "3. SELECT * FROM students WHERE state = 'California';"
puts "4. SELECT name, major FROM students WHERE gpa = '3.9';"
puts "5. SELECT * FROM students ORDER BY gpa DESC;"
puts "6. SELECT * FROM students ORDER BY name ASC;"
puts

puts "🔗 JOIN QUERIES:"
puts "-" * 70
puts "7. SELECT * FROM students JOIN courses ON id = student_id;"
puts "8. SELECT name, course_name FROM students JOIN courses ON id = student_id;"
puts "9. SELECT name, course_name, instructor FROM students JOIN courses ON id = student_id WHERE state = 'California';"
puts "10. SELECT * FROM students JOIN courses ON id = student_id ORDER BY name ASC;"
puts

puts "➕ INSERT QUERIES:"
puts "-" * 70
puts "11. INSERT INTO students VALUES (Kevin Brown, kevin.b@university.edu, 21, Oregon, Engineering, 3.7, 2022);"
puts "12. INSERT INTO courses VALUES (Advanced AI, Dr. Smith, 4, Computer Science, 1);"
puts

puts "✏️  UPDATE QUERIES:"
puts "-" * 70
puts "13. UPDATE students SET gpa = '4.0' WHERE name = 'Alice Johnson';"
puts "14. UPDATE students SET state = 'Nevada' WHERE state = 'California';"
puts "15. UPDATE courses SET credits = '5' WHERE course_name = 'Machine Learning';"
puts

puts "🗑️  DELETE QUERIES:"
puts "-" * 70
puts "16. DELETE FROM courses WHERE credits = '3';"
puts "17. DELETE FROM students WHERE gpa = '3.3';"
puts

puts "🎯 MULTI-LINE QUERIES (test semicolon handling):"
puts "-" * 70
puts "18. SELECT name, email"
puts "    FROM students"
puts "    WHERE state = 'Texas';"
puts
puts "19. UPDATE students"
puts "    SET major = 'Data Science'"
puts "    WHERE major = 'Computer Science';"
puts

puts "⚠️  ERROR TESTING:"
puts "-" * 70
puts "20. SELECT * FROM nonexistent_table;"
puts "21. SELECT * FROM students WHERE nonexistent_column = 'test';"
puts "22. UPDATE students SET nonexistent = 'value' WHERE name = 'Alice';"
puts

puts "=" * 70
puts "🚀 START TESTING"
puts "=" * 70
puts "Run: ruby my_sqlite_cli.rb"
puts "Then copy-paste the queries above!"
puts
