local IMAGE_ID = "" -- e.g. "rbxassetid://123456789"
local IMAGE_PATH = "RainBanner.png" -- e.g. "RainBanner.png" (in executor workspace folder)
local IMAGE_URL = "" -- e.g. "https://.../banner.png"
-- Corner-grab preset: menu is 550 wide, so a 550-wide banner centers its own
-- top corners exactly onto the menu's top corners. Source is 1088x944.
-- GRAB_OVERLAP: how many px the picture slides DOWN over the window edge
-- (hands "grab" the frame). Increase if hands float above, decrease if buried.
-- Значения подобраны вручную под текущую картинку.
local BANNER_W, BANNER_H = 550, 500
local GRAB_OVERLAP = 29

local function resolve_image()
    -- restore: executor globals (getcustomasset/isfile/writefile) may be
    -- invisible to loadstring chunks by bare name — resolve via getgenv().
    local gg = (typeof(getgenv) == "function" and getgenv()) or {}
    local gca = (typeof(gg.getcustomasset) == "function" and gg.getcustomasset)
        or (typeof(getcustomasset) == "function" and getcustomasset)
    local g_isfile = (typeof(gg.isfile) == "function" and gg.isfile)
        or (typeof(isfile) == "function" and isfile)
    if IMAGE_PATH ~= "" and gca then
        local ok, asset = pcall(gca, IMAGE_PATH)
        if ok and asset then return asset end
    end
    if IMAGE_URL ~= "" and gca then
        local ok = pcall(function()
            local has = g_isfile and g_isfile("RainBanner.png")
            if not has then
                local wf = (typeof(gg.writefile) == "function" and gg.writefile)
                    or (typeof(writefile) == "function" and writefile)
                wf("RainBanner.png", game:HttpGet(IMAGE_URL))
            end
        end)
        if ok then
            local ok2, asset = pcall(gca, "RainBanner.png")
            if ok2 and asset then return asset end
        end
    end
    if IMAGE_ID ~= "" then return IMAGE_ID end
    return nil
end

local function ON_CLICK()
    -- TODO: your function, e.g.:
    -- Library:Notify("banner clicked");
end

return { initialize = function()
    local Lib = (typeof(getgenv) == "function" and getgenv().Library) or Library
    local win = Lib and Lib.PRWindow
    local holder = win and win.Holder
    if not holder then return nil end
    if holder:FindFirstChild("RainBanner") then return end

    local btn = Instance.new("ImageButton")
    btn.Name = "RainBanner"
    btn.AnchorPoint = Vector2.new(0.5, 1)
    -- restore: размеры ниже заданы в пикселях ДО масштабирования UI, поэтому
    -- пересчитываем их через Library:GetUIScale(). Раньше этого не было: при
    -- UIScale != 1 (ThemeManager/конфиг, SaveManager:LoadAutoloadConfig) баннер
    -- уезжал — картинка рисовалась в пиксельных координатах, а Holder
    -- масштабировался, и в бандле конфиг успевал примениться до инициализации.
    local scale = 1
    pcall(function()
        scale = tonumber(Lib:GetUIScale()) or 1
    end)
    if type(scale) ~= "number" or scale <= 0 then scale = 1 end
    btn.Position = UDim2.new(0.5, 0, 0, GRAB_OVERLAP * scale)
    btn.Size = UDim2.new(0, BANNER_W * scale, 0, BANNER_H * scale)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    local img = resolve_image()
    if not img then return nil end
    btn.Image = img
    btn.ScaleType = Enum.ScaleType.Fit
    btn.ZIndex = 0
    btn.AutoButtonColor = true
    -- restore: let clicks fall through to the game (camera rotate etc.).
    -- Trade-off: ON_CLICK below will NOT fire while this is false.
    -- Set back to true if you want the banner clickable again.
    btn.Active = false
    btn.Parent = holder

    btn.MouseButton1Click:Connect(function()
        xpcall(ON_CLICK, warn)
    end)

    -- restore: конфиг (SaveManager:LoadAutoloadConfig) может применить UIScale
    -- уже после нашей инициализации — тогда баннер снова разъедется. Следим за
    -- сменой масштаба и пересчитываем геометрию на ходу.
    local last_scale = scale
    task.spawn(function()
        while btn and btn.Parent do
            task.wait(0.5)
            local s = 1
            pcall(function() s = tonumber(Lib:GetUIScale()) or 1 end)
            if type(s) ~= "number" or s <= 0 then s = 1 end
            if s ~= last_scale then
                last_scale = s
                pcall(function()
                    btn.Position = UDim2.new(0.5, 0, 0, GRAB_OVERLAP * s)
                    btn.Size = UDim2.new(0, BANNER_W * s, 0, BANNER_H * s)
                end)
            end
        end
    end)
end }