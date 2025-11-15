require "csv"

class MySqliteRequest

    attr_reader :file_path, :table_name

    def initialize(file_path = nil )
        @file_path = file_path || ''
        

    end
    def from(table_name)
        @table_name = table_name
        self
    end
    def select(column_name)

        

        self
    end
    def where(column_name, criteria)
    
        self
    end
    def join(column_on_db_a, filename_db_b, column_on_db_b)
    
        self
    end
    def order(order, column_name)
    
    
        self
    end
    def insert(table_name)
    
    
        self
    end
    def values(data)
    end
    def update(table_name)
    
    
        self
    end
    def set(data)
    
    
        self
    end
    def delete
    
    
        self
    end




    def run
        My_CSV.parse(@table_name)
    end
end

class My_CSV

    attr_reader :file_path, :table
    @@header = nil
    @@table = nil
    def initialize(file_path)
        @file_path = file_path
        @@table = CSV.read(@file_path)
        @@header = @@table[0]
    end
    def self.header(file_path)
        if new(file_path)
            @@header
        end

    end
    def self.table(file_path)
        if new(file_path)
            @@table
        end
    end

    def self.get_records(table_name, criteria, selected = "*")

        new(table_name)
        records = []
        result =[]
        index = @@header.index(criteria[:column_name])
        @@table.each_with_index do |record, i|
            next if i == 0
            if record[index] == criteria[:value]
                records.push(record)
            end
        end
        if selected == "*"
            result = records
        end

        if self.column_existe?(selected)
            records.each do |col|
                result.push(col[@@header.index(selected)])
            end
        end

        result
    end
    def self.column_existe?(column_name)
        @@header.include?(column_name)
    end
end

# last_cursor = 0
# data = CSV.read("test.csv")
# puts data.inspect
# header = data[0]
# puts header.inspect
# puts header.index()
criteria = {
    :column_name => "birth_state",
    :condition => "==",
    :value => "Louisiana"
}
puts My_CSV.get_records("nba_players.csv", criteria, "Playe").inspect
# puts My_CSV.header("test.csv").inspect
# puts My_CSV.table("test.csv").inspect


# file = File.open("test.txt", "r+")
# header =  file.readline
# puts "Offset after reading #{header.length} bytes: #{file.tell}"
# file.seek(file.tell, IO::SEEK_SET)
# puts file.readline
# puts "Offset after reading #{header.length} bytes: #{file.tell}"

# puts file.readline
# # puts file.readline
# # puts
# File.open("test.txt", "r+") do |file|
#     header = file.readline
#     puts header.inspect
#     puts file.tell
#     last_cursor = file.tell
#     file.seek(last_cursor, IO::SEEK_SET)
#     file.puts("2047,Alaa Abdelnaby,208,108,Duke University,1968,Cairo,Egypt")
#     last_cursor = file.tell
#     file.seek(last_cursor, IO::SEEK_SET)
#     file.puts("746,Zaid Abdul-Aziz,206,106,Iowa State University,1946,Brooklyn,New York")
#     puts last_cursor
# end