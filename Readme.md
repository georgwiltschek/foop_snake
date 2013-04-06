# Multiplayer Snake

Snakes are controlled by up to four clients, AI takes over snakes not claimed by humans. Snakes can eat part of any other snakes, growing the number of segments behind the collision point. On Head-to-Head collisions, one snake kills the other snake depending on the color combination. The surviving snake grows the length of the killed snake.

run with ```ruby server/server.rb [num_snakes]```

connect clients with ```ruby client/client.rb```

requirements:
- ruby 1.9.* (maybe 1.9.3? maybe works with 1.8.*...)
- rubysdl (Windows/Linux)
- rsdl (OSX)