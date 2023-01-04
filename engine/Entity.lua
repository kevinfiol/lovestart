local Rectangle = require 'engine.Rectangle'
local lume = require 'lib.lume'
local sodapop = require 'lib.sodapop'
local baton = require 'lib.baton'
local mishape = require 'lib.mishape'

local Entity = Rectangle:extend()

Entity.static = {
    noop = function() end
}

function Entity:new(class_name, area, opts)
    opts = opts or {}
    Entity.super.new(self, opts.x, opts.y, opts.width, opts.height)
    self.class_name = class_name
    self.area = area
    self.systems = {}
    self.dead = false
    self.sprite = nil
    self.input = nil
end

function Entity:update(dt)
    if self.sprite then
        self.sprite:update(dt)
    end

    if self.input then
        self.input:update()
    end
end

function Entity:draw()
    if self.sprite then
        self.sprite:draw()
    end

    if _G.DEBUG_BOXES then
        love.graphics.rectangle(
            'line',
            self.x,
            self.y,
            self.width,
            self.height
        )
    end
end

function Entity:destroy()
    self.dead = true
    self.area = nil

    for k, _ in pairs(self) do
        self[k] = nil
    end
end

---@param cfg table @ baton config
---@return table @ baton instance
function Entity:setControls(cfg)
    self.input = baton.new(cfg)
    return self.input
end

function Entity:loadSprite(filename, cfg)
    cfg = cfg or {}
    cfg.offset = cfg.offset or {}
    local new_fn = cfg.animated and sodapop.newAnimatedSprite or sodapop.newSprite

    -- IMPORTANT:
    -- The Entity's `width` and `height` will determine its bounding box
    -- the width and height provided to the sprite should match that of the actual sprite image
    local image = love.graphics.newImage(filename)
    local width = cfg.width or self.width
    local height = cfg.height or self.height
    local w_half = width / 2
    local h_half = height / 2
    local offset_x = cfg.offset.x or 0
    local offset_y = cfg.offset.y or 0

    -- init soda sprite
    self.sprite = new_fn(
        self.x + w_half,
        self.y + h_half
    )

    self.sprite:setAnchor(function ()
        return self.x + w_half - offset_x,
            self.y + h_half - offset_y
    end)

    -- load animations
    if cfg.animations then
        for name, animation in pairs(cfg.animations) do
            self.sprite:addAnimation(name, lume.extend({
                image = image,
                frameWidth = width,
                frameHeight = height,
                frames = {}
            }, animation))
        end

        self.sprite:switch(cfg.initial)
    end

    return self.sprite
end

function Entity:flipX()
    if not self.sprite then return end
    self.sprite.flipX = not self.sprite.flipX
end

function Entity:flipY()
    if not self.sprite then return end
    self.sprite.flipY = not self.sprite.flipY
end

function Entity:animation(animation)
    if not self.sprite then return end

    -- dont switch if animation is already playing
    if self.sprite.animation == animation then return end
    self.sprite:switch(animation)
end

-- debug methods
function Entity:schema(schema, custom_map)
    if not _G.DEBUG then return end
    local validator = mishape(schema, custom_map)

    local res = validator(self)
    if not res.ok then
        local error_string = '[mishape]: Schema Errors have occured:\n\t'
        for _, v in ipairs(res.errors) do
            error_string = error_string .. v .. '\n\t'
        end

        error(error_string)
    end
end

return Entity