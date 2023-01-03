local Enum = require 'enum'
local Entity = require 'engine.Entity'
local util = require 'engine.util'

local Player = Entity:extend()

local SPEED = 130
local WIDTH = 11
local HEIGHT = 14
local GRAVITY = 400
local JUMP_VEL = -400

function Player:new(area, x, y, opts)
    opts = opts or {}
    opts.width = opts.width or WIDTH
    opts.height = opts.height or HEIGHT
    Player.super.new(self, 'PLAYER', area, x, y, opts.width, opts.height)

    self.systems = { 'physics', 'collision' }

    self.collision = {
        class = Enum.Collision.Class.Player,
        events = {
            [Enum.Collision.Class.Wall] = util.bind(self, self.onWallCollision)
        }
    }

    self.vel = { x = 0, y = 0 }
    self.accel = { x = 0, y = GRAVITY }
    self.max_vel = { x = 200, y = 800 }
    self.drag = { x = 800, y = 800 }
    self.angle = 0
    self.angular_vel = 0
    self.jumping = false
    self.grounded = false
    self.walking = false

    self.input = self:setControls({
        controls = {
            left = { 'key:left', 'key:a' },
            right = { 'key:right', 'key:d' },
            jump = { 'key:c' }
        }
    })

    self.sprite = self:loadSprite('assets/sprite/tbone.png', {
        animated = true,
        width = 16,
        height = 16,
        offset = { x = 2, y = 3 },
        initial = 'idle',
        animations = {
            idle = {
                frames = { {1, 1, 4, 1, 0.1} }
            },
            walk = {
                frames = { {8, 1, 11, 1, 0.1} }
            },
            fall = {
                frames = { {13, 1, 13, 1, 0.1} }
            },
            jump = {
                frames = { {12, 1, 12, 1, 0.1} }
            }
        }
    })

    self:schema({
        jumping = 'boolean',
        grounded = 'boolean',
        walking = 'boolean',
        input = 'table',
        sprite = 'table',
        systems = 'table',
        collision = {
            class = 'string',
            events = 'table'
        }
    })
end

function Player:update(dt)
    Player.super.update(self, dt)

    if self.collision.touching.bottom then
        local o = self.collision.touching.bottom
        if o.class_name == 'WALL' then
            if not self.grounded then
                self.grounded = true
                self.accel.y = 0
            end
        end
    else
        if self.grounded then
            self.grounded = false
            self.accel.y = GRAVITY
        end
    end

    if self.input then
        self:move(dt)
        self:jump()
    end
end

function Player:draw()
    Player.super.draw(self)
end

function Player:move(dt)
    if self.input:down('left') then
        self.x = self.x - SPEED * dt

        if not self.sprite.flipX then
            self:flipX()
        end

        if not self.walking then
            self.walking = true
            self:animation('walk')
        end
    elseif self.input:down('right') then
        self.x = self.x + SPEED * dt

        if self.sprite.flipX then
            self:flipX()
        end

        if not self.walking then
            self.walking = true
            self:animation('walk')
        end
    end

    local stopped_walking =
        self.input:released('right') or
        self.input:released('left')
        and not (
            self.input:down('right') or
            self.input:down('left')
        )

    if stopped_walking then
        self.walking = false
        self.sprite:switch('idle')
    end
end

function Player:jump()
    if self.vel.y < 0 then
        self:animation('jump')
    elseif self.vel.y > 0 then
        self:animation('fall')
    end

    if self.input:pressed('jump') and self.grounded then
        self.vel.y = JUMP_VEL
    end
end

function Player:onWallCollision(_, side)
    if side == 'top' then
        -- nicer than setting self.vel.y to 0
        self.vel.y = self.vel.y / 6
    end

    if side == 'bottom' then
        self.vel.y = 0

        if self.input:down('left') or self.input:down('right') then
            self:animation('walk')
        else
            self:animation('idle')
        end
    end
end

return Player