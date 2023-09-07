

-- Name this file `main.lua`. Your game can use multiple source files if you wish
-- (use the `import "myFilename"` command), but the simplest games can be written
-- with just `main.lua`.

-- You'll want to import these in just about every project you'll work on.

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Declaring this "gfx" shorthand will make your life easier. Instead of having
-- to preface all graphics calls with "playdate.graphics", just use "gfx."
-- Performance will be slightly enhanced, too.
-- NOTE: Because it's local, you'll have to do it in every .lua source file.

local gfx <const> = playdate.graphics

-- Global variable pile-on!
local default_n_powers_to_display = 4
local default_base = 10
local axis_options = { "log", "linear" }

local n_powers_to_display = default_n_powers_to_display
local base = default_base
local current_axis = 1


-- A function to set up our game environment.

function myGameSetUp()

    local myfont = gfx.font.new("Fonts/font-rains-1x")

    gfx.setFont(myfont)


    local myInputHandlers = {

        upButtonDown = function()
            n_powers_to_display = math.min(n_powers_to_display + 1, 6)
        end,

        downButtonDown = function()
            n_powers_to_display = math.max(n_powers_to_display - 1, 1)
        end,

        leftButtonDown = function()
            base = math.min(base+1, 16)
        end,

        rightButtonDown = function()
            base = math.max(base-1, 2)
        end,

        BButtonDown = function()
            n_powers_to_display = default_n_powers_to_display
            base = default_base
        end,

        AButtonDown = function()
            current_axis += 1
            if current_axis > #axis_options then
                current_axis = 1
            end
        end

    }

    playdate.inputHandlers.push(myInputHandlers)

end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

myGameSetUp()

DEG_TO_RAD = 0.01745329

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.

function playdate.update()

    local function drawTick(angle_deg, circle_r, circle_center, label, label_radius_fudge)
        local crankangle = playdate.getCrankPosition()
        local theta_deg = angle_deg + crankangle
        while(theta_deg > 360) do
            theta_deg = theta_deg - 360
        end
        
        local v1 = playdate.geometry.vector2D.newPolar(circle_r-10, theta_deg)
        local v2 = playdate.geometry.vector2D.newPolar(circle_r+5, theta_deg)

        local start_p = circle_center + v1
        local end_p = circle_center + v2
        gfx.drawLine(start_p.x, start_p.y, end_p.x, end_p.y)

        if label and string.len(label) > 0 then
            local font_v = playdate.geometry.vector2D.newPolar(label_radius_fudge, theta_deg)

            local text_width, text_height = gfx.getTextSize(label)
            
            local font_height_fudge = math.sin(theta_deg * DEG_TO_RAD / 2.0) * text_height
            local font_width_fudge = math.sin(theta_deg * DEG_TO_RAD) * text_width

            gfx.drawTextAligned(label, start_p.x - font_width_fudge + font_v.x, start_p.y - font_height_fudge + font_v.y, kTextAlignment.center)
        end
    end

    playdate.graphics.clear()

    local h = playdate.display.getHeight()
    local w = playdate.display.getWidth()
    local circle_r = math.min(h/2, w/2)-10

    local center_x = w/2
    local center_y = h/2
    local center_p = playdate.geometry.point.new(center_x, center_y)

    gfx.setLineWidth(2)

    gfx.drawCircleAtPoint(center_p, circle_r)
    
    local mode = axis_options[current_axis]

    if "linear" == mode then
        for i = 0.0, 359.0, 45.0 do
            local num_str = string.format("%.0f", i)
            drawTick(i, circle_r, center_p, num_str, 0)
        end
    elseif "log" == mode then
        local total_angle_range = 360
        local last_indicator = base^n_powers_to_display
        local done = false
        local next_val = 0
        local current_delta = 1
        local ticks_this_power = 0
        while not done do
            next_val += current_delta
            -- print(next_val)
            local this_angle = total_angle_range * math.log(next_val, base) / math.log(last_indicator, base)
            ticks_this_power += 1
            local show_full_value = false
            if base == ticks_this_power then
                ticks_this_power = 1
                current_delta *= base
                show_full_value = true
            end
            if 1 == next_val then
                show_full_value = true
            end
            if next_val + current_delta >= last_indicator then
                done = true
            end

            local num_str = string.format("%x", ticks_this_power)

            local label_radius_fudge = 0
            if show_full_value then
                local n_zeros = math.floor(math.log(next_val, base))
                num_str = string.format("%i", next_val)
                num_str = "1"
                for i = 1, n_zeros do
                    num_str = num_str .. "0"
                end
                label_radius_fudge = -8
            end

            drawTick(this_angle, circle_r, center_p, num_str, label_radius_fudge)
        end
    end
    
--    gfx.sprite.update()
    playdate.timer.updateTimers()

end

