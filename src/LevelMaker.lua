--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    ::resetMap::
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND

    local keyIsGenerated = false
    local lockIsGenerated = false

    local keyColor = math.random(#KEY_IDS)
    local lockColor = keyColor
    local hasKey = false
    local lockPosition = 0

    local poleColor = math.random(#POLE_IDS)
    local flagColor = math.random(#FLAG_IDS)

    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY

        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        --don't let emptiness be last box
        if math.random(7) == 1 and x ~= width then
          for y = 7, height do
              table.insert(tiles[y],
                  Tile(x, y, tileID, nil, tileset, topperset))
          end
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            -- except on the last box
            if math.random(8) == 1 and x ~= width then
                blockHeight = 2

                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end
                -- chance to generate key on pillar
                if not keyIsGenerated then
                  if math.random(8) == 1 then
                      table.insert(objects,
                          GameObject {
                              texture = 'keys',
                              x = (x - 1) * TILE_SIZE,
                              y = (4 - 1) * TILE_SIZE,
                              width = 16,
                              height = 16,
                              consumable = true,

                              -- select keyColor frame
                              frame = KEY_IDS[keyColor],

                              onConsume = function(player, object)
                                hasKey = true
                                gSounds['pickup']:play()
                              end

                          }
                      )
                      keyIsGenerated = true
                    end
                  end

                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil

            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[#BUSH_IDS] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(player, obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }

                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )

            -- chance to generate lock
            elseif not lockIsGenerated then
              if math.random(25) == 1 then
                lockPosition = #objects + 1
                table.insert(objects,
                    GameObject {
                        texture = 'locks',
                        x = x * TILE_SIZE,
                        y = (4 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        collidable = true,
                        solid = true,
                        -- select keyColor frame
                        frame = LOCK_IDS[lockColor],

                        -- collision function takes player
                        onCollide = function(player, object)
                          if hasKey then
                            --play the sound to indicate in key
                            gSounds['pickup']:play()
                            object.x = width


                            -- maintain reference so we can set it to nil
                            local pole = GameObject {
                              texture = 'poles',
                              --TESTING
                              x = (width - 1) * TILE_SIZE,
                              y = (4 - 1) * TILE_SIZE,
                              width = 16,
                              height = 48,
                              collidable = true,
                              -- select frame
                              frame = POLE_IDS[poleColor],

                              onCollide = function(player, object)
                                gSounds['pickup']:play()
                                player.score = player.score + 200
                              end
                            }
                            table.insert(objects, pole)

                            -- maintain reference so we can set it to nil
                            local flag = GameObject {
                                texture = 'flags',
                                x = (width - 3) * TILE_SIZE,
                                y = (4 - 1) * TILE_SIZE,
                                width = 64,
                                height = 16,
                                consumable = true,
                                -- select frame
                                frame = FLAG_IDS[flagColor],

                                onConsume = function(player, object)
                                  gStateMachine:change('play', {player = player})
                                end
                              }
                              table.insert(objects, flag)
                            end
                        end
                    }
                )
                lockIsGenerated = true
              end
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles

    --ensure that lock and key are generated
    if (keyIsGenerated and lockIsGenerated) then
      return GameLevel(entities, objects, map)
    else
      goto resetMap
      print("goto")
    end
end
