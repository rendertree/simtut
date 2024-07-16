--[[

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>

]]

local SPEED = 200

local screen_width = 0
local screen_height = 0

local score = 0
local rects_total = 0

local paused = false
local game_over = false

-- Using metatables to create a read-only table for constants
local function read_only(t)
    local proxy = {}
    local mt = {
        __index = t,
        __new_index = function(table, key, value)
            error("Attempt to modify read-only table", 2)
        end,
        __metatable = false
    }
    setmetatable(proxy, mt)
    return proxy
end

local CONST = read_only({
    RECT_W = 50,
    RECT_H = 50
})

local rects = {}
local rect = {}
local player_rect = { x = 50, y = 575, w = 100, h = 20 }

function init_rects()
  for i in ipairs(rects) do
      rects[i] = nil
  end
  
  for i = 1, 16 do
        table.insert(rects, {
            x = (i - 1) * CONST.RECT_W,
            y = 50,
            w = CONST.RECT_W,
            h = CONST.RECT_H,
            id = i + 16 * 0
        })
    end
    
    for i = 1, 16 do
        table.insert(rects, {
            x = (i - 1) * CONST.RECT_W,
            y = 100,
            w = CONST.RECT_W,
            h = CONST.RECT_H,
            id = i + 16 * 1
        })
    end
    
    for i = 1, 16 do
        table.insert(rects, {
            x = (i - 1) * CONST.RECT_W,
            y = 150,
            w = CONST.RECT_W,
            h = CONST.RECT_H,
            id = i + 16 * 3
        })
    end
    
    for i = 1, 16 do
        table.insert(rects, {
            x = (i - 1) * CONST.RECT_W,
            y = 200,
            w = CONST.RECT_W,
            h = CONST.RECT_H,
            id = i + 16 * 4
        })
    end

    rects_total = #rects
end

function love.load()
    love.window.setTitle("Classic Game")
    
    -- Set the background color to black
    love.graphics.setBackgroundColor(0, 0, 0)

    -- Collision status
    is_colliding_rects = false
    is_colliding_player = false
    
    init_rects()
    
    rect = {
        x = 100,
        y = 300,
        w = 40,
        h = 40,
        speed_x = 150, -- Speed in the X direction
        speed_y = 100, -- Speed in the Y direction
    }
    
    screen_width = love.graphics.getWidth()
    screen_height = love.graphics.getHeight()
end

-- Check for collision between two rectangles
function check_collision_rect(a, b)
    if a.x < b.x + b.w and
       a.x + a.w > b.x and
       a.y < b.y + b.h and
       a.y + a.h > b.y then
        return true
    else
        return false
    end
end

function love.keypressed(key)
    if key == "p" then
        paused = not paused
    end
    
    if key == "return" and game_over then
        game_over = not game_over
        rect.y = 300
        
        init_rects()
        
        score = 0
    end
end

function love.update(dt)    
    -- Handle player rectangle movement
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        player_rect.x = player_rect.x + SPEED * dt
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        player_rect.x = player_rect.x - SPEED * dt
    end

    -- Clamp the player_rect.x value between 0 and 700
    player_rect.x = math.max(0, math.min(700, player_rect.x))
  
    if not paused and not game_over then
        -- Update the rectangle's position
        rect.x = rect.x + rect.speed_x * dt
        rect.y = rect.y + rect.speed_y * dt
    end

    -- Check for collision between the rect and all other rectangles
    local move_rect = { x = rect.x, y = rect.y, w = rect.w, h = rect.h }
    local is_colliding_rects = false
    for i = 1, #rects do
        if check_collision_rect(move_rect, rects[i]) and rects[i].id ~= 99 then
            is_colliding_rects = true
            rects[i].id = 99
            score = score + 1;
            break
        end
    end
    
    local is_colliding_player = false
    if check_collision_rect(player_rect, move_rect) then
      is_colliding_player = true
    end

    -- Handle collision detection
    if is_colliding_rects or rect.y < 0 then
        -- Move the rect to the bottom of the screen and stop vertical movement
        rect.speed_y = -rect.speed_y
    else
        -- Check for collision with the screen boundaries and reverse direction if needed
        if rect.x < 0 then
            rect.x = 0
            rect.speed_x = -rect.speed_x
        elseif rect.x + rect.w > screen_width then
            rect.x = screen_width - rect.w
            rect.speed_x = -rect.speed_x
        end

        if is_colliding_player then
            rect.speed_y = -rect.speed_y
        end
    end
    
    if rect.y > screen_width and not game_over or score == rects_total then
      game_over = true
    end
end

function love.draw()
    -- Draw the rectangles
    for i, rect in ipairs(rects) do
        if rect.id ~= 99 then
            love.graphics.setColor(0, 0, 1)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        end
    end

    -- Draw the move rect
    love.graphics.setColor(1, 0, 0)  -- Red for the moving rect
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    
    -- Draw player rect
    love.graphics.setColor(0, 1, 0)  -- Green for the player rect
    love.graphics.rectangle("fill", player_rect.x, player_rect.y, player_rect.w, player_rect.h)
    
    -- Display the score
    love.graphics.setColor(1, 1, 1)  -- White text
    local score_text = "Score: " .. tostring(score)
    love.graphics.print(score_text, 10, 10)
    
    if paused then
      love.graphics.print("Paused", screen_width/2-50, screen_height/2, 0, 3, 3)
    end
    
    if game_over then
      love.graphics.print("Game Over", screen_width/2-100, screen_height/2-50, 0, 3, 3)
    end
end
