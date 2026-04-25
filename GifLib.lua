-- GifLib 2.3
-- Made for the delta executor.
local GifLib = {}
GifLib.__index = GifLib

local gifs = {}

local function parseSize(text)
    local w = tonumber(text:match("width:%s*(%d+)"))
    local h = tonumber(text:match("height:%s*(%d+)"))
    return w, h
end

local function split(str)
    local t = {}
    for s in string.gmatch(str, "([^,]+)") do
        table.insert(t, (s:gsub("%s+", "")))
    end
    return t
end

local function ensureFolders()
    if not isfolder("Gif") then makefolder("Gif") end
    if not isfolder("Gif/data") then makefolder("Gif/data") end
    if not isfolder("Gif/data/png") then makefolder("Gif/data/png") end
end

function GifLib:New(config)
    assert(config.Name, "Precisa de Name")

    local width, height = parseSize(config.Size or "")
    local cols = config.Cols or 5
    local sprites = config.Sprites or 1

    local urls = split(config.GifUrlSprites or "")

    ensureFolders()

    local images = {}

    for i, url in ipairs(urls) do
        local data = game:HttpGet(url)
        local path = "Gif/data/png/"..config.Name.."_"..i..".png"
        writefile(path, data)
        table.insert(images, getcustomasset(path))
    end

    local parent = config.Parent or game.CoreGui

    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.Size = config.UISize or UDim2.new(0,200,0,200)
    img.Position = config.Position or UDim2.new(0.5,-100,0.5,-100)
    img.Parent = parent

    local frameW = width / cols
    local rows = math.ceil(sprites / cols)
    local frameH = height / rows

    gifs[config.Name] = {
        ImageLabel = img,
        Frames = sprites,
        Cols = cols,
        FrameW = frameW,
        FrameH = frameH,
        Assets = images,
        CurrentSheet = 1
    }
end

function GifLib:Play(config)
    local g = gifs[config.Name]
    if not g then return warn("Gif não existe") end

    local fps = tonumber(config.FramesPorSecond) or 10
    local delay = 1 / fps

    local current = 0

    task.spawn(function()
        while true do
            local sheet = g.Assets[g.CurrentSheet]
            g.ImageLabel.Image = sheet

            local col = current % g.Cols
            local row = math.floor(current / g.Cols)

            g.ImageLabel.ImageRectOffset = Vector2.new(col * g.FrameW, row * g.FrameH)
            g.ImageLabel.ImageRectSize = Vector2.new(g.FrameW, g.FrameH)

            current += 1

            if current >= g.Frames then
                current = 0
                g.CurrentSheet += 1
                if g.CurrentSheet > #g.Assets then
                    g.CurrentSheet = 1
                end
            end

            task.wait(delay)
        end
    end)
end

return setmetatable({}, GifLib)
