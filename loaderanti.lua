-- ========================================================
-- LOADER ANTI (BẢN FIX LỖI)
-- ========================================================
if _G.VzNam_AntiLoaded then return end
_G.VzNam_AntiLoaded = true

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- ⚠️ BẮT BUỘC: DÁN LINK RAW CỦA FILE LOADER 1 (HOẶC CLIENT) VÀO ĐÂY
local NEXT_LOADER_URL = "DAN_LINK_RAW_LOADER_1_CUA_MAY_VAO_DAY"

local function LoadNext()
    print("[LoaderAnti] Đang tải file tiếp theo...")
    local success, err = pcall(function()
        local code = game:HttpGet(NEXT_LOADER_URL)
        -- Thử dùng load nếu loadstring bị chặn
        local func = loadstring or load
        func(code)()
    end)

    if not success then
        warn("[LoaderAnti] LỖI TẢI SCRIPT: " .. tostring(err))
        -- In thông báo lên màn hình game để mày biết
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Lỗi Loader",
            Text = tostring(err),
            Duration = 10
        })
    else
        print("[LoaderAnti] Tải file tiếp theo THÀNH CÔNG!")
    end
end

-- 1. CHỐNG AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- 2. TỰ ĐỘNG REJOIN (Bọc pcall để không làm hỏng script)
pcall(function()
    game:BindToClose(function()
        task.wait(2)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

-- 3. TỰ ĐỘNG TẢI LẠI KHI CHẾT
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(3)
    LoadNext()
end)

-- 4. CHẠY LẦN ĐẦU TIÊN
task.spawn(function()
    task.wait(1)
    LoadNext()
end)
