EMAIL = "user@gmail.com"
PASSWORD = "sucret"

puts "Exapl of prompting"
print "Enter your Email:\n\t->"
email = gets.chomp
if email != EMAIL
  puts "Wrong Email"
else
  print "Enter your Passord:\n\t->"
  password = gets.chomp
  if password != PASSWORD
    puts "Wrong Password"
    exit
  else
    puts "Welcom back #{EMAIL}"
  end
end
