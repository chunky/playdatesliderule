import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"

local gfx <const> = playdate.graphics

-- Global variable pile-on!
local default_base = 10

local base = default_base
local outer_angle = 0
local inner_angle = 0
local hair_angle = 0

function reset_settings()
    base = default_base
    inner_angle = 0
    outer_angle = 0
    hair_angle = 0
end

function myGameSetUp()

    local myfont = gfx.font.new("Fonts/Nano Sans")
    gfx.setFont(myfont)

    local menu = playdate.getSystemMenu()
    menu:addMenuItem("Reset", function() reset_settings() end)

    local myInputHandlers = {

        leftButtonDown = function()
            base = math.min(base+1, 16)
        end,

        rightButtonDown = function()
            base = math.max(base-1, 2)
        end,

        AButtonDown = function()
            outer_angle = playdate.getCrankPosition()
        end,

        BButtonDown = function()
            inner_angle = playdate.getCrankPosition()
        end,

        cranked = function()
            if playdate.buttonIsPressed(playdate.kButtonA) then
                outer_angle = playdate.getCrankPosition()
            elseif playdate.buttonIsPressed(playdate.kButtonB) then
                inner_angle = playdate.getCrankPosition()
            else
                hair_angle = playdate.getCrankPosition()
            end
        end

    }

    playdate.inputHandlers.push(myInputHandlers)

end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

myGameSetUp()

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.

function playdate.update()

    local function drawTick(angle_deg, circle_r, circle_center, label, label_radius_fudge, rotate_angle, length_factor)
        local theta_deg = angle_deg + rotate_angle
        while(theta_deg > 360) do
            theta_deg = theta_deg - 360
        end
        local theta_rad = math.rad(theta_deg)
        
        local v1 = playdate.geometry.vector2D.newPolar(circle_r-(5 * length_factor), theta_deg)
        local v2 = playdate.geometry.vector2D.newPolar(circle_r+(2 * length_factor), theta_deg)

        local start_p = circle_center + v1
        local end_p = circle_center + v2
        gfx.drawLine(start_p.x, start_p.y, end_p.x, end_p.y)

        if label and string.len(label) > 0 then
            local font_v = playdate.geometry.vector2D.newPolar(label_radius_fudge, theta_deg)

            local text_width, text_height = gfx.getTextSize(label)
            
            local font_height_fudge = math.sin(theta_rad / 2.0) * text_height
            local font_width_fudge = math.sin(theta_rad) * text_width

            gfx.drawTextAligned(label, start_p.x - font_width_fudge + font_v.x, start_p.y - font_height_fudge + font_v.y, kTextAlignment.center)
        end
    end

    -- Fill in the axes for values in range min to max
    -- Valuefunc converts values in the range 0..1 to scaled axis numbers 
    local function drawAxis(t_func, center_p, circle_r, rotate_angle, t_min, t_max, full_max_value, full_max_angle, depth)

        if 0 == depth then
            gfx.drawArc(center_p.x, center_p.y, circle_r, 0 + rotate_angle, full_max_angle + rotate_angle)
        end
        if 3 <= depth then
            return
        end

        local scaled_max_v, max_v = t_func(1.0)

        local min_angle = full_max_angle * t_func(t_min) / scaled_max_v
        local max_angle = full_max_angle * t_func(t_max) / scaled_max_v

        -- Ticks less than approx this many pixels apart aren't useful
        if circle_r * math.asin(math.rad(max_angle-min_angle)) < 10 then return end

        local last_t = 0.0
        local dt = ((t_max-t_min)/10.0)
        
        -- This is where floating point silliness kicks in
        --  Fudge everything by a substantial factor, then shrink back inside the loop
        local iee_factor = 10^(depth+3)
        local t_min_x = math.floor(t_min * iee_factor)
        local t_max_x = math.floor(t_max * iee_factor)
        local dt_x = math.floor(dt * iee_factor)

        for t_x=t_min_x, t_max_x, dt_x do
            local t = t_x / iee_factor
            local scaled_v, v = t_func(t)

            local value = scaled_v
            local value_angle = full_max_angle * value / scaled_max_v

            print("depth: " .. depth .. " Value: " .. value .. " Angle: " .. value_angle)
            drawAxis(t_func, center_p, circle_r, rotate_angle, last_t, t, full_max_value, full_max_angle, depth+1)
            
            local strlabel = nil
            if 0 >= depth then
                strlabel = string.format("%.0f", v * 10^(depth))
            end
            drawTick(value_angle, circle_r, center_p, strlabel, 0, rotate_angle, 2.0 / (depth + 2))

            last_t = t
        end
    end

    local function drawCalculator()
        local h = playdate.display.getHeight()
        local w = playdate.display.getWidth()
        
        local center_x = h/2 -- w/2
        local center_y = h/2
        local center_p = playdate.geometry.point.new(center_x, center_y)

        gfx.setLineWidth(1)

        local outer_radius = math.min(h/2, w/2)-8
        local inner_radius = math.min(h/2, w/2)-40


        local TOTAL_ANGLE_RANGE = 330

        local function func_Log(minval, maxval)
            return function(t)
                local v = playdate.math.lerp(minval, maxval, t)
                return math.log(v, base), v
            end
        end

        local function func_Lin(minval, maxval)
            return function(t)
                local v = playdate.math.lerp(minval, maxval, t)
                return v, v
            end
        end

        local f = func_Lin(0.0, base)
        -- local f = func_Log(1.0, base)
        
        drawAxis(f, center_p, outer_radius, outer_angle, 0.0, 1.0, f(1.0), TOTAL_ANGLE_RANGE, 0)
        -- addLogConstants(func_Log(1, base), center_p, outer_radius, outer_angle, TOTAL_ANGLE_RANGE)

        drawAxis(f, center_p, inner_radius, inner_angle, 0.0, 1.0, f(1.0), TOTAL_ANGLE_RANGE, 0)
        -- addLogConstants(center_p, inner_radius, inner_angle, TOTAL_ANGLE_RANGE)

        local hair_radius = math.min(h/2, w/2) + 10
        local hair_v = playdate.geometry.vector2D.newPolar(hair_radius, hair_angle)
        local hair_end = center_p + hair_v
        gfx.drawLine(center_p.x, center_p.y, hair_end.x, hair_end.y)
    end

    playdate.graphics.clear()
    drawCalculator()
--    gfx.sprite.update()
    playdate.timer.updateTimers()

end

