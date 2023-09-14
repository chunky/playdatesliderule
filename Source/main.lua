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

local axis_options = { "x", "x^2", "lin", "pi" }
local outer_axis = axis_options[1]
local inner_axis = axis_options[1]

local axis_funcs = {
    ["x"] = function(t)
        local v = playdate.math.lerp(1.0, base, t)
        return math.log(v, base), v
    end,
    ["x^2"] = function(t)
        local v = playdate.math.lerp(0.0, base^2, t^2)
        return math.log(v, base), v
    end,
    ["lin"] = function(t)
        local v = playdate.math.lerp(0.0, base, t)
        return v, v
    end,
    ["pi"] = function(t)
        local v = playdate.math.lerp(1.0, math.pi, t)
        return math.log(v, base), v
    end 
}

function reset_settings()
    base = default_base
    inner_angle = 0
    outer_angle = 0
    hair_angle = 0
    inner_axis = axis_options[1]
    outer_axis = axis_options[1]
end

function myGameSetUp()

    local myfont = gfx.font.new("Fonts/Nano Sans")
    gfx.setFont(myfont)

    local menu = playdate.getSystemMenu()
    menu:addMenuItem("Reset", function() reset_settings() end)

    menu:addOptionsMenuItem("Outer Axis", axis_options, outer_axis, function(newval) outer_axis = newval end)
    menu:addOptionsMenuItem("Inner Axis", axis_options, inner_axis, function(newval) inner_axis = newval end)

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

    local function drawTick(angle_deg, circle_r, label, label_radius_fudge, rotate_angle, length_factor, transform)
        local theta_deg = angle_deg + rotate_angle
        while(theta_deg > 360) do
            theta_deg = theta_deg - 360
        end
        local theta_rad = math.rad(theta_deg)
        
        local start_p = playdate.geometry.vector2D.newPolar(circle_r-(5 * length_factor), theta_deg)
        local end_p = playdate.geometry.vector2D.newPolar(circle_r+(2 * length_factor), theta_deg)

        local tickLine = playdate.geometry.lineSegment.new(start_p.x, start_p.y, end_p.x, end_p.y)
        transform:transformLineSegment(tickLine)
        gfx.drawLine(tickLine)

        if label and string.len(label) > 0 then
            local font_v = playdate.geometry.vector2D.newPolar(label_radius_fudge, theta_deg)

            local text_width, text_height = gfx.getTextSize(label)
            
            local font_height_fudge = math.sin(theta_rad / 2.0) * text_height
            local font_width_fudge = math.sin(theta_rad) * text_width

            local p = playdate.geometry.point.new(start_p.x - font_width_fudge + font_v.x, start_p.y - font_height_fudge + font_v.y)
            transform:transformPoint(p)

            gfx.drawTextAligned(label, p.x, p.y, kTextAlignment.center)
        end
    end

    -- Fill in the axes for values in range min to max
    -- Valuefunc converts values in the range 0..1 to scaled axis numbers 
    local function drawAxis(t_func, circle_r, rotate_angle, t_min, t_max, full_max_angle, depth, transform)

        if 0 == depth then
            -- Transforms don't work on arcs, but they do on polys.
            local arc = playdate.geometry.arc.new(0.0, 0.0, circle_r, rotate_angle, full_max_angle + rotate_angle)
            local est_px_along_edge = circle_r * 2 * math.pi * (full_max_angle / 360.0)
            local arc_poly = {}
            local n_edge_samples = 50
            for i = 0, n_edge_samples do
                local p = arc:pointOnArc(i * est_px_along_edge / n_edge_samples)
                arc_poly[#arc_poly+1] = p
            end
            local poly = playdate.geometry.polygon.new(table.unpack(arc_poly))
            transform:transformPolygon(poly)
            gfx.drawPolygon(poly)
        end
        if 10 <= depth then
            return
        end

        local scaled_min_v, min_v = t_func(0.0)
        local scaled_max_v, max_v = t_func(1.0)

        local min_angle = full_max_angle * t_min
        local max_angle = full_max_angle * t_max

        -- Ticks less than approx this many pixels apart aren't useful
        if circle_r * math.asin(math.rad(max_angle-min_angle)) < 20.0 then return end

        local last_t = t_min
        local dt = ((t_max-t_min)/base)
        
        -- This is where floating point silliness kicks in
        --  Fudge everything by a substantial factor, then shrink back inside the loop
        local ieee_factor = 10^(depth+3)
        local t_min_x = math.floor(t_min * ieee_factor)
        local t_max_x = math.floor(t_max * ieee_factor)
        local dt_x = math.floor(dt * ieee_factor)
        if 0 >= dt_x then return end

        for t_x=t_min_x, t_max_x, dt_x do
            local t = t_x / ieee_factor
            local scaled_v, v = t_func(t)

            local value_angle = full_max_angle * (scaled_v - scaled_min_v) / (scaled_max_v - scaled_min_v)

            drawAxis(t_func, circle_r, rotate_angle, last_t, t, full_max_angle, depth+1, transform)
            
            local strlabel = nil
            if 0 >= depth then
                strlabel = string.format("%.0f", v * base^(depth))
            end
            drawTick(value_angle, circle_r, strlabel, 0, rotate_angle, 2.0 / (depth + 2), transform)

            last_t = t
        end
    end

    local function drawHair(circle_r, hair_angle, transform)
        local hair_radius = circle_r + 10
        local hair_v = playdate.geometry.vector2D.newPolar(hair_radius, hair_angle)
        local hair_end = hair_v
        local hairline = playdate.geometry.lineSegment.new(0.0, 0.0, hair_end.x, hair_end.y)
        transform:transformLineSegment(hairline)
        gfx.drawLine(hairline)
    end

    local function drawCalculator(inner_radius, outer_radius, transform)

        local total_angle = 330

        local o_func = axis_funcs[outer_axis]
        drawAxis(o_func, outer_radius, outer_angle, 0.0, 1.0, total_angle, 0, transform)

        local i_func = axis_funcs[inner_axis]
        drawAxis(i_func, inner_radius, inner_angle, 0.0, 1.0, total_angle, 0, transform)

        drawHair(outer_radius + 10, hair_angle, transform)
    end

    playdate.graphics.clear()


    local h = playdate.display.getHeight()
    local w = playdate.display.getWidth()
    
    local center_x = h/2 -- w/2
    local center_y = h/2

    local main_radius = math.min(h/2, w/2)
    local outer_radius = main_radius-8
    local inner_radius = main_radius-40

    local main_width = h

    local transform = playdate.geometry.affineTransform.new()
    gfx.setDrawOffset(h/2, h/2)
    -- Draw the main one
    gfx.setScreenClipRect(0, 0, main_width, h)

    gfx.setLineWidth(1)
    drawCalculator(inner_radius, outer_radius, transform)

    gfx.clearClipRect()
    gfx.setDrawOffset(0, 0)
    gfx.setLineWidth(2)
    gfx.drawLine(main_width, 0, main_width, h)
    -- Draw a zoomed_in one on the right hand side

    gfx.setScreenClipRect(main_width, 0, w - main_width, h)

    local scale = 2.0

    local translate_focus = playdate.geometry.vector2D.newPolar(((inner_radius + outer_radius) / 2.0) * scale, hair_angle)
    if playdate.buttonIsPressed(playdate.kButtonA) then
        translate_focus = playdate.geometry.vector2D.newPolar(outer_radius * scale, outer_angle)
    elseif playdate.buttonIsPressed(playdate.kButtonB) then
        translate_focus = playdate.geometry.vector2D.newPolar(inner_radius * scale, inner_angle)
    end
    

    gfx.setLineWidth(1)
    transform:scale(scale)
    gfx.setDrawOffset(main_width + 0.5 * (w - main_width) - translate_focus.dx, h/2 - translate_focus.dy)
    drawCalculator(inner_radius, outer_radius, transform)
--    gfx.sprite.update()
    playdate.timer.updateTimers()

end

