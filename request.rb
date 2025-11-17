require_relative "my_sqlite_request"

# MySqliteRequest.new("short_nba_players").select("*").where("birth_state", "New York").run
# # p MySqliteRequest.new("short_nba_players").select("Player").where("birth_state", "New York").run
# MySqliteRequest.new("short_nba_players").select(["Player", "birth_state"]).where("birth_state", "New York").run

request = MySqliteRequest.new
request.from("short_nba_players")
request.select("Player")
request.where("birth_state", "New York")
request.run
