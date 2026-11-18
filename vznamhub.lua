-- nghiêm cấm việc ăn cắp, anti,.. 
-- VZNAM HUB V4.7 
local ok, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubv4-TongHop/refs/heads/main/loader.lua"))()
end)
-- loadstring(game:HttpGet("https://raw.gthub...vznamhub.lua"))()
if not ok then
    local msg = "❌ VzNamHub lỗi: " .. tostring(err)
    warn(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "VzNamHub",
            Text = "Lỗi tải script, thử lại hoặc báo admin!",
            Duration = 6
        })
    end)
end
