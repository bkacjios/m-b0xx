love.filesystem.setRequirePath("?.lua;?/init.lua;modules/?.lua;modules/?/init.lua")

require("errorhandler")
require("util.love2d")

local notification = require("notification")

local graphics = love.graphics
local newImage = graphics.newImage

local portChangeFont = graphics.newFont("fonts/melee-bold.otf", 42)

local ffi = require("ffi")

ffi.cdef[[
typedef enum
{
    SDL_FALSE = 0,
    SDL_TRUE = 1
} SDL_bool;

SDL_bool SDL_SetHint(const char *name, const char *value);
]]

local sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C

-- Allow background input for joystick events..
sdl.SDL_SetHint("SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS", "1")

local BOXX_JOYSTICK

function love.load()
	graphics.setBackgroundColor(0, 0, 0, 0) -- Transparent background for OBS

	local joysticks = love.joystick.getJoysticks()
	for i, joystick in ipairs(joysticks) do
		local name = joystick:getName()
		notification.coloredMessage(name)
		if name == "Arduino Leonardo" then
			BOXX_JOYSTICK = joystick
			notification.coloredMessage(("Found B0XX: %s"):format(name))
			notification.coloredMessage(("Axis count: %d"):format(joystick:getAxisCount()))
		end
	end
end

local BUTTON_MAPPING = {
	[1] = "A",
	[2] = "B",
	[3] = "X",
	[4] = "Y",
	[5] = "Z",
	[6] = "L",
	[7] = "R",
	[8] = "START",
}

local BUTTONS = {
	A = 1,
	B = 2,
	X = 3,
	Y = 4,
	Z = 5,
	L = 6,
	R = 7,
	START = 8,
}

local BUTTON_PRESSED = {}

local BACKGROUND = newImage("textures/buttons/bg-t1.png")

local BUTTON_TEXTURES = {
	A = newImage("textures/buttons/A.png"),
	B = newImage("textures/buttons/B.png"),
	X = newImage("textures/buttons/X.png"),
	Y = newImage("textures/buttons/Y.png"),
	Z = newImage("textures/buttons/Z.png"),
	L = newImage("textures/buttons/LT.png"),
	R = newImage("textures/buttons/RT.png"),
	START = newImage("textures/buttons/ST.png"),
}

local ANALOG_TEXTURES = {
	UP = newImage("textures/buttons/UP.png"),
	DOWN = newImage("textures/buttons/DN.png"),
	LEFT = newImage("textures/buttons/L.png"),
	RIGHT = newImage("textures/buttons/R.png"),

	C_UP = newImage("textures/buttons/CU.png"),
	C_DOWN = newImage("textures/buttons/CD.png"),
	C_LEFT= newImage("textures/buttons/CL.png"),
	C_RIGHT = newImage("textures/buttons/CR.png"),
}

local MOD_TEXTURES = {
	MOD_X = newImage("textures/buttons/MX.png"),
	MOD_Y = newImage("textures/buttons/MY.png"),
}

function love.update(dt)
	notification.update(8, 0)
end

function love.joystickadded(joystick)
	if joystick:getName() == "Arduino Leonardo" then
		BOXX_JOYSTICK = joystick
		notification.coloredMessage("B0XX plugged in")
	end
end

function love.joystickremoved(joystick)
	if joystick:getName() == "Arduino Leonardo" then
		BOXX_JOYSTICK = nil
		notification.coloredMessage("B0XX unplugged")
	end
end

function love.joystickpressed(joystick, button)
	local map = BUTTON_MAPPING[button]
	if map then
		BUTTON_PRESSED[map] = true
	end
end

function love.joystickreleased( joystick, button )
	local map = BUTTON_MAPPING[button]
	if map then
		BUTTON_PRESSED[map] = false
	end
end

function love.wheelmoved(x, y)

end

function love.draw()
	love.drawControllerOverlay()
	notification.draw()
end

local abs = math.abs

function love.drawControllerOverlay()
	local w, h = graphics.getPixelDimensions()

	graphics.setColor(255, 255, 255, 255)

	graphics.easyDraw(BACKGROUND, 0, 0, 0, w, h)

	if not BOXX_JOYSTICK then return end

	for button, texture in pairs(BUTTON_TEXTURES) do
		if BUTTON_PRESSED[button] then
			graphics.easyDraw(texture, 0, 0, 0, w, h)
		end
	end

	local JOY_X = BOXX_JOYSTICK:getAxis(1)
	local JOY_Y = BOXX_JOYSTICK:getAxis(2)

	local C_X = BOXX_JOYSTICK:getAxis(3)
	local C_Y = BOXX_JOYSTICK:getAxis(4)

	local JOY_X_NAME, JOY_Y_NAME

	if JOY_X < 0 then
		JOY_X_NAME = "LEFT"
	elseif JOY_X > 0 then
		JOY_X_NAME = "RIGHT"
	end

	if JOY_Y < 0 then
		JOY_Y_NAME = "UP"
	elseif JOY_Y > 0 then
		JOY_Y_NAME = "DOWN"
	end

	-- I have no idea if this is correct.. but it's my best guess for now
	if (JOY_X ~= 0 and abs(JOY_X) < 0.7375) or (JOY_Y ~= 0 and abs(JOY_Y) < 0.2875) then
		graphics.easyDraw(MOD_TEXTURES["MOD_X"], 0, 0, 0, w, h)
	end

	if (JOY_X ~= 0 and abs(JOY_X) < 0.2875) or (JOY_Y ~= 0 and abs(JOY_Y) < 0.7375) then
		graphics.easyDraw(MOD_TEXTURES["MOD_Y"], 0, 0, 0, w, h)
	end

	if ANALOG_TEXTURES[JOY_X_NAME] then
		graphics.easyDraw(ANALOG_TEXTURES[JOY_X_NAME], 0, 0, 0, w, h)
	end

	if ANALOG_TEXTURES[JOY_Y_NAME] then
		graphics.easyDraw(ANALOG_TEXTURES[JOY_Y_NAME], 0, 0, 0, w, h)
	end

	local C_X_NAME, C_Y_NAME

	if C_X < 0 then
		C_X_NAME = "C_LEFT"
	elseif C_X > 0 then
		C_X_NAME = "C_RIGHT"
	end

	if C_Y < 0 then
		C_Y_NAME = "C_UP"
	elseif C_Y > 0 then
		C_Y_NAME = "C_DOWN"
	end

	if ANALOG_TEXTURES[C_X_NAME] then
		graphics.easyDraw(ANALOG_TEXTURES[C_X_NAME], 0, 0, 0, w, h)
	end

	if ANALOG_TEXTURES[C_Y_NAME] then
		graphics.easyDraw(ANALOG_TEXTURES[C_Y_NAME], 0, 0, 0, w, h)
	end
end

local FPS_LIMIT = 60

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
 
	-- Main loop time.
	return function()
		local frame_start = love.timer.getTime()

		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end
 
		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
 
			if love.draw then love.draw() end
 
			love.graphics.present()
		end
 
		if love.timer then
			local frame_time = love.timer.getTime() - frame_start
			love.timer.sleep(1 / FPS_LIMIT- frame_time)
		end
	end
end

function love.quit()
end