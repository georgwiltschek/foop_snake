# Multiplayer Snake

Snakes are controlled by up to four clients, AI takes over snakes not claimed by humans. Snakes can eat part of any other snakes, growing the number of segments behind the collision point. On Head-to-Head collisions, one snake kills the other snake depending on the color combination. The surviving snake grows the length of the killed snake.

run with ```ruby server/server.rb [num_snakes]```

connect clients with ```ruby client/client.rb [-opengl]```

requirements:
- ruby (1.9.* needed for -opengl rendering, SDL works with 1.8.7)
- rubysdl gem (Windows/Linux) or rsdl gem (OSX)
- opengl gem (optional)
- json gem (should be included in most ruby versions)
