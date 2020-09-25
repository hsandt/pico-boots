-- common pico-8 constants

-- screen
screen_width = 128
screen_height = 128

-- tilemap
tile_size = 8
map_region_tile_width = 128
map_region_tile_height = 32  -- we don't use shared data so stop at 32
map_region_width  = map_region_tile_width  * tile_size
map_region_height = map_region_tile_height * tile_size

-- text dimensions (including separator space)
character_width = 4
character_height = 6

-- time
fps60 = 60
fps30 = 30
delta_time60 = 0x0000.0444  -- 1/60 = 0.01666259765625
delta_time30 = 0x0000.0888  -- 1/30 = 0.0333251953125
