local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui

if PlayerGui:FindFirstChild("VzNamHubV4UI") then PlayerGui.VzNamHubV4UI:Destroy() end
if CoreGui:FindFirstChild("VzNamHubV4UI") then CoreGui.VzNamHubV4UI:Destroy() end
if PlayerGui:FindFirstChild("VzNamHubCoverUI") then PlayerGui.VzNamHubCoverUI:Destroy() end
if CoreGui:FindFirstChild("VzNamHubCoverUI") then CoreGui.VzNamHubCoverUI:Destroy() end
pcall(function()
    if gethui then
        local h = gethui()
        if h:FindFirstChild("VzNamHubV4UI") then h.VzNamHubV4UI:Destroy() end
        if h:FindFirstChild("VzNamHubCoverUI") then h.VzNamHubCoverUI:Destroy() end
    end
end)
if SoundService:FindFirstChild("VzNamHubSound") then SoundService.VzNamHubSound:Destroy() end

local Connections = {}
local function Track(conn) if conn then table.insert(Connections, conn) end return conn end
local function DisconnectAll() for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end Connections = {} end

local State = { ThemeBase = Color3.fromRGB(15, 16, 22), StrokeMode = "Solid", StrokeColor = Color3.fromRGB(0, 191, 255), Volume = 0.5, SoundId = "1837879082", SelectedScript = nil, IsAutoLoad = false, CurrentConfig = "Default", Transparent = 0, OuterTransparent = 1, Language = "VI", Background = "Normal", BackgroundUrl = nil, TextColor = Color3.fromRGB(255,255,255), TextMode = "Solid" }
State.FontId = "Default" -- kiểu chữ đang chọn (Default = giữ font gốc)

-- [MỚI] CÔNG TẮC TRƯỢT: chấm tròn trắng lướt ngang từ trái qua phải (và ngược lại), nền xám chuyển dần sang xanh
State.SlideToggle = function(btn, dot, on, posOn, posOff)
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(dot, info, {Position = on and posOn or posOff}):Play()
    TweenService:Create(btn, info, {BackgroundColor3 = on and Color3.fromRGB(50,200,50) or Color3.fromRGB(60,65,75)}):Play()
end

-- [MỚI] PHỤ ĐỀ + ICON NHẤP CHUỘT cho các chức năng
State.ClickIcons = {}
State.RowHints = {
    ["Anti AFK (treo không văng)"] = "Bật để không bị văng khi đứng yên",
    ["Tự bật lại VzNamHub khi vào game"] = "Bật để hub tự chạy lại khi dịch chuyển",
    ["Auto join lại khi bị văng"] = "Bật để tự vào lại khi bị văng",
    ["Auto verify key premium"] = "Bật để tự nhập key premium đã chọn",
    ["Ngôn ngữ / Language"] = "Ấn bên phải để đổi ngôn ngữ",
    ["Màn trắng (AFK)"] = "Bật để phủ màn trắng (treo AFK)",
    ["Màn đen (AFK)"] = "Bật để phủ màn đen (treo AFK)",
    ["Khung log nổi"] = "Bật để hiện khung log nổi",
    ["Thanh tiện ích nổi"] = "Bật để hiện FPS, Ping, RAM nổi",
}
State.GetRowHint = function(text) return State.RowHints[(tostring(text):gsub("^[^%a]+", ""))] end
-- nút bấm: chữ chức năng ở trên, phụ đề giải thích ở dưới, icon 👆 bên phải
State.AddHint = function(btn, sub, height, noIcon)
    if not btn or not sub then return btn end
    height = height or 30
    btn.Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset, 0, height)
    btn.TextYAlignment = Enum.TextYAlignment.Top
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    local pad = btn:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", btn)
    local right = noIcon and 6 or 20
    pad.PaddingTop, pad.PaddingRight = UDim.new(0, 3), UDim.new(0, right)
    local left = pad.PaddingLeft.Offset
    local s = Instance.new("TextLabel", btn)
    s.Name, s.BackgroundTransparency, s.ZIndex = "Hint", 1, btn.ZIndex
    s.Size, s.Position = UDim2.new(1, 0, 0, 12), UDim2.new(0, 0, 1, -14)
    s.Text, s.TextColor3, s.TextSize, s.Font = sub, Color3.fromRGB(175, 180, 190), 8, Enum.Font.Gotham
    s.TextXAlignment, s.TextTruncate, s.TextStrokeTransparency = btn.TextXAlignment, Enum.TextTruncate.AtEnd, 0.6
    if not noIcon then
        local ic = Instance.new("TextLabel", btn)
        ic.Name, ic.BackgroundTransparency, ic.ZIndex = "ClickIcon", 1, btn.ZIndex
        ic.Size, ic.Position, ic.Text, ic.TextSize = UDim2.new(0, 14, 0, 14), UDim2.new(1, right - 21, 0.5, -7), "👆", 10
        local im = Instance.new("ImageLabel", btn)
        im.Name, im.BackgroundTransparency, im.ZIndex, im.ScaleType, im.Visible = "ClickImg", 1, btn.ZIndex, Enum.ScaleType.Fit, false
        im.Size, im.Position = UDim2.new(0, 12, 0, 12), UDim2.new(1, right - 19, 0.5, -7)
        if State.ClickAsset then im.Image = State.ClickAsset; im.Visible = true; ic.Visible = false end
        table.insert(State.ClickIcons, {im, ic})
    end
    return btn
end
-- hàng có công tắc/thanh kéo: thêm phụ đề dưới tiêu đề (rightPad = chừa chỗ bên phải cho công tắc/thanh)
State.RowHint = function(frame, title, sub, rightPad, height)
    if not frame or not title or not sub then return end
    height, rightPad = height or 31, rightPad or 50
    frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, height)
    title.Position = UDim2.new(title.Position.X.Scale, title.Position.X.Offset, 0, 2)
    title.Size = UDim2.new(title.Size.X.Scale, title.Size.X.Offset, 0, 14)
    local s = Instance.new("TextLabel", frame)
    s.Name, s.BackgroundTransparency = "Hint", 1
    s.Size, s.Position = UDim2.new(1, -(title.Position.X.Offset + rightPad), 0, 12), UDim2.new(0, title.Position.X.Offset, 0, 16)
    s.Text, s.TextColor3, s.TextSize, s.Font = sub, Color3.fromRGB(175, 180, 190), 8, Enum.Font.Gotham
    s.TextXAlignment, s.TextTruncate, s.TextStrokeTransparency = Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd, 0.6
end

-- [MỚI] ICON NHẤP CHUỘT (ảnh nhúng sẵn, tự ghi ra file rồi dùng getcustomasset; thiếu hàm thì dùng emoji 👆)
do
    local CLICK_B64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAATiElEQVR42tVba3RUVZb+zrmPqkqqkvAICQkBQniGRhSiJDxM6AABGmfUWAExPlhogMZWluJ71lTKsXV6OQ4C3Y7hIfaAwEp46XJoArgI3bztCLYYB1EgQQKRQCopUlW37r1nz4+umxUFEkSS9Oy1zp97T+695zt7f3t/+1QYboEREWeMCQBgjGHXrl0TfD7fZF3XM4PBYJqmaRJjzMYYC0VFRRmMsc+cTufulJSUPaNHj/4GAEpLSyW32y0YY4RONPZzH1BaWioVFBSYRMQ+/PDDh69cuTI/GAxmKIqiSJIEAOCcg4jAGINhGCAiCCHAGLvodDp3uVyupVOnTj0CAB6Ph3u9XvH/AgC32y2VlZWZu3btyqqrq1ui6/oYAJAkCbquX+Gcf8oYO6EoynlFUaBpGhdCDBFC3GaaZrqiKDBNEwB0u91eMnjw4H/JyMhotED9hwbA4/HIXq/X2Lp1a1FDQ8NyIYQqSRJkWf5fl8u1sl+/flvuuOOOM9cJGXn37t2ZDQ0Ns/1+/8NE5JQkCYqiVMXHx8/My8s73lkgsJ+5+NcCgcArjY2NsNvtzTExMd78/Pw/MMYCrT3kGu9kAAQAHDlyZMipU6d+FwgE/tk0Tdjt9u979ux577Rp0w52BgjsZmN+y5YtT/r9/uXBYBAul+t8YmLirNzc3D97PB5eVVXFrIUfP368e01NTR/TNJnD4dBzc3NPMcZCAFBSUqLMmzdPB4AtW7Y84/P53tJ1HVFRUb7+/fuPnDBhQk1HcwK7Gbbfs2dPxpkzZw6Fw2HJbrefTU1NnXT33Xd/vWbNGvucOXNCRKRs27bt0ebm5kJN04YahtGLiJgkSbqqqjU2m+0vLpdr1a9+9av9rYHYvHnzPJ/P965pmlBV9eCjjz56d1lZGXWkF/CfMrm4uBhEJFdXV/+XEEJSVTXgdDrvab34rVu3jl27du2BpqamlaZpZquqmuBwOJjT6YTNZlM452mapj1WV1e3r6ysrOzw4cM95s2bpy9dutSWn59fEhUV9YYsywCQVVpa+puCggKztLRU6nIP2LNnjzxx4kRj8+bND/n9/nWmacLhcDw1e/bs5du3b7dNnz5d27Rp00y/3//fpmmqjDFwzj8joo969ux5vEePHlptba2rsbFxHOd8JoCeAGC3208MHjx4SkZGRo3H41GLi4tp3bp1RzRNGwng8ogRI4aMGTPmciSNUpd5QEVFhSAiyefzPc0YI8ZY1YMPPviHkpISZfr06drOnTtzm5ubN2iapnLOfS6Xa96cOXNGz50711tZWbl19erVnxFR6eOPP/7knDlzBjscjg1EhGAwOKSqqmpzTU2NIykpiRhjekJCwiIAQpKkHmfPnl0AgCoqKqQuC4HS0lLJ6/WK8vLyMQDuBMBiY2P/wBgT3bp1E3V1dc7z58+v1DQNNpstGBMT4y4oKFjh8Xgyx40b9+fVq1fXl5eXn3vmmWfqx44du6u4uDj5wQcfnB0dHf2fRAQAGYcPH/63efPm6SUlJcqUKVP2KopyiHNOfr/fTURSTk6O2WUAxMfHMwC4dOnSFFVVEQ6HGxMSErYRESsoKDD379//IIBURVFYdHT0Cw888MDuRYsWFa1cuXLvvn37Jnz33Xfdzp07h++++y7u0KFDkzZs2HDklVdemTRr1qxnVVXdbxgGNTY2PrFv376koqIiAwBzOBwfEBETQqR/8sknwxljRES8SwB45513CADC4fAdjDHY7fZvJkyYUFtcXMyIiDU0NMyKxOff3G7375cuXZq+bdu2t2tra9X4+Hjj9ddfpx07dsDj8ZDL5dJPnjzp2LRp09qtW7fGJSYmLgZAqqrGfP/999ZzKD4+/i+6rpuSJMl1dXXpERLuEgBYWVmZICJGRCkAIMvycSJiXq9XHDlypLtpmncAYKZprmOM0YYNG4rq6uocTqdTLy0tlV966SWWl5eH4uJitmLFCoVzbpw/fz5x2bJl90+ZMuWQaZpfSpJEjY2Nt0XSLUtLS/tWCFGjKAokSRoNADk5OZ0fApEYJQCxAJJN04SmaV9FruHixYspAGKEEIiOjv6KMYampqZJwWCQ7rvvPp6Tk4NgMIhwOIxwOIyCggKMHj0afr+f/H7/LwEwSZL+xjlnpmn2j+w069u3b1BV1YbIN/SOEHHX1QF1dXU2ACpjDABaCMlmszmkiOxzuVxERNB1PQYAGzJkCCMicM5hKUMA6NOnDyMiFhcXN/jv66MrkXnRAOD1eokxBsaY9X0dJpHbBSCyYCQkJDQyxho452CMOa37gUDgomEYIcYYLly4ILWu8yOS96pnRhQgdF1HZF5yZF59RGswIQQPh8OcMQYiCnRlJUiRRWmMsXoigiRJwyx8MjMzL8iy7GOMQZblXM45SZIktwbvqpdybgGhEZFNCHGHaZqkKMrXEQ8Q+/btiwWQKIQAEX3TZRwQ2RGJMUamaR7jnFMwGBxCRMztdvOEhIQriqLsFULANM3CQCAwyDAMra3nRUpdhMPhK1999dVkSZKSNU1jNpvtT9ac+vr6YZIkxYfDYQD4W4RvuqYStJC32WwHwuEwI6Lh27dv/0VpaamIhMd7QggA6P7ll18OvXLlSlObL414gBBCNDY2Ou12u+Ccn7jzzjsrrLq/ubk5T1EURkSNAwYMOAYAX375ZdcAUFFRIQAgOTm5wjTNgKqqcmNj41zGGHk8HjUvL2+nJEkbY2JiIMtyoD3SsgAIBAK6EMJwOBw8Njb2hdTU1FCE9dVQKPSQEII453uzsrLqOkoW3xAAXq9XlJaWShMnTjyjKMrHABAKhR47cOBAMgDD4/HII0aMeMo0zepAIBB/vdj/cQgYhsEZYz2bmprW33///R8WFRVFFRQUmJs2bZrPOU8jIuZ0Ot8FgOHDh7OuIsEfWGxs7L8bhmGYphl75syZFV6vVwwfPpyPGjXqYnx8fG6/fv0+l2XZ1qqGuK4HREVFdc/Kylo7d+7chxhjWLFiRYCI7M3NzV6bzQbO+bEHHnhgt1VydykAli6/9957j0ZHR6+ONDmnb9my5cWCgoLw0qVLbbm5ud+mpKR8paqq/UaeKYTAwYMHe+fl5T0/YsSI340ZM+a3Cxcu/KfRo0ffZ7fb/xQVFfUCY0wvKyvj+EcwImIej4efPn067v333z+xYsUKeu+998TWrVvnWj1AIrKnpaWdAkCvvvqqSUQUCoXIMAzSNI2IiB555BECQMnJyY0DBw7UoqOjCQDJskzdunWjtLS0T95+++1fAEBRUZECwKovOADJ7XZLXRICVkMiNTXV17Nnz3ttNttlXdfZ5cuXV23ZsuW3paWlpKpqyKrg2uMCn88X880336gAjFGjRhn9+vUzGhoazJqaml8uW7Zsh8fjSVyxYoXOGDPtdjspiiI452ak38i7hAMsQpwxY8ZXsbGxeXa7/YJpmmhoaHh5/fr1+2tqalI1TQu0xQEWCWqaRtnZ2XT48GH58OHD8rFjx+Rly5ZJkiSFa2trkysqKn5bUlIy9q677lo1ZMiQ/YMGDdqbmZn5/osvvjhJlmXRqsPc+Wbl6127dg1Yt27dgVWrVtH69eupsrLynsTExM/aCoHHH3+cAFCPHj3o22+/JSKicDhMhmEQEdGCBQsIgEhMTNRTUlJIlmWKpFbinFNSUhLl5eW9qaoqRo8erQCQrfBoFS4d4wE/JsXJkyefeuihhybExMS8IMtyoxCCtxcC1vVBgwahf//+0HUdjDHoug4hBMaPHw8ArKmpKfns2bPo1auX8dhjj5lz5swxe/fubdTW1hp//etfF0+fPv25yspKnTFmWOEREWrk8Xg6hzhbv6iysrIfESWlpqaebMsD5s+fTwAoMzOTDMNoGaFQiIiIPvjggxZSzMrKourqarKsurqaxo4dawIw0tLSLq9atcqdlZX17sCBA/ekpqZumT59+r8ePXo07se/rcNPmDwejwwAiqIgLS3t22sBYC3w17/+dQsAME2zTQD27NlDREQCgQAFAgEiIqqoqCBJkigmJob69u1LiqK0hEh0dDQNGDDgpMfjGXsjLLtVCJHX6zU9Hg8Ph8Mqi/j49UIgohvaNZfLhZSUFAghIMsyZFmGEAJJSUlwOBzQNA01NTXC5XIZhYWFZl5enhkKhcLV1dUDN27cuPHAgQPdW6nZDgWgJUNEegFtagFVVW+07oAQoqVytCpI65oQAgkJCby8vFxeu3attGPHDqmkpETlnOu1tbUpL7/8ciEAys7OljoFAOu7hRB0I2nwBmuPa17jnEPXdTzxxBPIyMhAIBCAruuYO3cuxo0bx/x+P50/f36KLMvYu3ev6EwA2jVZlsE5/8HOXm/R1wPRmtOvXz8IISBJEogIRISRI0cyACwUCiW011LrCACiZVlW2kuDQggEAoFrzrFivnUf8XoAtA4R61coUVFRVsdJlnVdl06CrS0kItGWCszLy8OwYcOQn5/fAkZrUxQFhmHA7/dDUZQ2dwPDMK66b7fbOQDExcUlALBFGq/X3A35JwU3EysuLmZVVVUtD0tPT6fi4mJqtZNC13VxLffknMM0TUycOBHHjh2DqqowTbMFGEmSIITAlClT8Pzzz6N///5ISUlpmWO5eFxcHBwOB3w+H1JTU1s8wnqfw+GwvONWdJAiBUV73iJH1KDct2/fb65VB1hD13UyTZN0Xf/BdWu0th/f03WdhBB09OhR2rlz5zXriDfffFMAoEGDBp0jIocVNTfrAczr9QpZlrFt27bEdevW9amvr0/inAtZli/n5eX5nnrqqdOSJAXLysoAQGKMye0x+/Va5pFOEUzTBGPsKh5gjME0Tdx+++0/aLG3tlZ/w9rbuPYA4LIsi+Li4syPPvroJU8+eXdTU1NcOBxuSUXHjx9HSUnJqYyMjIMxMTHrARzgnOvtyeH27rWVKi3dEGnRX5drZFnm7a1RbsvtX3vtNTF//vxHVq5c+d7Zs2elCFlRVFSUIIyxNjc3MwBDAAzo3r37Q7fffvspTdO6R2KwwwjAag6iR8hSNSUiJhFxAD2IaGZxKw5ARTAMw8UYo2jYhSkMEyaYYCRJEhhjvbs8dRIAMBgM2gCoNpvNtNlsRCzHLoeDIvCt3rt3L2zdurWNgDuKBcCoUKAZgBQIBGAYBgDsGxwaogAAPzgqzp8/f1X7TQihBgaDa6mpqamIiaCSJEFRFHA+LgnVIghdVRXk5eV1WqrdswZoZGRkJWKy5ZoEAOZkuViTJ04qI0wmTAwkAEIIABhAbEgM8U/ixEIPjrSKTpUBkJFtfEJgvXJsGgCuyDFaRcaVxL1BmAxEMNEEMwA3gYEOQUCEZvNCCCEUxHZPxJrAUGVJbo48fT/Mw0bKRhoZ3+i7Cv9DnU4ZvjETo4vR2k7ZVu8BBqBycDAdAKRSOUBFARw4AAKRYcTjRgWIpAMVQHCAV21Dn7q5kM3SR5wmmVA7xCVU2YlmzVMwzW3Kbhi0LhfvHWjQ7jAwsQtlSKOJmPiaXBnk3Ym6c7oapOAFYBQJAM73BzGwTJU/ZCT4BPKR0lH1EbVlZxQ8hNwMOH5WKHCOFgl7EcYj5EmDZjk8D+PD5/EnJT7OuwPzrjuARJGuXGTO7tIQoZeP3wZZbQYC7ELBZpd3A5CRs5nA9LUj6Dhm8D6PGM3VR/DvPPjwYHFGFVAyBt6pO7aH8oPb2Jps3I8HFLKNN+nQ6xT9zaNgcYAO3DcvlzbEBZEH5htUzcFV51A6W07ZQBXyFfeJ4Rj+HHQrqYOpb1vFHw9GP17qBn+uNRHEiANcB6GhBRlhHhqFiqf5PjWwF7pZNjwo7e9R7vEmG3tTM2mzeCAL3yBjQLWAAGHSDHW4AqBbQ0qlz3I51i+Qr5XlZhJX+ZR8dEAzyTV6u3Rf9TgNmTT4CmaM3ek5R5X8KZXhY6eVY1dWrBQJYAAQTGBWBOnKEnzgBA7bsK/MCUVLq5q6ELfCC/ScEQtq7C3S5l5GwSpqk+g9fN+W6YQbU0GCZLjwBe+6JpS2wEaOKRjzRzIz5nZ2OrCFo7e10nQ0uUCwYFXvq2ZqE6sO6LCmCZjd0TnXMvZkI3fpRiZ77k7cSEahO1mTcSvAH8cWT/YNk0Mq1d38qS8vRFS3lMQdLM4Q5k3H5EJsd2PFfXYj9RkwIbyFdLz6l5tGnsZXzu+6pLgW0f64F9IJ5T8ZkQz3mYR1qvX5ucHjNIx5cm4h1k1Kz4X1uGq+8M4n0Lb7C8fKgm3oFgA3+Qlb2CY8z3Tn7bC8jN1m+Rgs0mM0S8iUPNmRKQHk5l5l8Rm0P0y9cNQoCQAAAAASUVORK5CYII="
    local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local function b64decode(data)
        local lookup = {}
        for i = 1, 64 do lookup[B64:sub(i, i)] = i - 1 end
        local out, bits, nbits = {}, 0, 0
        for c in data:gmatch(".") do
            local v = lookup[c]
            if v then
                bits = bits * 64 + v; nbits = nbits + 6
                if nbits >= 8 then
                    nbits = nbits - 8
                    local pw = 2 ^ nbits
                    local byte = math.floor(bits / pw)
                    bits = bits - byte * pw
                    out[#out + 1] = string.char(byte)
                end
            end
        end
        return table.concat(out)
    end
    task.spawn(function()
        local ok = pcall(function()
            local getasset = getcustomasset or getsynasset
            if not (writefile and getasset) then error("thiếu hàm") end
            writefile("VzNamHub_click.png", b64decode(CLICK_B64))
            State.ClickAsset = getasset("VzNamHub_click.png")
        end)
        if ok and State.ClickAsset then
            for _, pr in ipairs(State.ClickIcons) do
                if pr[1].Parent then pr[1].Image = State.ClickAsset; pr[1].Visible = true; pr[2].Visible = false end
            end
        end
    end)
end

local OuterPieces = {}
local function Corner(parent, radius) local c = Instance.new("UICorner", parent); c.CornerRadius = radius or UDim.new(0, 5); return c end
local AllUIStrokes = {}
local function Stroke(parent, color, thickness) local s = Instance.new("UIStroke", parent); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Color = color or State.StrokeColor; s.Thickness = thickness or 1; table.insert(AllUIStrokes, s); return s end
local ThemedElements = {}
local ApplyElementAlpha
local ApplyTextColor, RelocalizeAll, ApplyFont, SetFontById -- gán ở cuối file (đa ngôn ngữ + màu chữ + kiểu chữ)
local function RegTheme(el, t) table.insert(ThemedElements, {Element = el, Type = t}); if ApplyElementAlpha then ApplyElementAlpha(el) end return el end
local function CreateCustomButton(parent, text, themeType)
    local btn = Instance.new("TextButton", parent); btn.BackgroundColor3 = Color3.fromRGB(70,15,50); btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Text = text; btn.TextColor3 = Color3.fromRGB(255,255,255); btn.TextSize = 9; btn.Font = Enum.Font.Gotham; btn.TextXAlignment = Enum.TextXAlignment.Left
    local padding = Instance.new("UIPadding", btn); padding.PaddingLeft = UDim.new(0, 5)
    Corner(btn); Stroke(btn, Color3.fromRGB(0,191,255), 1); RegTheme(btn, themeType)
    Track(btn.MouseButton1Click:Connect(function()
        local t = btn.Text
        if t:find("^%s*↓") or t:find("^%s*→") then return end
        if _G.__vznam_log then _G.__vznam_log("INFO", "Bấm nút: " .. (t:gsub("^%s+", ""))) end
    end))
    return btn
end

-- LOGGING
local LogColors = { INFO = Color3.fromRGB(200,200,210), SUCCESS = Color3.fromRGB(85,255,85), WARNING = Color3.fromRGB(255,200,50), ERROR = Color3.fromRGB(255,85,85) }
local LogTags = { INFO = "[INFO]", SUCCESS = "[THÀNH CÔNG]", WARNING = "[CẢNH BÁO]", ERROR = "[LỖI]" }
local nhatKiScroll
do
local LogHistory = {}
local MAX_LOG_LINES = 300
-- Các log bắt đầu bằng những cụm này sẽ KHÔNG hiện trong nhật ký (thêm bớt tùy ý)
local LOG_IGNORE = {"Mở mục:", "Đóng mục:", "Mở menu", "Ẩn menu", "Bấm nút:", "Mở ô tìm kiếm", "Đóng ô tìm kiếm", "Đổi kích thước menu", "Tìm tab:", "Tìm chức năng:"}
local function AddLogLine(scroll, text, color)
    if not scroll or not scroll.Parent then return end
    local labels = {}
    for _, child in ipairs(scroll:GetChildren()) do if child:IsA("TextLabel") then table.insert(labels, child) end end
    if #labels >= MAX_LOG_LINES then labels[1]:Destroy() end
    local logLabel = Instance.new("TextLabel", scroll); logLabel.Size, logLabel.AutomaticSize = UDim2.new(1, -4, 0, 0), Enum.AutomaticSize.Y; logLabel.BackgroundTransparency = 1; logLabel.Text, logLabel.TextColor3, logLabel.TextSize = text, color, 10; logLabel.Font, logLabel.TextXAlignment, logLabel.TextWrapped = Enum.Font.Code, Enum.TextXAlignment.Left, true
    task.defer(function() if scroll and scroll.Parent then scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y) end end)
end
_G.__vznam_clearHistory = function() LogHistory = {} end
_G.__vznam_replayLogs = function(scroll) for _, h in ipairs(LogHistory) do AddLogLine(scroll, h[1], h[2]) end end
_G.__vznam_log = function(status, message)
    local m = tostring(message)
    for _, p in ipairs(LOG_IGNORE) do
        if m:sub(1, #p) == p then return end
    end
    local tag = LogTags[status] or "[INFO]"; local color = LogColors[status] or Color3.new(1,1,1); local text = string.format("[%s] %s %s", os.date("%H:%M:%S"), tag, m)
    table.insert(LogHistory, {text, color}); if #LogHistory > 500 then table.remove(LogHistory, 1) end
    AddLogLine(nhatKiScroll, text, color); AddLogLine(_G.MiniLogScroll, text, color)
end
end

-- SAFE LOAD
local ALLOWED_HOSTS = { "raw.githubusercontent.com", "gist.githubusercontent.com", "github.com", "api.luarmor.net", "fyycommunity.my.id", "id.tomroblox.com", "scriptblox.com", "senahub.xyz", "luaprotect.dev", "getcodium.xyz" }
local function IsUrlAllowed(url) if typeof(url) ~= "string" then return false end local host = string.match(url, "^https?://([^/]+)"); if not host then return false end for _, h in ipairs(ALLOWED_HOSTS) do if host:lower() == h or host:lower():sub(-(#h + 1)) == "." .. h then return true end end return false end
local function SafeLoad(url, scriptName)
    scriptName = scriptName or "Script"; _G.__vznam_log("INFO", scriptName .. " - Đang tải...")
    if not IsUrlAllowed(url) then _G.__vznam_log("ERROR", scriptName .. " - Host bị chặn!"); return false end
    local ok, source = pcall(function() return game:HttpGet(url, true) end); if not ok or not source then _G.__vznam_log("ERROR", scriptName .. " - Tải thất bại!"); return false end
    _G.__vznam_log("INFO", scriptName .. " - Đã tải " .. #source .. " ký tự, đang biên dịch..."); local executor_load = loadstring or load; local ok2, fn = pcall(executor_load, source); if not ok2 or not fn then _G.__vznam_log("ERROR", scriptName .. " - Lỗi cú pháp!"); return false end
    local ok3, err = pcall(fn); if not ok3 then _G.__vznam_log("ERROR", scriptName .. " - Lỗi Runtime: " .. tostring(err)) else _G.__vznam_log("SUCCESS", scriptName .. " - ✅ Quá trình tải thành công!") end
    return ok3
end

-- ẢNH TÙY CHỈNH CHO NÚT BẬT/TẮT MENU VÀ LOGO GÓC TRÁI
local IconCfg = {
    OpenButton = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/main/IMG_20261024_125441.jpg",
    Logo = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/main/IMG_20261024_125441.jpg",
}
function ApplyIconImage(imgLabel, textObj, source, file)
    if type(source) ~= "string" or source == "" then return end
    local function show(id) imgLabel.Image = id; imgLabel.Visible = true; if textObj then textObj.Text = "" end end
    if source:match("^%d+$") then show("rbxassetid://" .. source) return end
    if source:match("^rbxassetid://") then show(source) return end
    task.spawn(function()
        local ok, err = pcall(function()
            if not (writefile and getcustomasset) then error("Executor không hỗ trợ writefile/getcustomasset") end
            writefile(file, game:HttpGet(source))
            show(getcustomasset(file)); _G.__vznam_log("SUCCESS", "Đã tải ảnh icon: " .. file)
        end)
        if not ok then _G.__vznam_log("ERROR", "Không tải được ảnh icon: " .. tostring(err)) end
    end)
end

-- ROOT UI
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "VzNamHubV4UI"; ScreenGui.DisplayOrder = 999999; ScreenGui.ResetOnSpawn = false; ScreenGui.Parent = PlayerGui
pcall(function() if gethui then ScreenGui.Parent = gethui() elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui end end)

local CoverGui = Instance.new("ScreenGui"); CoverGui.Name = "VzNamHubCoverUI"; CoverGui.DisplayOrder = 999998; CoverGui.IgnoreGuiInset = true; CoverGui.ResetOnSpawn = false; CoverGui.Parent = PlayerGui
pcall(function() if gethui then CoverGui.Parent = gethui() elseif syn and syn.protect_gui then syn.protect_gui(CoverGui); CoverGui.Parent = CoreGui end end)
local WhiteScreen = Instance.new("Frame", CoverGui); WhiteScreen.Size, WhiteScreen.Position, WhiteScreen.BackgroundColor3, WhiteScreen.BorderSizePixel, WhiteScreen.Visible = UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(255,255,255), 0, false
local BlackScreen = Instance.new("Frame", CoverGui); BlackScreen.Size, BlackScreen.Position, BlackScreen.BackgroundColor3, BlackScreen.BorderSizePixel, BlackScreen.Visible = UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(0,0,0), 0, false

State.Ld = {}
-- MÀN HÌNH LOADING (giữa màn hình): VzNamHub v4.6 : Tổng Hợp + thanh load 1 -> 10 rồi mới mở menu
State.Ld.Frame = Instance.new("Frame", CoverGui); State.Ld.Frame.Name = "VzNamLoader"
State.Ld.Frame.AnchorPoint, State.Ld.Frame.Position, State.Ld.Frame.Size = Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, 440, 0, 170)
State.Ld.Frame.BackgroundColor3, State.Ld.Frame.BorderSizePixel, State.Ld.Frame.ZIndex = Color3.fromRGB(15, 16, 22), 0, 50
do local c = Instance.new("UICorner", State.Ld.Frame); c.CornerRadius = UDim.new(0, 16) end
do
    local s = Instance.new("UIStroke", State.Ld.Frame); s.Color, s.Thickness, s.Transparency = Color3.new(1, 1, 1), 2, 0.2
    local g = Instance.new("UIGradient", s)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 140, 190)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(105, 85, 190)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(185, 85, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 140, 190)),
    })
    State.Ld.StrokeGrad = g
    Track(RunService.RenderStepped:Connect(function() if g.Parent then g.Rotation = (tick() * 40) % 360 end end))
    local bgG = Instance.new("UIGradient", State.Ld.Frame)
    bgG.Color, bgG.Rotation = ColorSequence.new(Color3.fromRGB(18, 20, 34), Color3.fromRGB(42, 22, 62)), 45
    State.Ld.Frame.BackgroundColor3 = Color3.new(1, 1, 1)
end
State.Ld.Title = Instance.new("TextLabel", State.Ld.Frame)
State.Ld.Title.BackgroundTransparency, State.Ld.Title.Size, State.Ld.Title.Position = 1, UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 18)
State.Ld.Title.Text, State.Ld.Title.TextColor3, State.Ld.Title.TextSize, State.Ld.Title.Font, State.Ld.Title.ZIndex = "VzNamHub v4.6 : Tổng Hợp", Color3.new(1, 1, 1), 26, Enum.Font.GothamBold, 51
State.Ld.Sub = Instance.new("TextLabel", State.Ld.Frame)
State.Ld.Sub.BackgroundTransparency, State.Ld.Sub.Size, State.Ld.Sub.Position = 1, UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 66)
State.Ld.Sub.Text, State.Ld.Sub.TextColor3, State.Ld.Sub.TextSize, State.Ld.Sub.Font, State.Ld.Sub.ZIndex = "Đang load... 0/10", Color3.fromRGB(225, 230, 245), 18, Enum.Font.GothamBold, 51
State.Ld.BarBg = Instance.new("Frame", State.Ld.Frame)
State.Ld.BarBg.Size, State.Ld.BarBg.Position, State.Ld.BarBg.BackgroundColor3, State.Ld.BarBg.BorderSizePixel, State.Ld.BarBg.ZIndex = UDim2.new(1, -50, 0, 20), UDim2.new(0, 25, 0, 112), Color3.fromRGB(40, 42, 55), 0, 51
do local c = Instance.new("UICorner", State.Ld.BarBg); c.CornerRadius = UDim.new(0, 10) end
State.Ld.Fill = Instance.new("Frame", State.Ld.BarBg)
State.Ld.Fill.Size, State.Ld.Fill.BackgroundColor3, State.Ld.Fill.BorderSizePixel, State.Ld.Fill.ZIndex = UDim2.new(0, 0, 1, 0), Color3.fromRGB(0, 191, 255), 0, 52
do local c = Instance.new("UICorner", State.Ld.Fill); c.CornerRadius = UDim.new(0, 10) end
do
    State.Ld.Fill.BackgroundColor3 = Color3.new(1, 1, 1)
    local fg = Instance.new("UIGradient", State.Ld.Fill)
    fg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 191, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 110, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 105, 180)),
    })
    local tg = Instance.new("UIGradient", State.Ld.Title)
    tg.Color = ColorSequence.new(Color3.fromRGB(0, 220, 255), Color3.fromRGB(255, 120, 190))
end

local function ShowToast(message)
    _G.__vznam_log("INFO", "Thông báo: " .. tostring(message))
    local toast = Instance.new("TextLabel", ScreenGui); toast.Size, toast.Position = UDim2.new(0, 280, 0, 36), UDim2.new(0.5, -140, 1, 0); toast.BackgroundColor3, toast.BackgroundTransparency = Color3.fromRGB(45, 180, 45), 0.1; toast.Text, toast.TextColor3, toast.TextSize = message, Color3.fromRGB(255, 255, 255), 12; toast.Font, toast.ZIndex = Enum.Font.GothamBold, 9999
    Corner(toast, UDim.new(0, 8)); Stroke(toast, Color3.fromRGB(0, 255, 0), 2)
    TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -140, 1, -50)}):Play()
    task.delay(2, function() local hide = TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -140, 1, 0)}); hide:Play(); hide.Completed:Wait(); toast:Destroy() end)
end

local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Size, MainFrame.AnchorPoint, MainFrame.Position = UDim2.new(0, 380, 0, 280), Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0); MainFrame.BackgroundColor3, MainFrame.BackgroundTransparency = Color3.fromRGB(15, 16, 22), 1; MainFrame.BorderSizePixel, MainFrame.Active, MainFrame.Draggable = 0, true, true
Corner(MainFrame, UDim.new(0, 8)); Stroke(MainFrame, Color3.fromRGB(0, 191, 255), 2)
MainFrame.Visible = false -- ẩn menu cho tới khi load xong (xem phần LOADING ở cuối file)

-- [MỚI] ANIMATION BẬT/TẮT MENU (phóng to "bật ra" / thu nhỏ khi ẩn)
State.MenuOpen = false
do
    local MenuScale = Instance.new("UIScale", MainFrame); MenuScale.Scale = 1
    local menuTween
    State.SetMenu = function(show)
        State.MenuOpen = show
        if menuTween then menuTween:Cancel() end
        if show then
            MenuScale.Scale = 0.8
            MainFrame.Visible = true
            menuTween = TweenService:Create(MenuScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
            menuTween:Play()
        else
            if not MainFrame.Visible then return end
            local t = TweenService:Create(MenuScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.8})
            menuTween = t
            t.Completed:Connect(function(st)
                if st == Enum.PlaybackState.Completed then MainFrame.Visible = false; MenuScale.Scale = 1 end
            end)
            t:Play()
        end
    end
end

local ResizeBtn = Instance.new("TextButton", MainFrame); ResizeBtn.Size, ResizeBtn.Position = UDim2.new(0, 18, 0, 18), UDim2.new(1, -18, 1, -18); ResizeBtn.BackgroundTransparency, ResizeBtn.Text = 1, "◢"; ResizeBtn.TextColor3, ResizeBtn.TextSize, ResizeBtn.ZIndex = Color3.fromRGB(0, 191, 255), 12, 10
local resizing, resizeStart, startSize = false, nil, nil
Track(ResizeBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = true; resizeStart = input.Position; startSize = MainFrame.AbsoluteSize end end))
Track(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if resizing then _G.__vznam_log("INFO", "Đổi kích thước menu: " .. math.floor(MainFrame.AbsoluteSize.X) .. "x" .. math.floor(MainFrame.AbsoluteSize.Y)) end; resizing = false end end))
Track(UserInputService.InputChanged:Connect(function(input) if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - resizeStart; MainFrame.Size = UDim2.new(0, math.clamp(startSize.X + d.X, 320, 500), 0, math.clamp(startSize.Y + d.Y, 230, 450)) end end))

local TopBar = Instance.new("Frame", MainFrame); TopBar.Size, TopBar.BackgroundTransparency = UDim2.new(1, 0, 0, 26), 1
local Logo = Instance.new("Frame", TopBar); Logo.Size, Logo.Position, Logo.BackgroundColor3, Logo.BorderSizePixel = UDim2.new(0, 18, 0, 18), UDim2.new(0, 6, 0.5, -9), Color3.fromRGB(0, 191, 255), 0
Corner(Logo, UDim.new(0, 4)); Stroke(Logo, Color3.fromRGB(0, 191, 255))
local LogoIcon = Instance.new("TextLabel", Logo); LogoIcon.Size, LogoIcon.BackgroundTransparency = UDim2.new(1,0,1,0), 1; LogoIcon.Text, LogoIcon.TextColor3, LogoIcon.TextSize, LogoIcon.Font = "🌸", Color3.fromRGB(255,255,255), 10, Enum.Font.GothamBold
local LogoImage = Instance.new("ImageLabel", Logo); LogoImage.Size, LogoImage.BackgroundTransparency, LogoImage.ScaleType, LogoImage.Visible = UDim2.new(1,0,1,0), 1, Enum.ScaleType.Crop, false; Corner(LogoImage, UDim.new(0, 4))
ApplyIconImage(LogoImage, LogoIcon, IconCfg.Logo, "VzNamHub_logo.png")
local Title = Instance.new("TextLabel", TopBar); Title.Size, Title.Position, Title.BackgroundTransparency = UDim2.new(1, -60, 1, 0), UDim2.new(0, 28, 0, 0), 1; Title.Text, Title.TextColor3, Title.TextSize, Title.Font = "👑 VzNamHub v4.6 : Tổng Hợp  👑", Color3.fromRGB(0, 191, 255), 10, Enum.Font.GothamBold; Title.TextXAlignment = Enum.TextXAlignment.Center
local CloseBtn = Instance.new("TextButton", TopBar); CloseBtn.Size, CloseBtn.Position = UDim2.new(0, 22, 0, 22), UDim2.new(1, -28, 0.5, -11); CloseBtn.BackgroundColor3, CloseBtn.BackgroundTransparency, CloseBtn.BorderSizePixel = Color3.fromRGB(220, 40, 40), 0, 0; CloseBtn.AutoButtonColor = true; CloseBtn.Text, CloseBtn.TextColor3, CloseBtn.TextSize, CloseBtn.Font = "X", Color3.fromRGB(254, 254, 254), 14, Enum.Font.GothamBold -- 254 (không phải 255) để màu chữ menu không đổi màu nút X
do local cc = Instance.new("UICorner", CloseBtn); cc.CornerRadius = UDim.new(0, 5) end
Track(CloseBtn.MouseButton1Click:Connect(function()
    _G.__vznam_log("WARNING", "Đóng VzNamHub (hủy toàn bộ menu)")
    DisconnectAll()
    if SoundService:FindFirstChild("VzNamHubSound") then SoundService.VzNamHubSound:Stop(); SoundService.VzNamHubSound:Destroy() end
    if CoverGui then CoverGui:Destroy() end
    ScreenGui:Destroy()
end))

local SidebarPanel = Instance.new("Frame", MainFrame); SidebarPanel.Name = "SidebarPanel"; SidebarPanel.Size, SidebarPanel.Position = UDim2.new(0.3, -4, 1, -34), UDim2.new(0, 6, 0, 28); SidebarPanel.BackgroundColor3, SidebarPanel.BorderSizePixel = Color3.fromRGB(15,16,22), 0
Corner(SidebarPanel, UDim.new(0, 2)); Stroke(SidebarPanel, Color3.fromRGB(0,191,255), 1)
local SearchBoxTab = Instance.new("TextBox", SidebarPanel); SearchBoxTab.Size, SearchBoxTab.Position = UDim2.new(1, -8, 0, 18), UDim2.new(0, 4, 0, 4); SearchBoxTab.BackgroundColor3, SearchBoxTab.PlaceholderText = Color3.fromRGB(12,12,17), "🔍 Search..."; SearchBoxTab.Text, SearchBoxTab.PlaceholderColor3, SearchBoxTab.TextColor3 = "", Color3.fromRGB(150,155,165), Color3.fromRGB(255,255,255); SearchBoxTab.TextSize, SearchBoxTab.Font = 8, Enum.Font.Gotham
Corner(SearchBoxTab, UDim.new(0, 4)); Stroke(SearchBoxTab); RegTheme(SearchBoxTab, "Input")
local SidebarScroll = Instance.new("ScrollingFrame", SidebarPanel); SidebarScroll.Size, SidebarScroll.Position = UDim2.new(1, -4, 1, -26), UDim2.new(0, 2, 0, 25); SidebarScroll.BackgroundTransparency, SidebarScroll.BorderSizePixel, SidebarScroll.ScrollBarThickness, SidebarScroll.ClipsDescendants = 1, 0, 2, true
local SidebarLayout = Instance.new("UIListLayout", SidebarScroll); SidebarLayout.SortOrder, SidebarLayout.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 3)
local SidebarPadding = Instance.new("UIPadding", SidebarScroll); SidebarPadding.PaddingLeft, SidebarPadding.PaddingRight, SidebarPadding.PaddingTop = UDim.new(0, 2), UDim.new(0, 6), UDim.new(0, 4)
Track(SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 10) end))
Track(SearchBoxTab:GetPropertyChangedSignal("Text"):Connect(function() local q = string.lower(SearchBoxTab.Text); for _, item in ipairs(SidebarScroll:GetChildren()) do if item:IsA("TextButton") then item.Visible = (q == "" or string.find(string.lower(item.Text), q, 1, true)) and true or false end end end))

local ContentContainer = Instance.new("Frame", MainFrame); ContentContainer.Name = "ContentContainer"; ContentContainer.Size, ContentContainer.Position = UDim2.new(0.68, -4, 1, -34), UDim2.new(0.315, 0, 0, 28); ContentContainer.BackgroundColor3, ContentContainer.BorderSizePixel = Color3.fromRGB(15,16,22), 0
Corner(ContentContainer, UDim.new(0, 2)); Stroke(ContentContainer, Color3.fromRGB(0,191,255), 1)
local ContentHeader = Instance.new("Frame", ContentContainer); ContentHeader.Size, ContentHeader.BackgroundTransparency = UDim2.new(1, 0, 0, 26), 1
local ActiveTabTitle = Instance.new("TextLabel", ContentHeader); ActiveTabTitle.Size, ActiveTabTitle.Position, ActiveTabTitle.BackgroundTransparency, ActiveTabTitle.Text = UDim2.new(1, -30, 1, -10), UDim2.new(0, 6, 0, 0), 1, ""; ActiveTabTitle.TextColor3, ActiveTabTitle.TextSize, ActiveTabTitle.Font = Color3.fromRGB(255,255,255), 10, Enum.Font.GothamBold; ActiveTabTitle.TextXAlignment = Enum.TextXAlignment.Left
local CurrentScriptLbl = Instance.new("TextLabel", ContentHeader); CurrentScriptLbl.Size, CurrentScriptLbl.Position, CurrentScriptLbl.BackgroundTransparency = UDim2.new(1, -40, 0, 10), UDim2.new(0, 6, 1, -12), 1
CurrentScriptLbl.Text, CurrentScriptLbl.TextColor3, CurrentScriptLbl.TextSize, CurrentScriptLbl.Font, CurrentScriptLbl.TextXAlignment = "Chưa có script nào chạy", Color3.fromRGB(50, 200, 50), 8, Enum.Font.GothamBold, Enum.TextXAlignment.Left
CurrentScriptLbl.TextTruncate = Enum.TextTruncate.AtEnd -- tên script dài thì cắt bớt, không chàn khung

local SearchInputContent = Instance.new("TextBox", ContentHeader); SearchInputContent.Size, SearchInputContent.Position = UDim2.new(1, -34, 0, 18), UDim2.new(0, 6, 0.5, -9); SearchInputContent.BackgroundColor3, SearchInputContent.TextColor3, SearchInputContent.PlaceholderText = Color3.fromRGB(12,12,17), Color3.fromRGB(255,255,255), "Search features..."; SearchInputContent.PlaceholderColor3, SearchInputContent.TextSize, SearchInputContent.Font = Color3.fromRGB(150,155,165), 8, Enum.Font.Gotham; SearchInputContent.Visible = false
Corner(SearchInputContent, UDim.new(0, 4)); Stroke(SearchInputContent); RegTheme(SearchInputContent, "Input")
local SearchContentIcon = Instance.new("TextButton", ContentHeader); SearchContentIcon.Size, SearchContentIcon.Position = UDim2.new(0, 20, 0, 20), UDim2.new(1, -24, 0.5, -10); SearchContentIcon.BackgroundTransparency, SearchContentIcon.Text, SearchContentIcon.TextSize, SearchContentIcon.TextColor3 = 1, "🔍", 9, Color3.fromRGB(200,205,215)
local searching = false
Track(SearchContentIcon.MouseButton1Click:Connect(function() searching = not searching; _G.__vznam_log("INFO", searching and "Mở ô tìm kiếm chức năng" or "Đóng ô tìm kiếm chức năng"); SearchInputContent.Visible = searching; ActiveTabTitle.Visible = not searching; CurrentScriptLbl.Visible = not searching; if searching then SearchInputContent:CaptureFocus() else SearchInputContent.Text = "" end end))
Track(SearchInputContent:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(SearchInputContent.Text)
    for _, d in ipairs(ContentContainer:GetDescendants()) do
        if d:IsA("TextButton") and d:GetAttribute("Searchable") then
            d.Visible = (q == "") or (string.find(string.lower(d.Text), q, 1, true) ~= nil)
        end
    end
end))
local HeaderDivider = Instance.new("Frame", ContentContainer); HeaderDivider.Size, HeaderDivider.Position, HeaderDivider.BackgroundColor3, HeaderDivider.BorderSizePixel = UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 26), Color3.fromRGB(0,191,255), 0

-- NỀN ANIME: 1 ẢNH DUY NHẤT trải qua cả 2 panel, khe giữa (khung ngoài) KHÔNG có ảnh
Track(SearchBoxTab.FocusLost:Connect(function() if SearchBoxTab.Text ~= "" then _G.__vznam_log("INFO", "Tìm tab: '" .. SearchBoxTab.Text .. "'") end end))
Track(SearchInputContent.FocusLost:Connect(function() if SearchInputContent.Text ~= "" then _G.__vznam_log("INFO", "Tìm chức năng: '" .. SearchInputContent.Text .. "'") end end))
local BgImages = {}
local function MakeBgImage(parent)
    local group = Instance.new("Frame", parent)
    group.Name, group.Size, group.Position = "AnimeBGGroup", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0)
    group.BackgroundTransparency, group.BorderSizePixel, group.ZIndex = 1, 0, 0
    group.ClipsDescendants = true
    local img = Instance.new("ImageLabel", group)
    img.Name, img.BackgroundTransparency, img.ImageTransparency, img.ScaleType, img.ZIndex = "AnimeBG", 1, 0, Enum.ScaleType.Crop, 0
    table.insert(BgImages, {Img = img, Panel = parent, Group = group})
    return img
end
MakeBgImage(SidebarPanel)
MakeBgImage(ContentContainer)

local function UpdateBgLayout()
    local lp, rp = SidebarPanel.AbsolutePosition, ContentContainer.AbsolutePosition
    local rs = ContentContainer.AbsoluteSize
    local fullSize = Vector2.new((rp.X + rs.X) - lp.X, (rp.Y + rs.Y) - lp.Y)
    for _, b in ipairs(BgImages) do
        local pp = b.Group.AbsolutePosition
        b.Img.Position = UDim2.fromOffset(lp.X - pp.X, lp.Y - pp.Y)
        b.Img.Size = UDim2.fromOffset(fullSize.X, fullSize.Y)
    end
end
Track(SidebarPanel:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateBgLayout))
Track(ContentContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateBgLayout))
Track(MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateBgLayout))
task.defer(UpdateBgLayout)


local Tabs = {}
local RegisteredScripts = {}

local TransDict = {
    ["VI"] = { ["🏠 THÔNG TIN"] = "🏠 THÔNG TIN", ["👑 VZNAM HUB"] = "👑 VZNAM HUB", ["📜 SCRIPT BLOX"] = "📜 SCRIPT BLOX", ["🥚 STEAL AN EGG"] = "🥚 STEAL AN EGG", ["🍎 BLOX FRUIT"] = "🍎 BLOX FRUIT", ["🎬 STUDIO LITE"] = "🎬 STUDIO LITE", ["❕ NHẬT KÍ"] = "❕ NHẬT KÍ", ["🖥️ SEVER"] = "🖥️ SEVER", ["⚙️ MISC"] = "⚙️ MISC", ["📦 CẤU HÌNH"] = "📦 CẤU HÌNH" },
    ["EN"] = { ["🏠 THÔNG TIN"] = "🏠 INFO", ["👑 VZNAM HUB"] = "👑 VZNAM HUB", ["📜 SCRIPT BLOX"] = "📜 SCRIPT BLOX", ["🥚 STEAL AN EGG"] = "🥚 STEAL AN EGG", ["🍎 BLOX FRUIT"] = "🍎 BLOX FRUIT", ["🎬 STUDIO LITE"] = "🎬 STUDIO LITE", ["❕ NHẬT KÍ"] = "❕ LOGS", ["🖥️ SEVER"] = "🖥️ SERVER", ["⚙️ MISC"] = "⚙️ MISC", ["📦 CẤU HÌNH"] = "📦 CONFIG" }
}
TransDict["EN"] = TransDict["VI"]
local function UpdateLanguageUI(lang)
    if RelocalizeAll then RelocalizeAll() end
end

local function CreateCategoryTab(tabName, layoutOrder)
    local tabBtn = CreateCustomButton(SidebarScroll, " " .. tabName, "Primary"); tabBtn.LayoutOrder, tabBtn.Size = layoutOrder or 0, UDim2.new(1, 0, 0, 26)
    tabBtn:SetAttribute("OriginName", tabName)
    local indicator = Instance.new("Frame", tabBtn); indicator.Size, indicator.Position, indicator.BackgroundColor3, indicator.BorderSizePixel, indicator.Visible = UDim2.new(0, 3, 0, 12), UDim2.new(0, 0, 0.5, -6), Color3.fromRGB(255,105,180), 0, false; Corner(indicator, UDim.new(0, 2))
    local containerFrame = Instance.new("Frame", ContentContainer); containerFrame.Size, containerFrame.Position = UDim2.new(1, 0, 1, -27), UDim2.new(0, 0, 0, 27); containerFrame.BackgroundTransparency, containerFrame.Visible, containerFrame.ClipsDescendants = 1, false, true
    local subBar = Instance.new("Frame", containerFrame); subBar.Size, subBar.Position, subBar.BackgroundTransparency, subBar.ZIndex = UDim2.new(1, -12, 0, 24), UDim2.new(0, 6, 0, 2), 1, 5
    local subLayout = Instance.new("UIListLayout", subBar); subLayout.FillDirection, subLayout.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 4)
    local noKeyBtn = CreateCustomButton(subBar, "no key", "Primary"); noKeyBtn.Size, noKeyBtn.ZIndex, noKeyBtn.TextXAlignment = UDim2.new(0.48, 0, 1, 0), 6, Enum.TextXAlignment.Center
    local nkStroke = noKeyBtn:FindFirstChildOfClass("UIStroke"); if nkStroke then nkStroke.Color, nkStroke.Thickness = Color3.fromRGB(255,50,50), 2 end
    local hasKeyBtn = CreateCustomButton(subBar, "có key", "Primary"); hasKeyBtn.Size, hasKeyBtn.ZIndex, hasKeyBtn.TextXAlignment = UDim2.new(0.48, 0, 1, 0), 6, Enum.TextXAlignment.Center
    
    local function makeScroll()
        local s = Instance.new("ScrollingFrame", containerFrame); s.Position, s.Size = UDim2.new(0, 6, 0, 28), UDim2.new(1, -12, 1, -28); s.BackgroundTransparency, s.BorderSizePixel, s.ScrollBarThickness, s.ClipsDescendants, s.ZIndex = 1, 0, 3, true, 1
        local p = Instance.new("UIPadding", s); p.PaddingLeft, p.PaddingRight, p.PaddingTop = UDim.new(0,4), UDim.new(0,10), UDim.new(0,6)
        local l = Instance.new("UIListLayout", s); l.Padding, l.HorizontalAlignment = UDim.new(0, 3), Enum.HorizontalAlignment.Center
        Track(l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() s.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end)); return s
    end
    local scrollNoKey = makeScroll(); scrollNoKey.Visible = true
    local scrollHasKey = makeScroll(); scrollHasKey.Visible = false
    Track(noKeyBtn.MouseButton1Click:Connect(function() scrollNoKey.Visible, scrollHasKey.Visible = true, false; local st1 = noKeyBtn:FindFirstChildOfClass("UIStroke"); if st1 then st1.Color, st1.Thickness = Color3.fromRGB(255,50,50), 2 end; local st2 = hasKeyBtn:FindFirstChildOfClass("UIStroke"); if st2 then st2.Color, st2.Thickness = Color3.fromRGB(0,191,255), 1 end end))
    Track(hasKeyBtn.MouseButton1Click:Connect(function() scrollNoKey.Visible, scrollHasKey.Visible = false, true; local st1 = hasKeyBtn:FindFirstChildOfClass("UIStroke"); if st1 then st1.Color, st1.Thickness = Color3.fromRGB(255,50,50), 2 end; local st2 = noKeyBtn:FindFirstChildOfClass("UIStroke"); if st2 then st2.Color, st2.Thickness = Color3.fromRGB(0,191,255), 1 end end))
    Track(tabBtn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end; containerFrame.Visible, indicator.Visible = true, true; ActiveTabTitle.Text = TransDict[State.Language][tabName] or tabName; SearchInputContent.Text = "" end))
    table.insert(Tabs, {Container = containerFrame, Indicator = indicator})
    local Elements = {}
    local function AddBtnTo(parent, name, callback, keyed)
        local btn = CreateCustomButton(parent, " ▶ " .. name, "Primary"); btn.Size = UDim2.new(1, 0, 0, 26); btn:SetAttribute("Searchable", true)
        btn.TextTruncate = Enum.TextTruncate.AtEnd -- tên script dài thì cắt bớt
        State.AddHint(btn, keyed and "Ấn để mở script (cần key)" or "Ấn để mở script")
        Track(btn.MouseButton1Click:Connect(function() ShowToast("✅ script | " .. string.upper(name) .. " | đã bật"); State.SetMenu(false); CurrentScriptLbl.Text = "🟢 Đang bật: " .. name; local okc, errc = pcall(callback); if not okc then _G.__vznam_log("ERROR", "Script '" .. name .. "' bị lỗi khi chạy: " .. tostring(errc)) end end))
        table.insert(RegisteredScripts, {Name = name, Callback = callback}); if _G.__vznam_rebuildScriptDropdown then _G.__vznam_rebuildScriptDropdown() end; return btn
    end
    function Elements:AddNoKey(name, cb) return AddBtnTo(scrollNoKey, name, cb) end
    function Elements:AddHasKey(name, cb) return AddBtnTo(scrollHasKey, name, cb, true) end
    return Elements
end

-- 1. THÔNG TIN (trang chủ: chào mừng + Discord + Có gì mới)
-- [SỬA] LayoutOrder = 0 để tab KEY PREMIUM (LayoutOrder = 1) nằm ngay dưới tab THÔNG TIN
local tabHomeBtn = CreateCustomButton(SidebarScroll, " 🏠 THÔNG TIN", "Primary"); tabHomeBtn.LayoutOrder, tabHomeBtn.Size = 0, UDim2.new(1, 0, 0, 26)
tabHomeBtn:SetAttribute("OriginName", "🏠 THÔNG TIN")
local homeIndicator = Instance.new("Frame", tabHomeBtn); homeIndicator.Size, homeIndicator.Position = UDim2.new(0, 3, 0, 12), UDim2.new(0, 0, 0.5, -6); homeIndicator.BackgroundColor3, homeIndicator.BorderSizePixel, homeIndicator.Visible = Color3.fromRGB(255,105,180), 0, false; Corner(homeIndicator, UDim.new(0, 2))
local homeScroll = Instance.new("ScrollingFrame", ContentContainer); homeScroll.Size, homeScroll.Position = UDim2.new(1, -12, 1, -29), UDim2.new(0, 6, 0, 28); homeScroll.BackgroundTransparency, homeScroll.BorderSizePixel = 1, 0; homeScroll.ScrollBarThickness, homeScroll.Visible, homeScroll.ClipsDescendants = 3, false, true
local homeLayout = Instance.new("UIListLayout", homeScroll); homeLayout.SortOrder, homeLayout.Padding, homeLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 6), Enum.HorizontalAlignment.Center
local homePad = Instance.new("UIPadding", homeScroll); homePad.PaddingLeft, homePad.PaddingRight, homePad.PaddingTop, homePad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 10), UDim.new(0, 6), UDim.new(0, 4)
Track(homeLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() homeScroll.CanvasSize = UDim2.new(0, 0, 0, homeLayout.AbsoluteContentSize.Y + 15) end))
Track(tabHomeBtn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end; homeScroll.Visible, homeIndicator.Visible = true, true; ActiveTabTitle.Text = TransDict[State.Language]["🏠 THÔNG TIN"]; SearchInputContent.Text = "" end))
table.insert(Tabs, {Container = homeScroll, Indicator = homeIndicator})

do
local DISCORD_NAME = "VzNam Hub Discord"
local DISCORD_DESC = "Cập nhật - hỗ trợ"
local DISCORD_LINK = "https://discord.gg/uvKQS8Df9"
local BADGE_TEXT   = "VzNam Hub"

local UpdateLogs = {
    {Tag = "MỚI", Title = "v4.7: Thêm Nhạc", Author = "VzNam Hub", Time = "15/11/26"},
    {Tag = "SỬA", Title = "Sửa lỗi đổi ngôn ngữ chỉ đổi tên tab.", Author = "VzNam Hub", Time = "15/11/26"},
}

local TagColors = {["MỚI"] = Color3.fromRGB(80, 230, 170), ["SỬA"] = Color3.fromRGB(100, 170, 255), ["FIX"] = Color3.fromRGB(255, 170, 70)}
local GREY = Color3.fromRGB(150, 155, 165)

local function makeCard(order)
    local card = Instance.new("Frame", homeScroll)
    card.LayoutOrder, card.Size, card.AutomaticSize, card.BackgroundColor3, card.BorderSizePixel = order, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, Color3.fromRGB(70, 15, 50), 0
    Corner(card, UDim.new(0, 8)); Stroke(card); RegTheme(card, "Primary")
    local pad = Instance.new("UIPadding", card); pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6), UDim.new(0, 6), UDim.new(0, 6)
    return card
end
local function makeChip(parent, text, bg, fg, order)
    local c = Instance.new("TextLabel", parent)
    c.LayoutOrder, c.AutomaticSize, c.Size, c.BackgroundColor3, c.BackgroundTransparency, c.BorderSizePixel = order, Enum.AutomaticSize.X, UDim2.new(0, 0, 0, 16), bg, 0.25, 0
    c.Text, c.TextColor3, c.TextSize, c.Font, c.TextTruncate = text, fg, 8, Enum.Font.GothamMedium, Enum.TextTruncate.AtEnd
    local p = Instance.new("UIPadding", c); p.PaddingLeft, p.PaddingRight = UDim.new(0, 7), UDim.new(0, 7)
    Corner(c, UDim.new(0, 8))
    local mx = Instance.new("UISizeConstraint", c); mx.MaxSize = Vector2.new(130, 16)
    return c
end

local welcome = makeCard(1)
local wl = Instance.new("UIListLayout", welcome); wl.FillDirection, wl.Padding, wl.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 8), Enum.SortOrder.LayoutOrder
local avatar = Instance.new("ImageLabel", welcome)
avatar.LayoutOrder, avatar.Size, avatar.BackgroundColor3, avatar.BorderSizePixel = 1, UDim2.new(0, 44, 0, 44), Color3.fromRGB(30, 30, 40), 0
avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(localPlayer.UserId) .. "&w=150&h=150"
Corner(avatar, UDim.new(1, 0)); Stroke(avatar, Color3.fromRGB(200, 200, 210), 1)
local infoCol = Instance.new("Frame", welcome)
infoCol.LayoutOrder, infoCol.Size, infoCol.AutomaticSize, infoCol.BackgroundTransparency = 2, UDim2.new(1, -52, 0, 0), Enum.AutomaticSize.Y, 1
local icl = Instance.new("UIListLayout", infoCol); icl.Padding, icl.SortOrder = UDim.new(0, 3), Enum.SortOrder.LayoutOrder
local hello = Instance.new("TextLabel", infoCol)
hello.LayoutOrder, hello.Size, hello.BackgroundTransparency, hello.Text, hello.TextColor3, hello.TextSize, hello.Font, hello.TextXAlignment = 1, UDim2.new(1, 0, 0, 11), 1, "Chào mừng trở lại", GREY, 8, Enum.Font.Gotham, Enum.TextXAlignment.Left
local nameLbl = Instance.new("TextLabel", infoCol)
nameLbl.LayoutOrder, nameLbl.Size, nameLbl.BackgroundTransparency, nameLbl.Text, nameLbl.TextColor3, nameLbl.TextSize, nameLbl.Font, nameLbl.TextXAlignment = 2, UDim2.new(1, 0, 0, 16), 1, localPlayer.Name, Color3.fromRGB(255, 255, 255), 13, Enum.Font.GothamBold, Enum.TextXAlignment.Left
nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
local chips = Instance.new("Frame", infoCol)
chips.LayoutOrder, chips.Size, chips.AutomaticSize, chips.BackgroundTransparency = 3, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1
local cl = Instance.new("UIListLayout", chips); cl.FillDirection, cl.Padding, cl.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 4), Enum.SortOrder.LayoutOrder
pcall(function() cl.Wraps = true end)

local exName = "Unknown"
pcall(function()
    if identifyexecutor then exName = tostring((identifyexecutor()))
    elseif getexecutorname then exName = tostring((getexecutorname())) end
end)
local gameChip = makeChip(chips, game.Name, Color3.fromRGB(40, 35, 45), Color3.fromRGB(255, 255, 255), 1)
makeChip(chips, exName, Color3.fromRGB(40, 35, 45), Color3.fromRGB(255, 255, 255), 2)
makeChip(chips, BADGE_TEXT, Color3.fromRGB(60, 120, 100), Color3.fromRGB(190, 255, 225), 3)
task.spawn(function()
    local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
    if ok and info and info.Name and gameChip.Parent then gameChip.Text = info.Name end
end)

local dc = makeCard(2)
local dcl = Instance.new("UIListLayout", dc); dcl.Padding, dcl.SortOrder = UDim.new(0, 6), Enum.SortOrder.LayoutOrder
local dcTop = Instance.new("Frame", dc); dcTop.LayoutOrder, dcTop.Size, dcTop.BackgroundTransparency = 1, UDim2.new(1, 0, 0, 30), 1
local dcIcon = Instance.new("TextLabel", dcTop); dcIcon.Size, dcIcon.BackgroundColor3, dcIcon.BorderSizePixel, dcIcon.Text, dcIcon.TextSize, dcIcon.TextColor3 = UDim2.new(0, 30, 0, 30), Color3.fromRGB(88, 101, 242), 0, "💬", 16, Color3.fromRGB(255, 255, 255); Corner(dcIcon, UDim.new(0, 8))
local dcTitle = Instance.new("TextLabel", dcTop); dcTitle.Size, dcTitle.Position, dcTitle.BackgroundTransparency, dcTitle.Text = UDim2.new(1, -38, 0, 15), UDim2.new(0, 38, 0, 0), 1, DISCORD_NAME
dcTitle.TextColor3, dcTitle.TextSize, dcTitle.Font, dcTitle.TextXAlignment = Color3.fromRGB(255, 255, 255), 10, Enum.Font.GothamBold, Enum.TextXAlignment.Left
local dcDesc = Instance.new("TextLabel", dcTop); dcDesc.Size, dcDesc.Position, dcDesc.BackgroundTransparency, dcDesc.Text = UDim2.new(1, -38, 0, 13), UDim2.new(0, 38, 0, 16), 1, DISCORD_DESC
dcDesc.TextColor3, dcDesc.TextSize, dcDesc.Font, dcDesc.TextXAlignment = GREY, 8, Enum.Font.Gotham, Enum.TextXAlignment.Left
local dcBtn = Instance.new("TextButton", dc)
dcBtn.LayoutOrder, dcBtn.Size, dcBtn.BackgroundColor3, dcBtn.BorderSizePixel, dcBtn.AutoButtonColor = 2, UDim2.new(1, 0, 0, 22), Color3.fromRGB(88, 101, 242), 0, true
dcBtn.Text, dcBtn.TextColor3, dcBtn.TextSize, dcBtn.Font = "Chép Link Mời", Color3.fromRGB(255, 255, 255), 9, Enum.Font.GothamBold; Corner(dcBtn, UDim.new(0, 6)); State.AddHint(dcBtn, "Ấn để chép link mời Discord", 30)
Track(dcBtn.MouseButton1Click:Connect(function()
    if typeof(setclipboard) == "function" then
        pcall(setclipboard, DISCORD_LINK)
        dcBtn.Text = "✓ Đã chép!"; ShowToast("📋 Đã chép link Discord!")
        task.delay(1.5, function() if dcBtn.Parent then dcBtn.Text = "Chép Link Mời" end end)
    else
        _G.__vznam_log("ERROR", "Executor không hỗ trợ setclipboard!")
    end
end))

local upd = makeCard(3)
local ul = Instance.new("UIListLayout", upd); ul.Padding, ul.SortOrder = UDim.new(0, 8), Enum.SortOrder.LayoutOrder
local updTitle = Instance.new("TextLabel", upd)
updTitle.LayoutOrder, updTitle.Size, updTitle.BackgroundTransparency, updTitle.Text = 1, UDim2.new(1, 0, 0, 16), 1, "✦ CÓ GÌ MỚI"
updTitle.TextColor3, updTitle.TextSize, updTitle.Font, updTitle.TextXAlignment = Color3.fromRGB(255, 105, 180), 10, Enum.Font.GothamBold, Enum.TextXAlignment.Left
for i, log in ipairs(UpdateLogs) do
    local row = Instance.new("Frame", upd)
    row.LayoutOrder, row.Size, row.AutomaticSize, row.BackgroundTransparency = i + 1, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1
    local rl = Instance.new("UIListLayout", row); rl.FillDirection, rl.Padding, rl.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 6), Enum.SortOrder.LayoutOrder
    local tag = Instance.new("TextLabel", row)
    tag.LayoutOrder, tag.Size, tag.BackgroundColor3, tag.BorderSizePixel = 1, UDim2.new(0, 32, 0, 16), TagColors[log.Tag] or TagColors["MỚI"], 0
    tag.Text, tag.TextColor3, tag.TextSize, tag.Font = log.Tag or "MỚI", Color3.fromRGB(10, 40, 30), 8, Enum.Font.GothamBold; Corner(tag, UDim.new(0, 4))
    local body = Instance.new("Frame", row)
    body.LayoutOrder, body.Size, body.AutomaticSize, body.BackgroundTransparency = 2, UDim2.new(1, -38, 0, 0), Enum.AutomaticSize.Y, 1
    local bl = Instance.new("UIListLayout", body); bl.Padding, bl.SortOrder = UDim.new(0, 3), Enum.SortOrder.LayoutOrder
    local t = Instance.new("TextLabel", body)
    t.LayoutOrder, t.Size, t.AutomaticSize, t.BackgroundTransparency, t.Text = 1, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1, log.Title or ""
    t.TextColor3, t.TextSize, t.Font, t.TextXAlignment, t.TextYAlignment, t.TextWrapped = Color3.fromRGB(255, 255, 255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, true
    local meta = Instance.new("TextLabel", body)
    meta.LayoutOrder, meta.Size, meta.AutomaticSize, meta.BackgroundColor3, meta.BackgroundTransparency, meta.BorderSizePixel = 2, UDim2.new(0, 0, 0, 14), Enum.AutomaticSize.X, Color3.fromRGB(40, 35, 50), 0.3, 0
    meta.Text, meta.TextColor3, meta.TextSize, meta.Font = (log.Author or BADGE_TEXT) .. "  •  🕒 " .. (log.Time or ""), GREY, 7, Enum.Font.GothamMedium
    local mp = Instance.new("UIPadding", meta); mp.PaddingLeft, mp.PaddingRight = UDim.new(0, 6), UDim.new(0, 6); Corner(meta, UDim.new(0, 7))
end
end

do
-- 2. VZNAM HUB
local tabMain = CreateCategoryTab("👑 VZNAM HUB", 2)
tabMain:AddNoKey("1. VzNamHub : Toa Độ (nokey)", function() SafeLoad("https://gist.githubusercontent.com/lenguyenvietnam0-stack/c03d6edb94d1c29fc02819c95ba804cb/raw/747f33eb4482e3ac9f3d54ecf1edfeef777b88b7/Main.lua", "Toa Độ") end)
tabMain:AddNoKey("2. VzNamHub : Tổng Hợp v3 (nokey)", function() SafeLoad("https://gist.githubusercontent.com/lenguyenvietnam0-stack/34d5edcbc5edb65c68ef8fd68d704bc3/raw/acde1477a294380bd857980d4814033d06a39e1d/Main.lua", "Tổng Hợp v3") end)
tabMain:AddNoKey("3. VzNamHub : Studio lite (nokey)", function() SafeLoad("https://gist.githubusercontent.com/lenguyenvietnam0-stack/0597866ce1b648cefce61590a7e29f7a/raw/afa4b909bda8a75b211f0e44a81dbfc2afa2bd10/Main.lua", "Studio Lite") end)
tabMain:AddNoKey("4. VzNamHub : Lấy Dữ Liệu Game (nokey)", function() SafeLoad("https://gist.githubusercontent.com/lenguyenvietnam0-stack/da990d55bbeade01b13efb86e2276461/raw/9bab33e7af562b15805ae7db7c1b0bff24be99db/Main.lua", "Lấy Dữ Liệu Game") end)
tabMain:AddHasKey("1. mẫu (không nên ấn)", function() SafeLoad("https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHub-Main/refs/heads/main/main.lua", "VzNamHub Main") end)

end

do
-- 3. SCRIPT BLOX (CHUYỂN TRANG + TỔNG SỐ TRANG + 🔑 SCRIPT CÓ KEY)
local tabBloxBtn = CreateCustomButton(SidebarScroll, " 📜 SCRIPT BLOX", "Primary"); tabBloxBtn.LayoutOrder, tabBloxBtn.Size = 3, UDim2.new(1, 0, 0, 26)
tabBloxBtn:SetAttribute("OriginName", "📜 SCRIPT BLOX")
local bloxIndicator = Instance.new("Frame", tabBloxBtn); bloxIndicator.Size, bloxIndicator.Position, bloxIndicator.BackgroundColor3, bloxIndicator.BorderSizePixel, bloxIndicator.Visible = UDim2.new(0, 3, 0, 12), UDim2.new(0, 0, 0.5, -6), Color3.fromRGB(255,105,180), 0, false; Corner(bloxIndicator, UDim.new(0, 2))
local bloxContainer = Instance.new("Frame", ContentContainer); bloxContainer.Size, bloxContainer.Position = UDim2.new(1, 0, 1, -27), UDim2.new(0, 0, 0, 27); bloxContainer.BackgroundTransparency, bloxContainer.Visible, bloxContainer.ClipsDescendants = 1, false, true

local bloxTopBar = Instance.new("Frame", bloxContainer); bloxTopBar.Size, bloxTopBar.Position, bloxTopBar.BackgroundTransparency = UDim2.new(1, -12, 0, 24), UDim2.new(0, 6, 0, 2), 1
local bloxLayout = Instance.new("UIListLayout", bloxTopBar); bloxLayout.FillDirection, bloxLayout.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 4)
local bloxSearchBox = Instance.new("TextBox", bloxTopBar); bloxSearchBox.Size, bloxSearchBox.BackgroundColor3, bloxSearchBox.PlaceholderText, bloxSearchBox.Text = UDim2.new(0.65, 0, 1, 0), Color3.fromRGB(12,12,17), "Nhập tên script...", ""
bloxSearchBox.TextColor3, bloxSearchBox.TextSize, bloxSearchBox.Font = Color3.fromRGB(255,255,255), 9, Enum.Font.Gotham; Corner(bloxSearchBox); Stroke(bloxSearchBox); RegTheme(bloxSearchBox, "Input")
local bloxSearchBtn = CreateCustomButton(bloxTopBar, "🔍 Tìm", "Primary"); bloxSearchBtn.Size, bloxSearchBtn.TextXAlignment = UDim2.new(0.33, 0, 1, 0), Enum.TextXAlignment.Center

local bloxPageBar = Instance.new("Frame", bloxContainer); bloxPageBar.Size, bloxPageBar.Position, bloxPageBar.BackgroundTransparency = UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0, 28), 1
local prevPageBtn = CreateCustomButton(bloxPageBar, " < Trang Trước", "Primary"); prevPageBtn.Size, prevPageBtn.TextXAlignment = UDim2.new(0.3, 0, 1, 0), Enum.TextXAlignment.Center
local pageLbl = Instance.new("TextLabel", bloxPageBar); pageLbl.Size, pageLbl.Position, pageLbl.BackgroundTransparency = UDim2.new(0.38, 0, 1, 0), UDim2.new(0.31, 0, 0, 0), 1
pageLbl.Text, pageLbl.TextColor3, pageLbl.TextSize, pageLbl.Font = "Trang 0/0", Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold
local nextPageBtn = CreateCustomButton(bloxPageBar, "Trang Sau > ", "Primary"); nextPageBtn.Size, nextPageBtn.Position, nextPageBtn.TextXAlignment = UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0), Enum.TextXAlignment.Center

local bloxScroll = Instance.new("ScrollingFrame", bloxContainer); bloxScroll.Position, bloxScroll.Size = UDim2.new(0, 6, 0, 50), UDim2.new(1, -12, 1, -50); bloxScroll.BackgroundTransparency, bloxScroll.BorderSizePixel, bloxScroll.ScrollBarThickness, bloxScroll.ClipsDescendants = 1, 0, 3, true
local bloxPad = Instance.new("UIPadding", bloxScroll); bloxPad.PaddingLeft, bloxPad.PaddingRight, bloxPad.PaddingTop = UDim.new(0, 2), UDim.new(0, 8), UDim.new(0, 4)
local bloxListLayout = Instance.new("UIListLayout", bloxScroll); bloxListLayout.Padding, bloxListLayout.HorizontalAlignment = UDim.new(0, 4), Enum.HorizontalAlignment.Center
Track(bloxListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() bloxScroll.CanvasSize = UDim2.new(0, 0, 0, bloxListLayout.AbsoluteContentSize.Y + 10) end))
Track(tabBloxBtn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end; bloxContainer.Visible, bloxIndicator.Visible = true, true; ActiveTabTitle.Text = TransDict[State.Language]["📜 SCRIPT BLOX"]; SearchInputContent.Text = "" end))
table.insert(Tabs, {Container = bloxContainer, Indicator = bloxIndicator})

local currentSearchQuery = ""
local currentSearchPage = 1
local currentTotalPages = nil

-- màu xanh cho nút Load (không đổi theo theme)
local LOAD_BLUE = Color3.fromRGB(0, 120, 255)
local LOAD_ARMED = Color3.fromRGB(230, 150, 30)

local function ExecuteScriptBloxSearch(query, page)
    if query == "" then _G.__vznam_log("WARNING", "ScriptBlox: chưa nhập tên script để tìm!") return end
    currentSearchQuery = query
    currentSearchPage = page
    pageLbl.Text = "Đang tải..."

    for _, c in ipairs(bloxScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    _G.__vznam_log("INFO", "ScriptBlox: Đang tìm '"..query.."' (Trang "..page..")...")

    local url = "https://scriptblox.com/api/script/search?q=" .. HttpService:UrlEncode(query) .. "&max=20&page=" .. tostring(page)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res then _G.__vznam_log("ERROR", "Lỗi API ScriptBlox!") pageLbl.Text = "Lỗi!" return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data or not data.result or not data.result.scripts then _G.__vznam_log("ERROR", "Không có dữ liệu!") pageLbl.Text = "Lỗi!" return end

    currentTotalPages = tonumber(data.result.totalPages); _G.__vznam_log("INFO", "ScriptBlox: trang " .. tostring(page) .. "/" .. tostring(currentTotalPages or "?") .. ", " .. #data.result.scripts .. " script")
    pageLbl.Text = "Trang " .. tostring(page) .. "/" .. tostring(currentTotalPages or "?")

    if #data.result.scripts == 0 then
        _G.__vznam_log("WARNING", "Không có thêm kết quả nào ở trang này!")
        return
    end

    for _, script in ipairs(data.result.scripts) do
        local hasKey = script.key == true
        local card = Instance.new("Frame", bloxScroll); card.Size, card.BackgroundColor3, card.BackgroundTransparency = UDim2.new(1, -4, 0, 45), State.ThemeBase:Lerp(Color3.new(1,1,1), 0.08), 0; card.ClipsDescendants = true; Corner(card); Stroke(card); RegTheme(card, "Primary")

        -- tiêu đề + tác giả: chừa chỗ cho 2 nút bên phải, chữ dài thì cắt bớt (...)
        local title = Instance.new("TextLabel", card); title.Size, title.Position, title.BackgroundTransparency = UDim2.new(1, -105, 0, 15), UDim2.new(0, 5, 0, 2), 1
        title.Text = (hasKey and "🔑 " or "") .. (script.title or "Unknown")
        title.TextColor3, title.TextSize, title.Font, title.TextXAlignment = Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
        title.TextTruncate, title.TextWrapped, title.ClipsDescendants = Enum.TextTruncate.AtEnd, false, true
        local author = Instance.new("TextLabel", card); author.Size, author.Position, author.BackgroundTransparency, author.Text = UDim2.new(1, -105, 0, 12), UDim2.new(0, 5, 0, 17), 1, "Tác giả: "..(script.author and script.author.username or "N/A").." | Game: "..(script.game and script.game.name or "N/A"); author.TextColor3, author.TextSize, author.Font, author.TextXAlignment = Color3.fromRGB(150,155,165), 7, Enum.Font.Gotham, Enum.TextXAlignment.Left
        author.TextTruncate, author.TextWrapped, author.ClipsDescendants = Enum.TextTruncate.AtEnd, false, true

        local copyBtn = Instance.new("TextButton", card); copyBtn.Size, copyBtn.Position, copyBtn.BackgroundColor3, copyBtn.Text = UDim2.new(0, 45, 0, 16), UDim2.new(1, -95, 0.5, -8), State.ThemeBase:Lerp(Color3.new(0,0,0), 0.4), "Copy"; copyBtn.TextColor3, copyBtn.TextSize, copyBtn.Font = Color3.fromRGB(255,255,255), 8, Enum.Font.GothamBold; Corner(copyBtn); RegTheme(copyBtn, "Input")
        Track(copyBtn.MouseButton1Click:Connect(function() if typeof(setclipboard) == "function" then setclipboard("https://scriptblox.com/script/"..(script.slug or "")); _G.__vznam_log("SUCCESS", "Đã copy link script: " .. (script.title or "?")) else _G.__vznam_log("ERROR", "Executor không hỗ trợ setclipboard!") end end))

        -- nút Load màu xanh (không RegTheme để theme không ghi đè màu)
        local loadBtn = Instance.new("TextButton", card); loadBtn.Size, loadBtn.Position, loadBtn.BackgroundColor3, loadBtn.Text = UDim2.new(0, 45, 0, 16), UDim2.new(1, -48, 0.5, -8), LOAD_BLUE, "Load"; loadBtn.TextColor3, loadBtn.TextSize, loadBtn.Font = Color3.fromRGB(255,255,255), 8, Enum.Font.GothamBold; loadBtn.BackgroundTransparency = 0; Corner(loadBtn)

        local armed = false
        Track(loadBtn.MouseButton1Click:Connect(function()
            if hasKey and not armed then
                armed = true
                loadBtn.Text, loadBtn.TextSize, loadBtn.BackgroundColor3 = "Load lại", 7, LOAD_ARMED
                ShowToast("🔑 Script này có key, ấn Load lại để bật")
                _G.__vznam_log("WARNING", "🔑 '"..(script.title or "?").."' có key! Ấn Load lại để bật.")
                task.delay(6, function()
                    if armed and loadBtn.Parent then armed = false; loadBtn.Text, loadBtn.TextSize, loadBtn.BackgroundColor3 = "Load", 8, LOAD_BLUE end
                end)
                return
            end
            armed = false
            loadBtn.Text, loadBtn.TextSize, loadBtn.BackgroundColor3 = "Load", 8, LOAD_BLUE
            _G.__vznam_log("INFO", "Bấm Load script: " .. tostring(script.title)); if not script.script then _G.__vznam_log("ERROR", "Script không có mã nguồn!") end
            if script.script then
                local func = (loadstring or load)(script.script)
                if func then
                    local okf, errf = pcall(func); if not okf then _G.__vznam_log("ERROR", "Runtime lỗi: " .. tostring(errf)) end
                    CurrentScriptLbl.Text = "🟢 Đang bật: " .. (hasKey and "🔑 " or "") .. (script.title or "?")
                    if okf then _G.__vznam_log("SUCCESS", "Đã bật: " .. (script.title or "?")) end
                else
                    _G.__vznam_log("ERROR", "Script lỗi cú pháp!")
                end
            end
        end))
    end
    _G.__vznam_log("SUCCESS", "Đã tải xong trang "..page..".")
end

Track(bloxSearchBtn.MouseButton1Click:Connect(function() ExecuteScriptBloxSearch(bloxSearchBox.Text, 1) end))
Track(prevPageBtn.MouseButton1Click:Connect(function()
    if currentSearchQuery == "" then return end
    if currentSearchPage > 1 then ExecuteScriptBloxSearch(currentSearchQuery, currentSearchPage - 1) else _G.__vznam_log("WARNING", "Đang ở trang đầu tiên!") end
end))
Track(nextPageBtn.MouseButton1Click:Connect(function()
    if currentSearchQuery == "" then return end
    if currentTotalPages and currentSearchPage >= currentTotalPages then _G.__vznam_log("WARNING", "Đang ở trang cuối!") return end
    ExecuteScriptBloxSearch(currentSearchQuery, currentSearchPage + 1)
end))

end

do
-- 4. STEAL AN EGG
local tab1 = CreateCategoryTab("🥚 STEAL AN EGG", 4)
tab1:AddNoKey("1. Hop sv1 người", function() SafeLoad("https://raw.githubusercontent.com/raw-roblox/PrivateServerBypass/refs/heads/main/lua", "Hop sv1 người") end)
tab1:AddNoKey("2. FyyCommunity", function() SafeLoad("https://FyyCommunity.my.id", "FyyCommunity") end)
tab1:AddNoKey("3. Night hub", function() SafeLoad("https://raw.githubusercontent.com/WhiteX1208/Scripts/refs/heads/main/StealAnEggs.luau", "Night hub") end)
tab1:AddNoKey("4. Chillii hub v10 ", function() SafeLoad("https://id.tomroblox.com/raw/kairoblox/chilli-x-venyx-v10-new-10500", "Chillii hub v10") end)
tab1:AddNoKey("5. Chillii hub v8 pro", function() SafeLoad("https://raw.githubusercontent.com/napun67/stealanegg/refs/heads/main/chillihubv8.lua", "Chillii hub v8 pro") end)
tab1:AddNoKey("6. Sena", function() SafeLoad("https://senahub.xyz/senaexclusive", "Sena") end)
tab1:AddNoKey("7. Chillii hub v7", function() SafeLoad("https://raw.githubusercontent.com/kadit9999/stealanegg/refs/heads/main/ChilliV5BaKhi.lua", "chillii hub v7") end)
tab1:AddNoKey("8. Virex join trứng", function() SafeLoad("https://cdn.luaprotect.dev/u/8660b0/AvrC3cs5mZ38jbnD", "Virex join trứng") end)
tab1:AddNoKey("9. Codium", function() SafeLoad("https://getcodium.xyz/loader.luau", "Codium") end)
tab1:AddHasKey("1. Lemon Hub v4", function() SafeLoad("https://raw.githubusercontent.com/owenzeke99-tech/lennonhubv4/refs/heads/main/lennonhubkeyless.txt", "Lemon Hub v4") end)
tab1:AddHasKey("2. Hoshi hub", function() SafeLoad("https://raw.githubusercontent.com/napun87/stealanegg/refs/heads/main/hosi.lua", "Hoshi hub") end)
tab1:AddHasKey("3. Bigfroot", function() SafeLoad("https://raw.githubusercontent.com/hanniii1/Loader/refs/heads/main/BFLoader.lua", "Bigfroot") end)
tab1:AddHasKey("4. Chữ A(ajjans)", function() SafeLoad("https://api.luarmor.net/files/v4/loaders/359e97f8618e9008afe5f496184ebb7c.lua", "Chữ A") end)
tab1:AddHasKey("5. Speed hub", function() SafeLoad("https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua", "Speed hub") end)
tab1:AddHasKey("6. Neohub", function() SafeLoad("https://raw.githubusercontent.com/neohubdev/script/main/script", "Neohub") end)
tab1:AddHasKey("7. Real kid", function() SafeLoad("https://raw.githubusercontent.com/realkidhub/realkid/refs/heads/main/main.lua", "Real kid") end)
tab1:AddHasKey("8. chillii hub v2", function() SafeLoad("https://gist.githubusercontent.com/ronnei/1fa67c56dd9af203b192d15e752928e5/raw/4e2d5105640e09a008b4ae6df23f9708cadfef06/chilliv2-stealanegg", "chillii hub v2") end)
tab1:AddHasKey("9. chillii hub v6 pro", function() SafeLoad("https://raw.githubusercontent.com/ronnei/hihi/refs/heads/main/chillihubv5.lua", "chillii hub v6 bảng to") end)
tab1:AddHasKey("10. Vxeze hub", function() SafeLoad("https://gist.githubusercontent.com/angeryy-tvy/6a9ce750ddf5860230196ac468868fdb/raw/Steal-An-Egg-Vxeze", "Vxeze hub") end)

-- 5. BLOX FRUIT
local tab2 = CreateCategoryTab("🍎 BLOX FRUIT", 5)
tab2:AddNoKey("1. RedzHub v2", function() SafeLoad("https://raw.githubusercontent.com/UCT-hub/main/refs/heads/main/redz-v2", "RedzHub v2") end)
tab2:AddNoKey("2. Quantumx Hub", function() SafeLoad("https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/QuantumOnyx.lua", "Quantumx Hub") end)
tab2:AddHasKey("1. Speed Hub", function() SafeLoad("https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua", "Speed Hub") end)
tab2:AddHasKey("2. Omg Hub", function() SafeLoad("https://raw.githubusercontent.com/Omgshit/Scripts/main/MainLoader.lua", "Omg Hub") end)
tab2:AddHasKey("3. TeddyHub", function() repeat task.wait() until game:IsLoaded(); SafeLoad("https://raw.githubusercontent.com/teddyhubdev/diepvy/refs/heads/main/TeddyHub.lua", "TeddyHub") end)
tab2:AddHasKey("4. Gravity Hub", function() SafeLoad("https://raw.githubusercontent.com/Dev-GravityHub/BloxFruit/refs/heads/main/Main.lua", "Gravity Hub") end)
tab2:AddHasKey("5. Realkid hub", function() SafeLoad("https://raw.githubusercontent.com/realkidhub/realkid/refs/heads/main/main.lua", "Realkid hub") end)
tab2:AddHasKey("6. BananaHub", function() repeat task.wait() until game:IsLoaded(); getgenv().Team = "Marines"; SafeLoad("https://raw.githubusercontent.com/obiyeueim/vthangsitink/main/BananaHub.lua", "BananaHub") end)

-- 6. EVADE
local tabEvade = CreateCategoryTab("🏃 EVADE", 6)
-- tabEvade:AddNoKey("1. Tên script", function() SafeLoad("LINK_RAW", "Tên script") end)
tabEvade:AddHasKey("1. YingYang(getkey1lan)", function() SafeLoad("https://raw.githubusercontent.com/linkyinyangg/beta/refs/heads/main/New", "YingYang") end)

-- 7. 99 NGÀY TRÊN BIỂN
local tab99 = CreateCategoryTab("🌊 99 NGÀY TRÊN BIỂN", 7)
-- tab99:AddNoKey("1. Tên script", function() SafeLoad("LINK_RAW", "Tên script") end)
-- tab99:AddHasKey("1. Tên script", function() SafeLoad("LINK_RAW", "Tên script") end)

-- 8. PAPER TO PLANE (GameBiHuynh)
local tabPaper = CreateCategoryTab("✈️ PAPER TO PLANE", 8)
-- tabPaper:AddNoKey("1. DYXNET HUB", function() SafeLoad("https://keys.taikhoanai.site/loader.lua", "DYXNET HUB") end)
tabPaper:AddHasKey("1. DYXNET HUB", function() SafeLoad("https://keys.taikhoanai.site/loader.lua", "DYXNET HUB") end)

-- 9. THROW FOOD FOR ANIMALS
local tabThrow = CreateCategoryTab("🍖 THROW FOOD FOR ANIMALS", 9)
-- tabThrow:AddNoKey("1. Tên script", function() SafeLoad("LINK_RAW", "Tên script") end)
-- tabThrow:AddHasKey("1. Tên script", function() SafeLoad("LINK_RAW", "Tên script") end)

-- 10. DOORS NX
local tabDoors = CreateCategoryTab("🚪 DOORS", 10)
-- tabDoors:AddNoKey("1. Tên script", function() SafeLoad("LINK_RAW", "Tên script") end)
tabDoors:AddHasKey("1. SCRIPT DOORS(QUÊN TÊN)", function() SafeLoad("https://raw.githubusercontent.com/bocaj111004/Abysall/refs/heads/main/Loader.luau", "SCRIPT DOOR") end)

-- 6. STUDIO LITE
local tabStudioLite = CreateCategoryTab("🎬 STUDIO LITE", 11)
tabStudioLite:AddNoKey("1. FORKT ENGINE v3.8", function() SafeLoad("https://raw.githubusercontent.com/HamZyy4/Studio-Roblox/refs/heads/main/data/ImportRbxm.lua", "FORKT ENGINE") end)
tabStudioLite:AddNoKey("2. NoKer Hub", function() SafeLoad("https://scriptblox.com/raw/Studio-Lite-Model-Inserter-NotMines-27264", "NoKer Hub") end)
tabStudioLite:AddHasKey("1. violence District", function() SafeLoad("https://raw.githubusercontent.com/HamZyy4/forkt-vd-v3/refs/heads/main/loader.lua", "violence District") end)

end

do
-- 7. NHẬT KÍ
local tabNhatKiBtn = CreateCustomButton(SidebarScroll, " ❕ NHẬT KÍ", "Primary"); tabNhatKiBtn.LayoutOrder, tabNhatKiBtn.Size = 12, UDim2.new(1, 0, 0, 26)
tabNhatKiBtn:SetAttribute("OriginName", "❕ NHẬT KÍ")
local nhatKiIndicator = Instance.new("Frame", tabNhatKiBtn); nhatKiIndicator.Size, nhatKiIndicator.Position, nhatKiIndicator.BackgroundColor3, nhatKiIndicator.BorderSizePixel, nhatKiIndicator.Visible = UDim2.new(0, 3, 0, 12), UDim2.new(0, 0, 0.5, -6), Color3.fromRGB(255,105,180), 0, false; Corner(nhatKiIndicator, UDim.new(0, 2))
local nhatKiContainer = Instance.new("Frame", ContentContainer); nhatKiContainer.Size, nhatKiContainer.Position = UDim2.new(1, 0, 1, -27), UDim2.new(0, 0, 0, 27); nhatKiContainer.BackgroundTransparency, nhatKiContainer.Visible, nhatKiContainer.ClipsDescendants = 1, false, true
local nhatKiTopBar = Instance.new("Frame", nhatKiContainer); nhatKiTopBar.Size, nhatKiTopBar.Position, nhatKiTopBar.BackgroundTransparency = UDim2.new(1, -12, 0, 22), UDim2.new(0, 6, 0, 2), 1
local clearLogBtn = CreateCustomButton(nhatKiTopBar, "🗑️ Xóa log", "Primary"); clearLogBtn.Size, clearLogBtn.TextXAlignment = UDim2.new(0.48, 0, 1, 0), Enum.TextXAlignment.Center
nhatKiScroll = Instance.new("ScrollingFrame", nhatKiContainer); nhatKiScroll.Position, nhatKiScroll.Size = UDim2.new(0, 6, 0, 26), UDim2.new(1, -12, 1, -26); nhatKiScroll.BackgroundColor3, nhatKiScroll.BackgroundTransparency, nhatKiScroll.BorderSizePixel = Color3.fromRGB(20, 25, 20), 0.3, 0; nhatKiScroll.ScrollBarThickness, nhatKiScroll.ClipsDescendants, nhatKiScroll.ZIndex = 3, true, 1
Corner(nhatKiScroll); local nhatKiPad = Instance.new("UIPadding", nhatKiScroll); nhatKiPad.PaddingLeft, nhatKiPad.PaddingRight, nhatKiPad.PaddingTop, nhatKiPad.PaddingBottom = UDim.new(0,6), UDim.new(0,10), UDim.new(0,6), UDim.new(0,4)
local nhatKiLayout = Instance.new("UIListLayout", nhatKiScroll); nhatKiLayout.Padding = UDim.new(0, 4); if _G.__vznam_replayLogs then _G.__vznam_replayLogs(nhatKiScroll) end
Track(nhatKiLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() nhatKiScroll.CanvasSize = UDim2.new(0, 0, 0, nhatKiLayout.AbsoluteContentSize.Y + 10) end))
Track(clearLogBtn.MouseButton1Click:Connect(function() for _, c in ipairs(nhatKiScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end; if _G.MiniLogScroll then for _, c in ipairs(_G.MiniLogScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end end; if _G.__vznam_clearHistory then _G.__vznam_clearHistory() end; _G.__vznam_log("WARNING", "Đã xóa log.") end))
Track(tabNhatKiBtn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end; nhatKiContainer.Visible, nhatKiIndicator.Visible = true, true; ActiveTabTitle.Text = TransDict[State.Language]["❕ NHẬT KÍ"]; SearchInputContent.Text = "" end))
table.insert(Tabs, {Container = nhatKiContainer, Indicator = nhatKiIndicator})

end

do
-- 8. SEVER
local tabSeverBtn = CreateCustomButton(SidebarScroll, " 🖥️ SEVER", "Primary"); tabSeverBtn.LayoutOrder, tabSeverBtn.Size = 13, UDim2.new(1, 0, 0, 26)
tabSeverBtn:SetAttribute("OriginName", "🖥️ SEVER")
local severIndicator = Instance.new("Frame", tabSeverBtn); severIndicator.Size, severIndicator.Position, severIndicator.BackgroundColor3, severIndicator.BorderSizePixel, severIndicator.Visible = UDim2.new(0, 3, 0, 12), UDim2.new(0, 0, 0.5, -6), Color3.fromRGB(255,105,180), 0, false; Corner(severIndicator, UDim.new(0, 2))
local severScroll = Instance.new("ScrollingFrame", ContentContainer); severScroll.Size, severScroll.Position = UDim2.new(1, -12, 1, -29), UDim2.new(0, 6, 0, 28); severScroll.BackgroundTransparency, severScroll.BorderSizePixel, severScroll.ScrollBarThickness, severScroll.Visible, severScroll.ClipsDescendants = 1, 0, 3, false, true
local severLayout = Instance.new("UIListLayout", severScroll); severLayout.SortOrder, severLayout.Padding, severLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), Enum.HorizontalAlignment.Center
local severPad = Instance.new("UIPadding", severScroll); severPad.PaddingLeft, severPad.PaddingRight, severPad.PaddingTop = UDim.new(0,4), UDim.new(0,10), UDim.new(0,6)
Track(severLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() severScroll.CanvasSize = UDim2.new(0, 0, 0, severLayout.AbsoluteContentSize.Y + 15) end))
Track(tabSeverBtn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end; severScroll.Visible, severIndicator.Visible = true, true; ActiveTabTitle.Text = TransDict[State.Language]["🖥️ SEVER"]; SearchInputContent.Text = "" end))
table.insert(Tabs, {Container = severScroll, Indicator = severIndicator})

local pendingFail = nil
local function JoinJob(jobId)
    jobId = (tostring(jobId or ""):gsub("%s", ""))
    if jobId == "" then _G.__vznam_log("WARNING", "Chưa nhập JobID!") ShowToast("⚠️ Chưa nhập JobID") return false end
    _G.__vznam_log("INFO", "Đang vào server " .. jobId)
    local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, localPlayer) end)
    if not ok then _G.__vznam_log("ERROR", "Teleport lỗi: " .. tostring(err)); return false end
    return true
end
-- dịch chuyển thất bại (server đầy/đã đóng...) -> tự thử server kế tiếp
pcall(function()
    Track(TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
        if plr ~= localPlayer then return end
        _G.__vznam_log("ERROR", "Dịch chuyển thất bại: " .. tostring(result) .. " - " .. tostring(msg))
        local f = pendingFail; pendingFail = nil
        if f then task.delay(1.5, f) end
    end))
end)
local function JoinList(list)
    local i = 0
    local function try()
        i = i + 1
        local sv = list[i]
        if not sv or i > 6 then pendingFail = nil; _G.__vznam_log("ERROR", "Thử nhiều server nhưng đều không vào được!"); return end
        _G.__vznam_log("INFO", string.format("Thử vào server %d/%d người (lần %d)", sv.playing, sv.maxPlayers, i))
        pendingFail = try
        if not JoinJob(sv.id) then pendingFail = nil; task.delay(1, try) end
    end
    try()
end
-- lấy request() của executor (có mã lỗi HTTP), không có thì dùng game:HttpGet
local function HttpGetAny(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    local why = "không có phản hồi"
    if req then
        local ok, res = pcall(req, {Url = url, Method = "GET", Headers = {["Accept"] = "application/json"}})
        if ok and type(res) == "table" and type(res.Body) == "string" then
            local code = tonumber(res.StatusCode or res.Status) or 200
            if code == 200 then return res.Body end
            why = "HTTP " .. tostring(code)
        elseif not ok then why = tostring(res) end
    end
    local ok2, body = pcall(function() return game:HttpGet(url) end)
    if ok2 and type(body) == "string" and body ~= "" then return body end
    return nil, why .. " / " .. (ok2 and "rỗng" or tostring(body))
end
local SERVER_HOSTS = {"games.roblox.com", "games.roproxy.com"}
local function GetServers(order, pages)
    local list, seen, lastErr = {}, {}, nil
    for _, host in ipairs(SERVER_HOSTS) do
        local cursor, got = nil, false
        for _ = 1, (pages or 1) do
            local url = string.format("https://%s/v1/games/%d/servers/Public?sortOrder=%s&excludeFullGames=true&limit=100", host, game.PlaceId, order)
            if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local body, err = HttpGetAny(url)
            if not body then lastErr = host .. ": " .. tostring(err); break end
            local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
            if not ok or type(data) ~= "table" or type(data.data) ~= "table" then lastErr = host .. ": dữ liệu lỗi (" .. tostring(body):sub(1, 60) .. ")"; break end
            got = true
            for _, sv in ipairs(data.data) do
                if sv.id and sv.id ~= game.JobId and not seen[sv.id] and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then
                    seen[sv.id] = true; table.insert(list, sv)
                end
            end
            cursor = data.nextPageCursor
            if not cursor then break end
        end
        if got then return list end
    end
    _G.__vznam_log("ERROR", "Không lấy được danh sách server! " .. tostring(lastErr))
    return nil
end
local severBusy = false
local function SeverGuard(fn)
    if severBusy then ShowToast("⏳ Đang xử lý, đợi chút...") return end
    severBusy = true
    local ok, err = pcall(fn)
    severBusy = false
    if not ok then _G.__vznam_log("ERROR", "Lỗi chức năng server: " .. tostring(err)) end
end
local function AddSeverBtn(text, order, cb, hint)
    local btn = CreateCustomButton(severScroll, " " .. text, "Primary"); btn.LayoutOrder, btn.Size = order, UDim2.new(1, 0, 0, 26); btn:SetAttribute("Searchable", true)
    State.AddHint(btn, hint)
    Track(btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb)
        if not ok then _G.__vznam_log("ERROR", "Lỗi nút server: " .. tostring(err)) end
    end))
    return btn
end

local jobInfoFrame = Instance.new("Frame", severScroll); jobInfoFrame.LayoutOrder, jobInfoFrame.Size, jobInfoFrame.BackgroundColor3, jobInfoFrame.BackgroundTransparency = 1, UDim2.new(1, 0, 0, 26), Color3.fromRGB(70,15,50), 0; Corner(jobInfoFrame); Stroke(jobInfoFrame); RegTheme(jobInfoFrame, "Primary")
local jobInfoLbl = Instance.new("TextLabel", jobInfoFrame); jobInfoLbl.Size, jobInfoLbl.Position, jobInfoLbl.BackgroundTransparency, jobInfoLbl.Text = UDim2.new(1, -10, 1, 0), UDim2.new(0, 5, 0, 0), 1, "JobID: " .. game.JobId
jobInfoLbl.TextColor3, jobInfoLbl.TextSize, jobInfoLbl.Font, jobInfoLbl.TextXAlignment, jobInfoLbl.ClipsDescendants = Color3.fromRGB(180,185,195), 8, Enum.Font.Gotham, Enum.TextXAlignment.Left, true

local jobInputFrame = Instance.new("Frame", severScroll); jobInputFrame.LayoutOrder, jobInputFrame.Size, jobInputFrame.BackgroundColor3, jobInputFrame.BackgroundTransparency = 2, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70,15,50), 0; Corner(jobInputFrame); Stroke(jobInputFrame); RegTheme(jobInputFrame, "Primary")
local jobInputLbl = Instance.new("TextLabel", jobInputFrame); jobInputLbl.Size, jobInputLbl.Position, jobInputLbl.BackgroundTransparency, jobInputLbl.Text = UDim2.new(0, 45, 1, 0), UDim2.new(0, 6, 0, 0), 1, "JobID"
jobInputLbl.TextColor3, jobInputLbl.TextSize, jobInputLbl.Font, jobInputLbl.TextXAlignment = Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
local jobIdBox = Instance.new("TextBox", jobInputFrame); jobIdBox.Size, jobIdBox.Position, jobIdBox.BackgroundColor3, jobIdBox.PlaceholderText, jobIdBox.Text = UDim2.new(1, -60, 0, 20), UDim2.new(0, 54, 0.5, -10), Color3.fromRGB(50,10,35), "Dán JobID vào đây...", ""
jobIdBox.PlaceholderColor3, jobIdBox.TextColor3, jobIdBox.TextSize, jobIdBox.Font, jobIdBox.ClearTextOnFocus, jobIdBox.ClipsDescendants = Color3.fromRGB(150,155,165), Color3.fromRGB(255,255,255), 8, Enum.Font.Gotham, false, true
Corner(jobIdBox, UDim.new(0, 4)); Stroke(jobIdBox); RegTheme(jobIdBox, "Input"); Track(jobIdBox.FocusLost:Connect(function() if jobIdBox.Text ~= "" then _G.__vznam_log("INFO", "Đã nhập JobID: " .. jobIdBox.Text) end end))

AddSeverBtn("🚪 Vào server", 3, function() pendingFail = nil; JoinJob(jobIdBox.Text) end, "Ấn để vào server theo JobID đã dán")

AddSeverBtn("📎 Code vào sever này!", 4, function()
    local code = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)', game.PlaceId, game.JobId)
    if typeof(setclipboard) == "function" then setclipboard(code); ShowToast("📎 Đã copy code vào server!"); _G.__vznam_log("SUCCESS", "Đã copy code vào server này.") else _G.__vznam_log("ERROR", "Executor không hỗ trợ setclipboard!") end
end, "Ấn để chép code vào server này")

AddSeverBtn("🔁 Đổi server", 5, function()
    SeverGuard(function()
        _G.__vznam_log("INFO", "Đang tìm server khác...")
        ShowToast("🔎 Đang tìm server...")
        local list = GetServers("Desc", 2); if not list then return end
        if #list == 0 then _G.__vznam_log("WARNING", "Không có server nào để đổi!") return end
        for i = #list, 2, -1 do local j = math.random(1, i); list[i], list[j] = list[j], list[i] end
        _G.__vznam_log("INFO", string.format("Đổi sang server %d/%d người", list[1].playing, list[1].maxPlayers))
        JoinList(list)
    end)
end, "Ấn để nhảy sang server ngẫu nhiên")

AddSeverBtn("🔍 Server vắng nhất", 6, function()
    SeverGuard(function()
        _G.__vznam_log("INFO", "Đang tìm server vắng nhất...")
        ShowToast("🔎 Đang tìm server...")
        local list = GetServers("Asc", 1); if not list then return end
        if #list == 0 then _G.__vznam_log("WARNING", "Không tìm thấy server nào!") return end
        table.sort(list, function(x, y) return (x.playing == 0 and 1e9 or x.playing) < (y.playing == 0 and 1e9 or y.playing) end)
        _G.__vznam_log("INFO", string.format("Server vắng nhất: %d/%d người", list[1].playing, list[1].maxPlayers))
        JoinList(list)
    end)
end, "Ấn để vào server ít người nhất")

AddSeverBtn("⤴️ Vào lại", 7, function()
    _G.__vznam_log("INFO", "Đang vào lại server này...")
    pendingFail = nil; JoinJob(game.JobId)
end, "Ấn để vào lại server này")

AddSeverBtn("📋 Copy JobID", 8, function()
    if typeof(setclipboard) == "function" then setclipboard(game.JobId); ShowToast("📋 Đã copy JobID!"); _G.__vznam_log("SUCCESS", "Đã copy JobID.") else _G.__vznam_log("ERROR", "Executor không hỗ trợ setclipboard!") end
end, "Ấn để chép JobID server này")
end

local autoLoadToggleBtn, autoLoadContainer, dropBtn, musicToggleBtn, musicContainer, HubSound, menuColorToggleBtn, menuColorContainer, ApplyTheme, UpdateAllStrokes, configScroll, cfgToggleBtn, mainConfigContainer -- biến dùng chung giữa các khối
do 
-- 9. MISC
local tabMiscBtn = CreateCustomButton(SidebarScroll, " ⚙️ MISC", "Primary"); tabMiscBtn.LayoutOrder, tabMiscBtn.Size = 14, UDim2.new(1, 0, 0, 26)
tabMiscBtn:SetAttribute("OriginName", "⚙️ MISC")
local miscIndicator = Instance.new("Frame", tabMiscBtn); miscIndicator.Size, miscIndicator.Position, miscIndicator.BackgroundColor3, miscIndicator.BorderSizePixel, miscIndicator.Visible = UDim2.new(0, 3, 0, 12), UDim2.new(0, 0, 0.5, -6), Color3.fromRGB(255,105,180), 0, false; Corner(miscIndicator, UDim.new(0, 2))
local miscScroll = Instance.new("ScrollingFrame", ContentContainer); miscScroll.Size, miscScroll.Position = UDim2.new(1, -12, 1, -29), UDim2.new(0, 6, 0, 28); miscScroll.BackgroundTransparency, miscScroll.BorderSizePixel, miscScroll.ScrollBarThickness, miscScroll.Visible, miscScroll.ClipsDescendants = 1, 0, 3, false, true
local miscLayout = Instance.new("UIListLayout", miscScroll); miscLayout.SortOrder, miscLayout.Padding, miscLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 5), Enum.HorizontalAlignment.Center
local miscPad = Instance.new("UIPadding", miscScroll); miscPad.PaddingLeft, miscPad.PaddingRight, miscPad.PaddingTop = UDim.new(0,4), UDim.new(0,10), UDim.new(0,6)
Track(miscLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() miscScroll.CanvasSize = UDim2.new(0, 0, 0, miscLayout.AbsoluteContentSize.Y + 15) end))
Track(tabMiscBtn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end; miscScroll.Visible, miscIndicator.Visible = true, true; ActiveTabTitle.Text = TransDict[State.Language]["⚙️ MISC"] end))
table.insert(Tabs, {Container = miscScroll, Indicator = miscIndicator})

autoLoadToggleBtn = CreateCustomButton(miscScroll, " ↓ auto load script", "Secondary"); autoLoadToggleBtn.LayoutOrder, autoLoadToggleBtn.Size = 1, UDim2.new(1, 0, 0, 34); State.AddHint(autoLoadToggleBtn, "Ấn để mở/đóng mục này", 30)
autoLoadContainer = Instance.new("Frame", miscScroll); autoLoadContainer.LayoutOrder, autoLoadContainer.Size, autoLoadContainer.AutomaticSize, autoLoadContainer.BackgroundTransparency, autoLoadContainer.Visible = 2, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1, true
local alLayout = Instance.new("UIListLayout", autoLoadContainer); alLayout.SortOrder, alLayout.Padding, alLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), Enum.HorizontalAlignment.Center
Track(autoLoadToggleBtn.MouseButton1Click:Connect(function() autoLoadContainer.Visible = not autoLoadContainer.Visible; autoLoadToggleBtn.Text = autoLoadContainer.Visible and " ↓ auto load script" or " → auto load script" end))
dropBtn = CreateCustomButton(autoLoadContainer, " 📜 Chọn Script Auto Load...", "Primary"); dropBtn.LayoutOrder, dropBtn.Size = 1, UDim2.new(1, 0, 0, 26)
dropBtn.TextTruncate = Enum.TextTruncate.AtEnd; State.AddHint(dropBtn, "Ấn để chọn script tự chạy")
local dropListFrame = Instance.new("ScrollingFrame", autoLoadContainer); dropListFrame.LayoutOrder, dropListFrame.Size, dropListFrame.BackgroundColor3 = 2, UDim2.new(1, 0, 0, 90), Color3.fromRGB(80,20,60); dropListFrame.BackgroundTransparency, dropListFrame.CanvasSize, dropListFrame.ScrollBarThickness, dropListFrame.Visible = 0, UDim2.new(0,0,0,0), 3, false
Corner(dropListFrame); Stroke(dropListFrame); RegTheme(dropListFrame, "DropFrame"); local dropLayout = Instance.new("UIListLayout", dropListFrame); dropLayout.Padding = UDim.new(0, 3)
Track(dropBtn.MouseButton1Click:Connect(function() dropListFrame.Visible = not dropListFrame.Visible end))
local function rebuildScriptDropdown()
    for _, c in ipairs(dropListFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i, scr in ipairs(RegisteredScripts) do
        local btn = CreateCustomButton(dropListFrame, " ▶ " .. scr.Name, "DropItem"); btn.LayoutOrder, btn.Size = i, UDim2.new(1, 0, 0, 22)
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        Track(btn.MouseButton1Click:Connect(function() State.SelectedScript = scr; _G.__vznam_log("INFO", "Chọn script auto load: " .. scr.Name); dropBtn.Text = " 📜 " .. scr.Name; dropListFrame.Visible = false; if State.IsAutoLoad then State.SetMenu(false); CurrentScriptLbl.Text = "🟢 Đang chạy: " .. scr.Name; pcall(scr.Callback) end end))
    end; dropListFrame.CanvasSize = UDim2.new(0, 0, 0, #RegisteredScripts * 25)
end
_G.__vznam_rebuildScriptDropdown = rebuildScriptDropdown; rebuildScriptDropdown()
local autoLoadScriptFrame = Instance.new("Frame", autoLoadContainer); autoLoadScriptFrame.LayoutOrder, autoLoadScriptFrame.Size, autoLoadScriptFrame.BackgroundColor3, autoLoadScriptFrame.BackgroundTransparency = 3, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70,15,50), 0
Corner(autoLoadScriptFrame); Stroke(autoLoadScriptFrame); RegTheme(autoLoadScriptFrame, "Primary")
local alsTitle = Instance.new("TextLabel", autoLoadScriptFrame); alsTitle.Size, alsTitle.Position, alsTitle.BackgroundTransparency, alsTitle.Text = UDim2.new(1, -40, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Auto Load Script Chạy"; alsTitle.TextColor3, alsTitle.TextSize, alsTitle.Font, alsTitle.TextXAlignment = Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
State.RowHint(autoLoadScriptFrame, alsTitle, "Bật để tự chạy script đã chọn", 45)
local toggleAutoBtn = Instance.new("TextButton", autoLoadScriptFrame); toggleAutoBtn.Size, toggleAutoBtn.Position, toggleAutoBtn.BackgroundColor3, toggleAutoBtn.Text = UDim2.new(0, 30, 0, 15), UDim2.new(1, -34, 0.5, -7.5), Color3.fromRGB(60,65,75), ""
Corner(toggleAutoBtn, UDim.new(1, 0)); Stroke(toggleAutoBtn); local autoDot = Instance.new("Frame", toggleAutoBtn); autoDot.Size, autoDot.Position, autoDot.BackgroundColor3 = UDim2.new(0, 11, 0, 11), UDim2.new(0, 2, 0.5, -5.5), Color3.fromRGB(255,255,255); Corner(autoDot, UDim.new(1, 0))
Track(toggleAutoBtn.MouseButton1Click:Connect(function() if not State.SelectedScript then _G.__vznam_log("WARNING", "Auto load: chưa chọn script!"); dropBtn.Text = " ⚠️ Chọn script trước!"; task.delay(1.5, function() if dropBtn.Parent then dropBtn.Text = " 📜 Chọn Script Auto Load..." end end); return end; State.IsAutoLoad = not State.IsAutoLoad; _G.__vznam_log("INFO", "Auto load script: " .. (State.IsAutoLoad and "BẬT" or "TẮT")); if State.IsAutoLoad then State.SlideToggle(toggleAutoBtn, autoDot, true, UDim2.new(1,-13,0.5,-5.5), UDim2.new(0,2,0.5,-5.5)); State.SetMenu(false); CurrentScriptLbl.Text = "🟢 Đang chạy: " .. State.SelectedScript.Name; pcall(State.SelectedScript.Callback) else State.SlideToggle(toggleAutoBtn, autoDot, false, UDim2.new(1,-13,0.5,-5.5), UDim2.new(0,2,0.5,-5.5)) end end))

-- NHẠC (FULL)
musicToggleBtn = CreateCustomButton(miscScroll, " ↓ âm nhạc", "Secondary"); musicToggleBtn.LayoutOrder, musicToggleBtn.Size = 3, UDim2.new(1, 0, 0, 34); State.AddHint(musicToggleBtn, "Ấn để mở/đóng mục này", 30)
musicContainer = Instance.new("Frame", miscScroll); musicContainer.LayoutOrder, musicContainer.Size, musicContainer.AutomaticSize, musicContainer.BackgroundTransparency, musicContainer.Visible = 4, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1, true
local muLayout = Instance.new("UIListLayout", musicContainer); muLayout.SortOrder, muLayout.Padding, muLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), Enum.HorizontalAlignment.Center
Track(musicToggleBtn.MouseButton1Click:Connect(function() musicContainer.Visible = not musicContainer.Visible; musicToggleBtn.Text = musicContainer.Visible and " ↓ âm nhạc" or " → âm nhạc" end))
HubSound = Instance.new("Sound", SoundService); HubSound.Name, HubSound.Looped, HubSound.Volume, HubSound.SoundId = "VzNamHubSound", true, State.Volume, "rbxassetid://" .. State.SoundId

local customIdBox = Instance.new("TextBox", musicContainer); customIdBox.LayoutOrder, customIdBox.Size = 1, UDim2.new(1, 0, 0, 26)
customIdBox.BackgroundColor3, customIdBox.BackgroundTransparency, customIdBox.PlaceholderText, customIdBox.Text = Color3.fromRGB(70,15,50), 0, "🎶 Nhập Sound ID...", ""
customIdBox.TextColor3, customIdBox.TextSize, customIdBox.Font = Color3.fromRGB(255,255,255), 9, Enum.Font.Gotham; Corner(customIdBox); Stroke(customIdBox); RegTheme(customIdBox, "Input")

local musicDropBtn = CreateCustomButton(musicContainer, " 🎵 Chọn Nhạc...", "Primary"); musicDropBtn.LayoutOrder, musicDropBtn.Size = 2, UDim2.new(1, 0, 0, 26); State.AddHint(musicDropBtn, "Ấn để chọn bài nhạc có sẵn")
local musicDropList = Instance.new("ScrollingFrame", musicContainer); musicDropList.LayoutOrder, musicDropList.Size, musicDropList.BackgroundColor3 = 3, UDim2.new(1, 0, 0, 95), Color3.fromRGB(80,20,60); musicDropList.BackgroundTransparency, musicDropList.CanvasSize, musicDropList.ScrollBarThickness, musicDropList.Visible = 0, UDim2.new(0,0,0,0), 3, false
Corner(musicDropList); Stroke(musicDropList); RegTheme(musicDropList, "DropFrame")
local musicListLayout = Instance.new("UIListLayout", musicDropList); musicListLayout.Padding = UDim.new(0, 3)

local presetMusics = { {Name = "🎵 Chill Lofi", Id = "1837879082"}, {Name = "🎶 Phonk Beat", Id = "1843404008"}, {Name = "🎵 Anime Relax", Id = "9043887091"}, {Name = "🎶 EDM Hype", Id = "1837871000"}, {Name = "🎶 Như Một Người Dưng", Id = "91897652967267"}, {Name = "🎶 chill 02", Id = "1848354536"}, {Name = "🎶 Backrooms", Id = "75544352326610"}, {Name = "🎶 Cool Hardtekk", Id = "90851490275942"}, {Name = "🎶 Dam Dam Di Di Di Di", Id = "82746224492420"}, {Name = "🎶 DJ Yang2 Remix", Id = "115189039255362"}, {Name = "🎶 Loop?", Id = "110829045185545"}, {Name = "🎶 Low Cortisol(AiDuaEmVe)", Id = "110919391228823"}, {Name = "🎶 JackPot", Id = "108531350726198"}, {Name = "🎶 OMGF-Hello", Id = "110788401793874"}, {Name = "🎶 NaTiGeTo", Id = "81496810882964"}, {Name = "🎶 Phonk(01)", Id = "120871403922972"}, {Name = "🎶 Electrosouls", Id = "84905694191715"} }
for i, m in ipairs(presetMusics) do local btn = CreateCustomButton(musicDropList, " " .. m.Name, "DropItem"); btn.LayoutOrder, btn.Size = i, UDim2.new(1, 0, 0, 22); Track(btn.MouseButton1Click:Connect(function() State.SoundId = m.Id; _G.__vznam_log("INFO", "Chọn nhạc: " .. m.Name .. " (ID " .. m.Id .. ")"); musicDropBtn.Text = " 🎵 " .. m.Name; musicDropList.Visible = false; if HubSound.IsPlaying then HubSound.SoundId = "rbxassetid://" .. State.SoundId; HubSound:Play() end end)) end
musicDropList.CanvasSize = UDim2.new(0, 0, 0, #presetMusics * 25); Track(musicDropBtn.MouseButton1Click:Connect(function() musicDropList.Visible = not musicDropList.Visible end))

local musicToggleFrame2 = Instance.new("Frame", musicContainer); musicToggleFrame2.LayoutOrder, musicToggleFrame2.Size, musicToggleFrame2.BackgroundColor3, musicToggleFrame2.BackgroundTransparency = 4, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70,15,50), 0
Corner(musicToggleFrame2); Stroke(musicToggleFrame2); RegTheme(musicToggleFrame2, "Primary")
local musicTitle = Instance.new("TextLabel", musicToggleFrame2); musicTitle.Size, musicTitle.Position, musicTitle.BackgroundTransparency, musicTitle.Text = UDim2.new(1, -40, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Phát Nhạc Nền"; musicTitle.TextColor3, musicTitle.TextSize, musicTitle.Font, musicTitle.TextXAlignment = Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
State.RowHint(musicToggleFrame2, musicTitle, "Bật để phát nhạc nền", 45)
local toggleMusicBtn = Instance.new("TextButton", musicToggleFrame2); toggleMusicBtn.Size, toggleMusicBtn.Position, toggleMusicBtn.BackgroundColor3, toggleMusicBtn.Text = UDim2.new(0, 30, 0, 15), UDim2.new(1, -34, 0.5, -7.5), Color3.fromRGB(60,65,75), ""
Corner(toggleMusicBtn, UDim.new(1, 0)); Stroke(toggleMusicBtn); local isMusicPlaying = false
local musicDot = Instance.new("Frame", toggleMusicBtn); musicDot.Size, musicDot.Position, musicDot.BackgroundColor3 = UDim2.new(0, 11, 0, 11), UDim2.new(0, 2, 0.5, -5.5), Color3.fromRGB(255,255,255); Corner(musicDot, UDim.new(1, 0))
Track(toggleMusicBtn.MouseButton1Click:Connect(function() 
    isMusicPlaying = not isMusicPlaying; _G.__vznam_log("INFO", "Nhạc nền: " .. (isMusicPlaying and "BẬT" or "TẮT"))
    if isMusicPlaying then 
        State.SlideToggle(toggleMusicBtn, musicDot, true, UDim2.new(1,-13,0.5,-5.5), UDim2.new(0,2,0.5,-5.5))
        local customId = tonumber(customIdBox.Text)
        HubSound.SoundId = "rbxassetid://" .. (customId and tostring(customId) or State.SoundId); _G.__vznam_log("INFO", "Phát nhạc ID: " .. (customId and tostring(customId) or State.SoundId)); if customIdBox.Text ~= "" and not customId then _G.__vznam_log("WARNING", "Sound ID không hợp lệ, dùng nhạc đã chọn") end
        HubSound:Play() 
    else 
        State.SlideToggle(toggleMusicBtn, musicDot, false, UDim2.new(1,-13,0.5,-5.5), UDim2.new(0,2,0.5,-5.5))
        HubSound:Stop() 
    end 
end))

-- THANH ÂM LƯỢNG
local volFrame = Instance.new("Frame", musicContainer); volFrame.LayoutOrder = 5; volFrame.Size, volFrame.BackgroundColor3, volFrame.BackgroundTransparency = UDim2.new(1, 0, 0, 26), Color3.fromRGB(70,15,50), 0
Corner(volFrame); Stroke(volFrame); RegTheme(volFrame, "Primary")
local volLabel = Instance.new("TextLabel", volFrame); volLabel.Size, volLabel.Position, volLabel.BackgroundTransparency, volLabel.Text, volLabel.TextColor3, volLabel.TextSize, volLabel.Font, volLabel.TextXAlignment = UDim2.new(1, -8, 1, 0), UDim2.new(0, 5, 0, 0), 1, "🔊 Âm lượng: " .. math.floor(State.Volume * 100) .. "%", Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
State.RowHint(volFrame, volLabel, "Kéo thanh để chỉnh âm lượng", 95)
local volBarBg = Instance.new("Frame", volFrame); volBarBg.Size, volBarBg.Position, volBarBg.BackgroundColor3 = UDim2.new(0, 80, 0, 8), UDim2.new(1, -86, 0.5, -4), Color3.fromRGB(90,25,65)
Corner(volBarBg, UDim.new(1, 0)); Stroke(volBarBg); RegTheme(volBarBg, "DropItem")
local volBarFill = Instance.new("Frame", volBarBg); volBarFill.Size, volBarFill.BackgroundColor3 = UDim2.new(State.Volume, 0, 1, 0), Color3.fromRGB(255,105,180); Corner(volBarFill, UDim.new(1, 0))
local volBtn = Instance.new("TextButton", volBarBg); volBtn.Size, volBtn.BackgroundTransparency, volBtn.Text = UDim2.new(1, 10, 1, 10), 1, ""
local adjustingVol = false
Track(volBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then adjustingVol = true end end))
Track(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if adjustingVol then _G.__vznam_log("INFO", "Âm lượng: " .. math.floor(State.Volume * 100) .. "%") end; adjustingVol = false end end))
Track(UserInputService.InputChanged:Connect(function(input) if adjustingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local absPos, absSize = volBarBg.AbsolutePosition.X, volBarBg.AbsoluteSize.X; local p = math.clamp((input.Position.X - absPos) / absSize, 0, 1); volBarFill.Size = UDim2.new(p, 0, 1, 0); State.Volume = p; HubSound.Volume = p; volLabel.Text = "🔊 Âm lượng: " .. math.floor(p * 100) .. "%" end end))

-- MÀU MENU
menuColorToggleBtn = CreateCustomButton(miscScroll, " ↓ màu menu", "Secondary"); menuColorToggleBtn.LayoutOrder, menuColorToggleBtn.Size = 5, UDim2.new(1, 0, 0, 34); State.AddHint(menuColorToggleBtn, "Ấn để mở/đóng mục này", 30)
menuColorContainer = Instance.new("Frame", miscScroll); menuColorContainer.LayoutOrder, menuColorContainer.Size, menuColorContainer.AutomaticSize, menuColorContainer.BackgroundTransparency, menuColorContainer.Visible = 6, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1, true
local mcLayout = Instance.new("UIListLayout", menuColorContainer); mcLayout.SortOrder, mcLayout.Padding, mcLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), Enum.HorizontalAlignment.Center
Track(menuColorToggleBtn.MouseButton1Click:Connect(function() menuColorContainer.Visible = not menuColorContainer.Visible; menuColorToggleBtn.Text = menuColorContainer.Visible and " ↓ màu menu" or " → màu menu" end))
local menuThemeList = { {Name = "🌸 Hồng Pastel", Bg = Color3.fromRGB(70, 15, 50)}, {Name = "🌙 Đêm Đen Sâu", Bg = Color3.fromRGB(15, 16, 22)}, {Name = "🔥 Đỏ Lửa", Bg = Color3.fromRGB(70, 10, 15)}, {Name = "🌊 Xanh Đại Dương", Bg = Color3.fromRGB(10, 22, 50)} }
function ApplyTheme(newBaseColor) State.ThemeBase = newBaseColor; local primary, secondary, dropFrame, dropItem, input = newBaseColor:Lerp(Color3.new(1,1,1), 0.08), newBaseColor:Lerp(Color3.new(1,1,1), 0.15), newBaseColor:Lerp(Color3.new(1,1,1), 0.2), newBaseColor:Lerp(Color3.new(1,1,1), 0.3), newBaseColor:Lerp(Color3.new(0,0,0), 0.4); SidebarPanel.BackgroundColor3, ContentContainer.BackgroundColor3 = newBaseColor, newBaseColor; for _, o in ipairs(OuterPieces) do o.BackgroundColor3 = newBaseColor end; for _, item in ipairs(ThemedElements) do local el = item.Element; if el and el.Parent then if item.Type == "Primary" then el.BackgroundColor3 = primary elseif item.Type == "Secondary" then el.BackgroundColor3 = secondary elseif item.Type == "DropFrame" then el.BackgroundColor3 = dropFrame elseif item.Type == "DropItem" then el.BackgroundColor3 = dropItem elseif item.Type == "Input" then el.BackgroundColor3 = input end end end end
local themeDropBtn = CreateCustomButton(menuColorContainer, " 🎨 Theme: 🌊 Xanh Đại Dương", "Primary"); themeDropBtn.LayoutOrder, themeDropBtn.Size = 1, UDim2.new(1, 0, 0, 26); State.AddHint(themeDropBtn, "Ấn để đổi màu menu")
local themeDropList = Instance.new("ScrollingFrame", menuColorContainer); themeDropList.LayoutOrder, themeDropList.Size, themeDropList.BackgroundColor3 = 2, UDim2.new(1, 0, 0, 95), Color3.fromRGB(80,20,60); themeDropList.BackgroundTransparency, themeDropList.CanvasSize, themeDropList.ScrollBarThickness, themeDropList.Visible = 0, UDim2.new(0,0,0,0), 3, false
Corner(themeDropList); Stroke(themeDropList); RegTheme(themeDropList, "DropFrame")
local themeListLayout = Instance.new("UIListLayout", themeDropList); themeListLayout.Padding = UDim.new(0, 3)

for i, th in ipairs(menuThemeList) do local btn = CreateCustomButton(themeDropList, " " .. th.Name, "DropItem"); btn.LayoutOrder, btn.Size = i, UDim2.new(1, 0, 0, 22); Track(btn.MouseButton1Click:Connect(function() themeDropBtn.Text = " 🎨 Theme: " .. th.Name; themeDropList.Visible = false; _G.__vznam_log("INFO", "Đổi theme: " .. th.Name); ApplyTheme(th.Bg) end)) end
themeDropList.CanvasSize = UDim2.new(0, 0, 0, #menuThemeList * 25); Track(themeDropBtn.MouseButton1Click:Connect(function() themeDropList.Visible = not themeDropList.Visible end))

local transFrame = Instance.new("Frame", menuColorContainer); transFrame.LayoutOrder, transFrame.Size, transFrame.BackgroundColor3, transFrame.BackgroundTransparency = 3, UDim2.new(1, 0, 0, 26), Color3.fromRGB(70,15,50), 0
Corner(transFrame); Stroke(transFrame); RegTheme(transFrame, "Primary")
local transLabel = Instance.new("TextLabel", transFrame); transLabel.Size, transLabel.Position, transLabel.BackgroundTransparency, transLabel.Text, transLabel.TextColor3, transLabel.TextSize, transLabel.Font, transLabel.TextXAlignment = UDim2.new(1, -8, 1, 0), UDim2.new(0, 5, 0, 0), 1, "✨ Trong suốt: 0%", Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
State.RowHint(transFrame, transLabel, "Kéo thanh để chỉnh độ trong suốt", 95)
local transBarBg = Instance.new("Frame", transFrame); transBarBg.Size, transBarBg.Position, transBarBg.BackgroundColor3 = UDim2.new(0, 80, 0, 8), UDim2.new(1, -86, 0.5, -4), Color3.fromRGB(90,25,65)
Corner(transBarBg, UDim.new(1, 0)); Stroke(transBarBg); RegTheme(transBarBg, "DropItem")
local transBarFill = Instance.new("Frame", transBarBg); transBarFill.Size, transBarFill.BackgroundColor3 = UDim2.new(0, 0, 1, 0), Color3.fromRGB(255,105,180); Corner(transBarFill, UDim.new(1, 0))
local transBtn = Instance.new("TextButton", transBarBg); transBtn.Size, transBtn.BackgroundTransparency, transBtn.Text = UDim2.new(1, 10, 1, 10), 1, ""
function SetPanelAlpha(p)
    State.Transparent = p
    transBarFill.Size = UDim2.new(p, 0, 1, 0)
    SidebarPanel.BackgroundTransparency = p
    ContentContainer.BackgroundTransparency = p
    transLabel.Text = "✨ Trong suốt: " .. math.floor(p * 100) .. "%"
end
local adjustingTrans = false
Track(transBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then adjustingTrans = true end end))
Track(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if adjustingTrans then _G.__vznam_log("INFO", "Độ trong suốt: " .. math.floor(State.Transparent * 100) .. "%") end; adjustingTrans = false end end))
Track(UserInputService.InputChanged:Connect(function(input) if adjustingTrans and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local absPos, absSize = transBarBg.AbsolutePosition.X, transBarBg.AbsoluteSize.X; local p = math.clamp((input.Position.X - absPos) / absSize, 0, 1); SetPanelAlpha(p) end end))

-- THANH TRONG SUỐT KHUNG NGOÀI
local outerFrame = Instance.new("Frame", menuColorContainer); outerFrame.LayoutOrder, outerFrame.Size, outerFrame.BackgroundColor3, outerFrame.BackgroundTransparency = 12, UDim2.new(1, 0, 0, 26), Color3.fromRGB(70,15,50), 0
Corner(outerFrame); Stroke(outerFrame); RegTheme(outerFrame, "Primary")
local outerLabel = Instance.new("TextLabel", outerFrame); outerLabel.Size, outerLabel.Position, outerLabel.BackgroundTransparency, outerLabel.Text, outerLabel.TextColor3, outerLabel.TextSize, outerLabel.Font, outerLabel.TextXAlignment = UDim2.new(1, -8, 1, 0), UDim2.new(0, 5, 0, 0), 1, "🪟 Khung ngoài: 100%", Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
State.RowHint(outerFrame, outerLabel, "Kéo thanh để chỉnh khung ngoài", 95)
local outerBarBg = Instance.new("Frame", outerFrame); outerBarBg.Size, outerBarBg.Position, outerBarBg.BackgroundColor3 = UDim2.new(0, 80, 0, 8), UDim2.new(1, -86, 0.5, -4), Color3.fromRGB(90,25,65)
Corner(outerBarBg, UDim.new(1, 0)); Stroke(outerBarBg); RegTheme(outerBarBg, "DropItem")
local outerBarFill = Instance.new("Frame", outerBarBg); outerBarFill.Size, outerBarFill.BackgroundColor3 = UDim2.new(1, 0, 1, 0), Color3.fromRGB(255,105,180); Corner(outerBarFill, UDim.new(1, 0))
local outerBtn = Instance.new("TextButton", outerBarBg); outerBtn.Size, outerBtn.BackgroundTransparency, outerBtn.Text = UDim2.new(1, 10, 1, 10), 1, ""
local OuterClip = Instance.new("Frame", MainFrame)
OuterClip.Name, OuterClip.Size, OuterClip.BackgroundTransparency, OuterClip.BorderSizePixel, OuterClip.ZIndex = "OuterClip", UDim2.new(1, 0, 1, 0), 1, 0, 0
local OuterPieceDefs = {
    {UDim2.new(0, 4, 0, 0),         UDim2.new(1, -8, 0, 1)},
    {UDim2.new(0, 3, 0, 1),         UDim2.new(1, -6, 0, 1)},
    {UDim2.new(0, 2, 0, 2),         UDim2.new(1, -4, 0, 1)},
    {UDim2.new(0, 1, 0, 3),         UDim2.new(1, -2, 0, 2)},
    {UDim2.new(0, 0, 0, 5),         UDim2.new(1, 0, 0, 23)},
    {UDim2.new(0, 0, 1, -6),        UDim2.new(1, 0, 0, 2)},
    {UDim2.new(0, 1, 1, -4),        UDim2.new(1, -2, 0, 1)},
    {UDim2.new(0, 2, 1, -3),        UDim2.new(1, -4, 0, 1)},
    {UDim2.new(0, 3, 1, -2),        UDim2.new(1, -6, 0, 1)},
    {UDim2.new(0, 4, 1, -1),        UDim2.new(1, -8, 0, 1)},
    {UDim2.new(0, 0, 0, 28),        UDim2.new(0, 6, 1, -34)},
    {UDim2.new(0.3, 2, 0, 28),      UDim2.new(0.015, -2, 1, -34)},
    {UDim2.new(0.995, -4, 0, 28),   UDim2.new(0.005, 4, 1, -34)},
}
for _, d in ipairs(OuterPieceDefs) do
    local f = Instance.new("Frame", OuterClip)
    f.Position, f.Size, f.BackgroundColor3, f.BackgroundTransparency, f.BorderSizePixel, f.ZIndex = d[1], d[2], State.ThemeBase, 1, 0, 0
    if d[3] then Corner(f, UDim.new(0, 8)) end
    table.insert(OuterPieces, f)
end
function SetOuterAlpha(p)
    State.OuterTransparent = p
    for _, f in ipairs(OuterPieces) do f.BackgroundTransparency = p end
    outerBarFill.Size = UDim2.new(p, 0, 1, 0)
    outerLabel.Text = "🪟 Khung ngoài: " .. math.floor(p * 100) .. "%"
end
local adjustingOuter = false
Track(outerBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then adjustingOuter = true end end))
Track(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if adjustingOuter then _G.__vznam_log("INFO", "Độ trong suốt khung ngoài: " .. math.floor(State.OuterTransparent * 100) .. "%") end; adjustingOuter = false end end))
Track(UserInputService.InputChanged:Connect(function(input) if adjustingOuter and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local p = math.clamp((input.Position.X - outerBarBg.AbsolutePosition.X) / outerBarBg.AbsoluteSize.X, 0, 1); SetOuterAlpha(p) end end))

local colorList = { {Name = "🔵 Xanh Dương", Color = Color3.fromRGB(0, 191, 255)}, {Name = "🌈 Cầu Vồng (Rainbow)", Color = "Rainbow"}, {Name = "🌸 Hồng Kẹo", Color = Color3.fromRGB(255, 105, 180)}, {Name = "🔴 Đỏ Đậm", Color = Color3.fromRGB(220, 20, 60)}, {Name = "❌ Không Viền", Color = "None"} }
local colorDropBtn = CreateCustomButton(menuColorContainer, " 🎨 Viền: 🔵 Xanh Dương", "Primary"); colorDropBtn.LayoutOrder, colorDropBtn.Size = 4, UDim2.new(1, 0, 0, 26); State.AddHint(colorDropBtn, "Ấn để đổi màu viền menu")
local colorDropList = Instance.new("ScrollingFrame", menuColorContainer); colorDropList.LayoutOrder, colorDropList.Size, colorDropList.BackgroundColor3 = 5, UDim2.new(1, 0, 0, 95), Color3.fromRGB(80,20,60); colorDropList.BackgroundTransparency, colorDropList.CanvasSize, colorDropList.ScrollBarThickness, colorDropList.Visible = 0, UDim2.new(0,0,0,0), 3, false
Corner(colorDropList); Stroke(colorDropList); RegTheme(colorDropList, "DropFrame")
local colorListLayout = Instance.new("UIListLayout", colorDropList); colorListLayout.Padding = UDim.new(0, 3)

-- ===== MỤC "MÀU CHỮ" =====
do
local textToggleBtn = CreateCustomButton(miscScroll, " ↓ màu chữ", "Secondary")
textToggleBtn.LayoutOrder, textToggleBtn.Size = 7, UDim2.new(1, 0, 0, 34); State.AddHint(textToggleBtn, "Ấn để mở/đóng mục này", 30)
local textContainer = Instance.new("Frame", miscScroll)
textContainer.LayoutOrder, textContainer.Size, textContainer.AutomaticSize, textContainer.BackgroundTransparency, textContainer.Visible = 8, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1, true
local tcLayout = Instance.new("UIListLayout", textContainer)
tcLayout.SortOrder, tcLayout.Padding, tcLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), Enum.HorizontalAlignment.Center
Track(textToggleBtn.MouseButton1Click:Connect(function()
    textContainer.Visible = not textContainer.Visible; _G.__vznam_log("INFO", (textContainer.Visible and "Mở mục: " or "Đóng mục: ") .. "màu chữ")
    textToggleBtn.Text = textContainer.Visible and " ↓ màu chữ" or " → màu chữ"
end))
textContainer.Visible = false
textToggleBtn.Text = " → màu chữ"

local cur = {r = 255, g = 255, b = 255}
local sliderSetters = {}
local function pushColor()
    State.TextMode = "Solid"
    if ApplyTextColor then ApplyTextColor(Color3.fromRGB(cur.r, cur.g, cur.b)) end
end
local function setAll(r, g, b)
    cur.r, cur.g, cur.b = r, g, b
    for _, s in pairs(sliderSetters) do s() end
end

local previewFrame = Instance.new("Frame", textContainer)
previewFrame.LayoutOrder, previewFrame.Size, previewFrame.BackgroundColor3, previewFrame.BackgroundTransparency = 1, UDim2.new(1, 0, 0, 26), Color3.fromRGB(70, 15, 50), 0
Corner(previewFrame); Stroke(previewFrame); RegTheme(previewFrame, "Primary")
local previewLbl = Instance.new("TextLabel", previewFrame)
previewLbl.Size, previewLbl.Position, previewLbl.BackgroundTransparency, previewLbl.Text = UDim2.new(1, -10, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Aa Xem trước"
previewLbl.TextColor3, previewLbl.TextSize, previewLbl.Font, previewLbl.TextXAlignment = Color3.fromRGB(255, 255, 255), 10, Enum.Font.GothamBold, Enum.TextXAlignment.Left

local presets = {
    {Name = "⚪ Trắng", C = {255, 255, 255}}, {Name = "🔵 Xanh Dương", C = {0, 191, 255}}, {Name = "🌸 Hồng Kẹo", C = {255, 105, 180}},
    {Name = "🟡 Vàng", C = {255, 215, 0}}, {Name = "🟢 Xanh Lá", C = {80, 255, 80}}, {Name = "🟠 Cam", C = {255, 150, 50}},
    {Name = "🔴 Đỏ", C = {255, 70, 70}}, {Name = "🌈 Cầu Vồng", C = "Rainbow"},
}
local presetBtn = CreateCustomButton(textContainer, " 🎨 Màu chữ: ⚪ Trắng", "Primary")
presetBtn.LayoutOrder, presetBtn.Size = 2, UDim2.new(1, 0, 0, 26); State.AddHint(presetBtn, "Ấn để chọn màu chữ có sẵn")
local presetList = Instance.new("ScrollingFrame", textContainer)
presetList.LayoutOrder, presetList.Size, presetList.BackgroundColor3 = 3, UDim2.new(1, 0, 0, 95), Color3.fromRGB(80, 20, 60)
presetList.BackgroundTransparency, presetList.CanvasSize, presetList.ScrollBarThickness, presetList.Visible = 0, UDim2.new(0, 0, 0, #presets * 25), 3, false
Corner(presetList); Stroke(presetList); RegTheme(presetList, "DropFrame")
local plLayout = Instance.new("UIListLayout", presetList); plLayout.Padding = UDim.new(0, 3)
for i, p in ipairs(presets) do
    local b = CreateCustomButton(presetList, " " .. p.Name, "DropItem"); b.LayoutOrder, b.Size = i, UDim2.new(1, 0, 0, 22)
    Track(b.MouseButton1Click:Connect(function()
        presetBtn.Text = " 🎨 Màu chữ: " .. p.Name; presetList.Visible = false; _G.__vznam_log("INFO", "Đổi màu chữ: " .. p.Name)
        if p.C == "Rainbow" then State.TextMode = "Rainbow"
        else setAll(p.C[1], p.C[2], p.C[3]); pushColor() end
    end))
end
Track(presetBtn.MouseButton1Click:Connect(function() presetList.Visible = not presetList.Visible end))

local function MakeSlider(order, name, key, fillColor)
    local f = Instance.new("Frame", textContainer)
    f.LayoutOrder, f.Size, f.BackgroundColor3, f.BackgroundTransparency = order, UDim2.new(1, 0, 0, 26), Color3.fromRGB(70, 15, 50), 0
    Corner(f); Stroke(f); RegTheme(f, "Primary")
    local lbl = Instance.new("TextLabel", f)
    lbl.Size, lbl.Position, lbl.BackgroundTransparency = UDim2.new(1, -100, 1, 0), UDim2.new(0, 5, 0, 0), 1
    lbl.TextColor3, lbl.TextSize, lbl.Font, lbl.TextXAlignment = Color3.fromRGB(255, 255, 255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
    State.RowHint(f, lbl, "Kéo thanh để chỉnh màu", 95)
    local bg = Instance.new("Frame", f)
    bg.Size, bg.Position, bg.BackgroundColor3 = UDim2.new(0, 80, 0, 8), UDim2.new(1, -86, 0.5, -4), Color3.fromRGB(90, 25, 65)
    Corner(bg, UDim.new(1, 0)); Stroke(bg); RegTheme(bg, "DropItem")
    local fill = Instance.new("Frame", bg)
    fill.Size, fill.BackgroundColor3 = UDim2.new(1, 0, 1, 0), fillColor; Corner(fill, UDim.new(1, 0))
    local btn = Instance.new("TextButton", bg)
    btn.Size, btn.Position, btn.BackgroundTransparency, btn.Text = UDim2.new(1, 10, 1, 10), UDim2.new(0, -5, 0, -5), 1, ""
    local function refresh()
        fill.Size = UDim2.new(cur[key] / 255, 0, 1, 0)
        lbl.Text = name .. ": " .. cur[key]
    end
    sliderSetters[key] = refresh
    refresh()
    local dragging = false
    local function update(input)
        local p = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        cur[key] = math.floor(p * 255 + 0.5)
        refresh(); pushColor()
        presetBtn.Text = " 🎨 Màu chữ: 🎯 Tùy chỉnh"
    end
    Track(btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input) end
    end))
    Track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if dragging then _G.__vznam_log("INFO", "Màu chữ tùy chỉnh: R" .. cur.r .. " G" .. cur.g .. " B" .. cur.b) end; dragging = false end
    end))
    Track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end))
end
MakeSlider(4, "R", "r", Color3.fromRGB(255, 70, 70))
MakeSlider(5, "G", "g", Color3.fromRGB(80, 255, 80))
MakeSlider(6, "B", "b", Color3.fromRGB(70, 140, 255))

local hexBox = Instance.new("TextBox", textContainer)
hexBox.LayoutOrder, hexBox.Size = 7, UDim2.new(1, 0, 0, 26)
hexBox.BackgroundColor3, hexBox.BackgroundTransparency, hexBox.PlaceholderText, hexBox.Text = Color3.fromRGB(70, 15, 50), 0, "🎨 Nhập mã màu (#FF66AA hoặc 255,100,170) rồi Enter...", ""
hexBox.PlaceholderColor3, hexBox.TextColor3, hexBox.TextSize, hexBox.Font, hexBox.ClearTextOnFocus, hexBox.ClipsDescendants = Color3.fromRGB(150, 155, 165), Color3.fromRGB(255, 255, 255), 8, Enum.Font.Gotham, false, true
Corner(hexBox); Stroke(hexBox); RegTheme(hexBox, "Input")
Track(hexBox.FocusLost:Connect(function(enter)
    if not enter then return end
    local t = hexBox.Text:gsub("%s", "")
    local r, g, b
    local hex = t:match("^#?(%x%x%x%x%x%x)$")
    if hex then
        r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
    else
        local rr, gg, bb = t:match("^(%d+),(%d+),(%d+)$")
        if rr then r, g, b = math.clamp(tonumber(rr), 0, 255), math.clamp(tonumber(gg), 0, 255), math.clamp(tonumber(bb), 0, 255) end
    end
    if r then _G.__vznam_log("INFO", "Nhập mã màu chữ: " .. t .. " → " .. r .. "," .. g .. "," .. b); setAll(r, g, b); pushColor(); presetBtn.Text = " 🎨 Màu chữ: 🎯 Tùy chỉnh"
    else _G.__vznam_log("WARNING", "Mã màu không hợp lệ!") end
end))

-- ===== KIỂU CHỮ (font) =====
local function F(n) local ok, v = pcall(function() return Enum.Font[n] end) return ok and v or nil end
local fontDefs = {
    {Id = "Default", Name = "⚪ Mặc định (Gotham)"},
    {Id = "SourceSans", Name = "Source Sans", R = "SourceSans", B = "SourceSansBold"},
    {Id = "Arial", Name = "Arial", R = "Arial", B = "ArialBold"},
    {Id = "Roboto", Name = "Roboto", R = "Roboto"},
    {Id = "Nunito", Name = "Nunito", R = "Nunito"},
    {Id = "Ubuntu", Name = "Ubuntu", R = "Ubuntu"},
    {Id = "Oswald", Name = "Oswald", R = "Oswald"},
    {Id = "TitilliumWeb", Name = "Titillium Web", R = "TitilliumWeb"},
    {Id = "JosefinSans", Name = "Josefin Sans", R = "JosefinSans"},
    {Id = "Merriweather", Name = "Merriweather (serif)", R = "Merriweather"},
    {Id = "Garamond", Name = "Garamond (serif)", R = "Garamond"},
    {Id = "Code", Name = "Code (monospace)", R = "Code"},
    {Id = "Cartoon", Name = "Cartoon", R = "Cartoon"},
    {Id = "Fantasy", Name = "Fantasy", R = "Fantasy"},
    {Id = "SciFi", Name = "SciFi", R = "SciFi"},
    {Id = "Bangers", Name = "Bangers", R = "Bangers"},
    {Id = "FredokaOne", Name = "Fredoka One", R = "FredokaOne"},
    {Id = "PatrickHand", Name = "Patrick Hand (viết tay)", R = "PatrickHand"},
    {Id = "IndieFlower", Name = "Indie Flower (viết tay)", R = "IndieFlower"},
    {Id = "PermanentMarker", Name = "Permanent Marker", R = "PermanentMarker"},
    {Id = "LuckiestGuy", Name = "Luckiest Guy", R = "LuckiestGuy"},
}
local fonts, fontById = {}, {}
for _, d in ipairs(fontDefs) do
    if d.Id ~= "Default" then
        d.Reg = F(d.R); d.Bold = F(d.B or d.R) or d.Reg
    end
    if d.Id == "Default" or d.Reg then table.insert(fonts, d); fontById[d.Id] = d end
end
local fontBtn = CreateCustomButton(textContainer, " 🔤 Kiểu chữ: ⚪ Mặc định (Gotham)", "Primary")
fontBtn.LayoutOrder, fontBtn.Size = 8, UDim2.new(1, 0, 0, 26); State.AddHint(fontBtn, "Ấn để đổi kiểu chữ")
local fontList = Instance.new("ScrollingFrame", textContainer)
fontList.LayoutOrder, fontList.Size, fontList.BackgroundColor3 = 9, UDim2.new(1, 0, 0, 110), Color3.fromRGB(80, 20, 60)
fontList.BackgroundTransparency, fontList.CanvasSize, fontList.ScrollBarThickness, fontList.Visible = 0, UDim2.new(0, 0, 0, #fonts * 25), 3, false
Corner(fontList); Stroke(fontList); RegTheme(fontList, "DropFrame")
local flLayout = Instance.new("UIListLayout", fontList); flLayout.Padding = UDim.new(0, 3)
for i, d in ipairs(fonts) do
    local b = CreateCustomButton(fontList, " " .. d.Name, "DropItem"); b.LayoutOrder, b.Size = i, UDim2.new(1, 0, 0, 22)
    b:SetAttribute("NoFont", true)
    if d.Reg then b.Font = d.Reg end
    Track(b.MouseButton1Click:Connect(function() fontList.Visible = false; _G.__vznam_log("INFO", "Đổi kiểu chữ: " .. d.Name); SetFontById(d.Id) end))
end
SetFontById = function(id)
    local d = fontById[id] or fontById.Default
    State.FontId = d.Id
    fontBtn.Text = " 🔤 Kiểu chữ: " .. d.Name
    if ApplyFont then ApplyFont(d.Reg and d or nil) end
end
Track(fontBtn.MouseButton1Click:Connect(function() fontList.Visible = not fontList.Visible end))
end

-- CHỌN NỀN: ẢNH TĨNH (ANIME) / NỀN ĐỘNG (CHUỖI ẢNH) / LINK RIÊNG / BÌNH THƯỜNG
do
local bgPresets = {
    {Name = "🌸 AnhNenGocCuaVzNam", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/main/IMG_20261024_125441.jpg"},
    {Name = "🌙 GaiAnimeLanhLung", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/e47b0b94d1f4ac19587156f744d0325e0db382e1/anh-anime-girl-lanh-lung-ngau-8.jpg"},
    {Name = "🔥 GaiAnimeCamMatNa", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/e47b0b94d1f4ac19587156f744d0325e0db382e1/anh-mo-ta.jpeg"},
    {Name = "👑 NagiBlueLock", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/e47b0b94d1f4ac19587156f744d0325e0db382e1/glitch-surge-isagis-blue-resolve.jpg"},
    {Name = "❤️‍🔥 GaiAnimeLanhLungNenDen", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/e47b0b94d1f4ac19587156f744d0325e0db382e1/hinh-nen-anime-202.jpg"},
    {Name = "🌊 NguoiNhen", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/d2b47b619d27079f0be794b7511ea6b4f49ff1bf/nguoinhen.jpeg"},
    {Name = "🤯 genshin", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/344532bbb0635d1141a44906aa0be138d64c886b/skirk-genshin-impact-4k-anime-wallpaper.jpg"},
    {Name = "🌜 Gojo", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/d2b47b619d27079f0be794b7511ea6b4f49ff1bf/IMG_20261101_214342.jpg"},
    {Name = "🌌 VuTru1", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/96009bfe72316154f2f9a50f750be9b015605d85/4k-black-hole-space-wallpaper.jpg"},
    {Name = "☄️ VuTru2", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/96009bfe72316154f2f9a50f750be9b015605d85/pngtree-vibrant-cosmic-black-hole-illustration-example-image_21843430.jpg"},
    {Name = "🛸 VuTru3", Url = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/96009bfe72316154f2f9a50f750be9b015605d85/hinh-nen-laptop-38-1440x720.jpg"},
}

local bgDropBtn = CreateCustomButton(menuColorContainer, " 🖼️ Nền: " .. bgPresets[1].Name, "Primary"); bgDropBtn.LayoutOrder, bgDropBtn.Size = 6, UDim2.new(1, 0, 0, 26); State.AddHint(bgDropBtn, "Ấn để chọn ảnh nền menu")
local bgDropList = Instance.new("ScrollingFrame", menuColorContainer); bgDropList.LayoutOrder, bgDropList.Size, bgDropList.BackgroundColor3 = 7, UDim2.new(1, 0, 0, 95), Color3.fromRGB(80,20,60); bgDropList.BackgroundTransparency, bgDropList.CanvasSize, bgDropList.ScrollBarThickness, bgDropList.Visible = 0, UDim2.new(0,0,0,0), 3, false
Corner(bgDropList); Stroke(bgDropList); RegTheme(bgDropList, "DropFrame")
local bgListLayout = Instance.new("UIListLayout", bgDropList); bgListLayout.Padding = UDim.new(0, 3)


local bgUrlBox = Instance.new("TextBox", menuColorContainer); bgUrlBox.LayoutOrder, bgUrlBox.Size = 10, UDim2.new(1, 0, 0, 26)
bgUrlBox.BackgroundColor3, bgUrlBox.BackgroundTransparency, bgUrlBox.PlaceholderText, bgUrlBox.Text = Color3.fromRGB(70,15,50), 0, "🔗 Dán link ảnh nền riêng rồi Enter...", ""
bgUrlBox.PlaceholderColor3, bgUrlBox.TextColor3, bgUrlBox.TextSize, bgUrlBox.Font, bgUrlBox.ClearTextOnFocus, bgUrlBox.ClipsDescendants = Color3.fromRGB(150,155,165), Color3.fromRGB(255,255,255), 8, Enum.Font.Gotham, false, true
Corner(bgUrlBox); Stroke(bgUrlBox); RegTheme(bgUrlBox, "Input")

local ELEMENT_ALPHA = 0.75
ApplyElementAlpha = function(el)
    if el and el:IsA("GuiObject") then
        local anime = State.Background ~= "Normal"
        el.BackgroundTransparency = anime and ELEMENT_ALPHA or 0
        if el:IsA("TextButton") or el:IsA("TextBox") then el.TextStrokeTransparency = anime and 0.4 or 1 end
    end
end

State.LastStatic, State.LastStaticUrl = "Normal", nil

-- Nhận dạng định dạng ảnh theo nội dung file (không tin đuôi link)
local function DetectExt(data)
    if type(data) ~= "string" or #data < 200 then return nil end
    local b1, b2, b3, b4 = data:byte(1, 4)
    if b1 == 0xFF and b2 == 0xD8 then return "jpg" end
    if b1 == 0x89 and b2 == 0x50 and b3 == 0x4E and b4 == 0x47 then return "png" end
    if data:sub(1, 4) == "RIFF" then return "webp" end
    return nil
end

local function GetAsset() return getcustomasset or getsynasset end

local function ApplyImage(url, file)
    task.spawn(function()
        local ok, err = pcall(function()
            local getasset = GetAsset()
            if not (writefile and getasset) then error("Executor không hỗ trợ writefile/getcustomasset") end
            _G.__vznam_log("INFO", "Đang tải nền: " .. tostring(url))
            local data = game:HttpGet(url, true)
            local ext = DetectExt(data)
            if not ext then error("link không phải ảnh hợp lệ") end
            local f = file:gsub("%.%w+$", "") .. "_" .. tostring(os.time()) .. "." .. ext
            writefile(f, data)
            _G.__vznam_log("SUCCESS", "Đã tải file nền: " .. f .. " (" .. #data .. " bytes)")
            local asset = getasset(f)
            if State.Background == "Normal" then return end
            for _, b in ipairs(BgImages) do b.Img.Visible = true; b.Img.Image = asset end
        end)
        if not ok then _G.__vznam_log("ERROR", "Không tải được nền: " .. tostring(err)) end
    end)
end

function SetBackground(mode, customUrl)
    if mode == "Anime" then mode = bgPresets[1].Name end
    if mode == "Custom" and (type(customUrl) ~= "string" or customUrl == "") then return end
    State.Background = mode; _G.__vznam_log("INFO", "Đổi nền: " .. tostring(mode))
    for _, item in ipairs(ThemedElements) do ApplyElementAlpha(item.Element) end

    if mode == "Normal" then
        bgDropBtn.Text = " 🖼️ Nền: ⬛ Bình Thường"
        State.LastStatic, State.LastStaticUrl = "Normal", nil
        for _, b in ipairs(BgImages) do b.Group.Visible = false end
        SetPanelAlpha(0)
        return
    end

    for _, b in ipairs(BgImages) do b.Group.Visible = true end
    UpdateBgLayout()
    task.defer(UpdateBgLayout)
    SetPanelAlpha(1)

    if mode == "Custom" then
        State.BackgroundUrl = customUrl
        State.LastStatic, State.LastStaticUrl = "Custom", customUrl
        bgDropBtn.Text = " 🖼️ Nền: 🔗 Link riêng"
        ApplyImage(customUrl, "VzNamHub_bg_custom.png")
        return
    end

    for i, p in ipairs(bgPresets) do
        if p.Name == mode then
            State.LastStatic, State.LastStaticUrl = mode, nil
            bgDropBtn.Text = " 🖼️ Nền: " .. p.Name
            ApplyImage(p.Url, "VzNamHub_bg_" .. i .. ".png")
            return
        end
    end

end

-- danh sách ảnh tĩnh
local bgItems = { {Name = "⬛ Bình Thường", Mode = "Normal"} }
for _, p in ipairs(bgPresets) do table.insert(bgItems, {Name = p.Name, Mode = p.Name}) end
for i, o in ipairs(bgItems) do local btn = CreateCustomButton(bgDropList, " " .. o.Name, "DropItem"); btn.LayoutOrder, btn.Size = i, UDim2.new(1, 0, 0, 22); Track(btn.MouseButton1Click:Connect(function() bgDropList.Visible = false; SetBackground(o.Mode) end)) end
bgDropList.CanvasSize = UDim2.new(0, 0, 0, #bgItems * 25); Track(bgDropBtn.MouseButton1Click:Connect(function() bgDropList.Visible = not bgDropList.Visible end))


Track(bgUrlBox.FocusLost:Connect(function(enter) if enter and bgUrlBox.Text ~= "" then SetBackground("Custom", bgUrlBox.Text) end end))
SetBackground(State.Background)
end

function UpdateAllStrokes(target) if target == "None" then for _, s in ipairs(AllUIStrokes) do if s then s.Transparency = 1 end end elseif target == "Rainbow" then for _, s in ipairs(AllUIStrokes) do if s then s.Transparency = 0 end end else State.StrokeColor = target; for _, s in ipairs(AllUIStrokes) do if s then s.Transparency = 0; s.Color = target end end end end
for i, cItem in ipairs(colorList) do local btn = CreateCustomButton(colorDropList, " " .. cItem.Name, "DropItem"); btn.LayoutOrder, btn.Size = i, UDim2.new(1, 0, 0, 22); Track(btn.MouseButton1Click:Connect(function() colorDropBtn.Text = " 🎨 Viền: " .. cItem.Name; colorDropList.Visible = false; _G.__vznam_log("INFO", "Đổi viền: " .. cItem.Name); if cItem.Color == "Rainbow" then State.StrokeMode = "Rainbow"; UpdateAllStrokes("Rainbow") elseif cItem.Color == "None" then State.StrokeMode = "None"; UpdateAllStrokes("None") else State.StrokeMode = "Solid"; UpdateAllStrokes(cItem.Color) end end)) end
colorDropList.CanvasSize = UDim2.new(0, 0, 0, #colorList * 25); Track(colorDropBtn.MouseButton1Click:Connect(function() colorDropList.Visible = not colorDropList.Visible end))
Track(RunService.RenderStepped:Connect(function() if State.StrokeMode ~= "Rainbow" then return end; local rainbow = Color3.fromHSV(tick() % 5 / 5, 1, 1); for _, s in ipairs(AllUIStrokes) do if s then s.Transparency = 0; s.Color = rainbow end end end))

end -- hết khối MISC
do -- khối CẤU HÌNH
-- 10. CẤU HÌNH
local tabConfigBtn = CreateCustomButton(SidebarScroll, " 📦 CẤU HÌNH", "Primary"); tabConfigBtn.LayoutOrder, tabConfigBtn.Size = 15, UDim2.new(1, 0, 0, 26)
tabConfigBtn:SetAttribute("OriginName", "📦 CẤU HÌNH")
local configIndicator = Instance.new("Frame", tabConfigBtn); configIndicator.Size, configIndicator.Position, configIndicator.BackgroundColor3, configIndicator.BorderSizePixel, configIndicator.Visible = UDim2.new(0, 3, 0, 12), UDim2.new(0, 0, 0.5, -6), Color3.fromRGB(255,105,180), 0, false; Corner(configIndicator, UDim.new(0, 2))
configScroll = Instance.new("ScrollingFrame", ContentContainer); configScroll.Size, configScroll.Position = UDim2.new(1, -12, 1, -29), UDim2.new(0, 6, 0, 28); configScroll.BackgroundTransparency, configScroll.BorderSizePixel, configScroll.ScrollBarThickness, configScroll.Visible, configScroll.ClipsDescendants = 1, 0, 3, false, true
local configLayout = Instance.new("UIListLayout", configScroll); configLayout.SortOrder, configLayout.Padding, configLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 5), Enum.HorizontalAlignment.Center
local cfgPad = Instance.new("UIPadding", configScroll); cfgPad.PaddingLeft, cfgPad.PaddingRight, cfgPad.PaddingTop = UDim.new(0,4), UDim.new(0,10), UDim.new(0,6)
Track(configLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() configScroll.CanvasSize = UDim2.new(0, 0, 0, configLayout.AbsoluteContentSize.Y + 15) end))
Track(tabConfigBtn.MouseButton1Click:Connect(function() for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end; configScroll.Visible, configIndicator.Visible = true, true; ActiveTabTitle.Text = TransDict[State.Language]["📦 CẤU HÌNH"] end))
table.insert(Tabs, {Container = configScroll, Indicator = configIndicator})

local function CreateSettingRow(parent, text, settingType, callback)
    local frame = Instance.new("Frame", parent); frame.Size, frame.BackgroundColor3 = UDim2.new(1, 0, 0, 30), Color3.fromRGB(70,15,50)
    Corner(frame); Stroke(frame); RegTheme(frame, "Primary")
    local lbl = Instance.new("TextLabel", frame); lbl.Size, lbl.Position, lbl.BackgroundTransparency, lbl.Text = UDim2.new(1, -60, 1, 0), UDim2.new(0, 10, 0, 0), 1, text
    lbl.TextColor3, lbl.TextSize, lbl.Font, lbl.TextXAlignment = Color3.fromRGB(255,255,255), 10, Enum.Font.Gotham, Enum.TextXAlignment.Left
    local hint = State.GetRowHint(text); if hint then State.RowHint(frame, lbl, hint, settingType == "label" and 110 or 50) end
    if settingType == "toggle" then
        local btn = Instance.new("TextButton", frame); btn.Size, btn.Position, btn.BackgroundColor3, btn.Text = UDim2.new(0, 36, 0, 18), UDim2.new(1, -46, 0.5, -9), Color3.fromRGB(60,65,75), ""
        Corner(btn, UDim.new(1,0)); Stroke(btn)
        local dot = Instance.new("Frame", btn); dot.Size, dot.Position, dot.BackgroundColor3 = UDim2.new(0, 12, 0, 12), UDim2.new(0, 2, 0.5, -6), Color3.fromRGB(255,255,255); Corner(dot, UDim.new(1,0))
        local state = false
        btn.MouseButton1Click:Connect(function() state = not state; State.SlideToggle(btn, dot, state, UDim2.new(1, -14, 0.5, -6), UDim2.new(0, 2, 0.5, -6)); _G.__vznam_log("INFO", "Cài đặt '" .. text .. "': " .. (state and "BẬT" or "TẮT")); if callback then callback(state) end end)
    elseif settingType == "label" then
        local valLbl = Instance.new("TextButton", frame); valLbl.Size, valLbl.Position, valLbl.BackgroundTransparency, valLbl.Text = UDim2.new(0, 150, 1, 0), UDim2.new(1, -160, 0, 0), 1, callback
        valLbl.TextColor3, valLbl.TextSize, valLbl.Font, valLbl.TextXAlignment = Color3.fromRGB(150,155,165), 9, Enum.Font.Gotham, Enum.TextXAlignment.Right
        valLbl.MouseButton1Click:Connect(function() 
            State.Language = State.Language == "VI" and "EN" or "VI"
            valLbl.Text = State.Language == "VI" and "VN → Tiếng Việt" or "EN → English"
            _G.__vznam_log("INFO", "Đổi ngôn ngữ: " .. State.Language); UpdateLanguageUI(State.Language)
        end)
    end
end

-- KHUNG LOG NỔI
local MiniLogContainer = Instance.new("Frame", ScreenGui); MiniLogContainer.Size, MiniLogContainer.Position = UDim2.new(0, 300, 0, 180), UDim2.new(0, 20, 1, -200); MiniLogContainer.BackgroundColor3, MiniLogContainer.BackgroundTransparency, MiniLogContainer.BorderSizePixel = Color3.fromRGB(15,16,22), 0.2, 0; MiniLogContainer.Visible = false; MiniLogContainer.Active = true; MiniLogContainer.Draggable = true
Corner(MiniLogContainer); Stroke(MiniLogContainer, Color3.fromRGB(0, 191, 255), 2)
local MiniLogTitle = Instance.new("TextLabel", MiniLogContainer); MiniLogTitle.Size, MiniLogTitle.BackgroundTransparency, MiniLogTitle.Text = UDim2.new(1, 0, 0, 20), 1, " 📊 Log Hệ Thống"; MiniLogTitle.TextColor3, MiniLogTitle.TextSize, MiniLogTitle.Font, MiniLogTitle.TextXAlignment = Color3.fromRGB(0, 191, 255), 10, Enum.Font.GothamBold, Enum.TextXAlignment.Left
_G.MiniLogScroll = Instance.new("ScrollingFrame", MiniLogContainer); _G.MiniLogScroll.Position, _G.MiniLogScroll.Size = UDim2.new(0, 4, 0, 20), UDim2.new(1, -8, 1, -24); _G.MiniLogScroll.BackgroundTransparency, _G.MiniLogScroll.BorderSizePixel, _G.MiniLogScroll.ScrollBarThickness = 1, 0, 3
local mlLayout = Instance.new("UIListLayout", _G.MiniLogScroll); mlLayout.Padding = UDim.new(0, 2); if _G.__vznam_replayLogs then _G.__vznam_replayLogs(_G.MiniLogScroll) end

local settingsToggleBtn = CreateCustomButton(configScroll, " → CÀI ĐẶT", "Secondary"); settingsToggleBtn.LayoutOrder, settingsToggleBtn.Size = 1, UDim2.new(1, 0, 0, 30); State.AddHint(settingsToggleBtn, "Ấn để mở/đóng mục này", 30)
local settingsContainer = Instance.new("Frame", configScroll); settingsContainer.LayoutOrder, settingsContainer.Size, settingsContainer.AutomaticSize, settingsContainer.BackgroundTransparency, settingsContainer.Visible = 2, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1, false
local stLayout = Instance.new("UIListLayout", settingsContainer); stLayout.Padding, stLayout.HorizontalAlignment = UDim.new(0, 4), Enum.HorizontalAlignment.Center
Track(settingsToggleBtn.MouseButton1Click:Connect(function() settingsContainer.Visible = not settingsContainer.Visible; _G.__vznam_log("INFO", (settingsContainer.Visible and "Mở mục: " or "Đóng mục: ") .. "cài đặt"); settingsToggleBtn.Text = settingsContainer.Visible and " ↓ CÀI ĐẶT" or " → CÀI ĐẶT" end))
CreateSettingRow(settingsContainer, "🌐 Ngôn ngữ / Language", "label", "VN → Tiếng Việt")
CreateSettingRow(settingsContainer, "Màn trắng (AFK)", "toggle", function(s) WhiteScreen.Visible = s end)
CreateSettingRow(settingsContainer, "Màn đen (AFK)", "toggle", function(s) BlackScreen.Visible = s end)
CreateSettingRow(settingsContainer, "📊 Khung log nổi", "toggle", function(s) MiniLogContainer.Visible = s end)

-- [MỚI] THANH TIỆN ÍCH: FPS / PING / CPU / GPU / RAM / TẢI MÁY (ước lượng)
do
    local Stats = game:GetService("Stats")

    -- hàng hiển thị trong Cài đặt
    local statRow = Instance.new("Frame", settingsContainer)
    statRow.Size, statRow.BackgroundColor3 = UDim2.new(1, 0, 0, 64), Color3.fromRGB(70,15,50)
    Corner(statRow); Stroke(statRow); RegTheme(statRow, "Primary")
    local statLbl = Instance.new("TextLabel", statRow)
    statLbl.Size, statLbl.Position, statLbl.BackgroundTransparency = UDim2.new(1, -10, 1, -6), UDim2.new(0, 5, 0, 3), 1
    statLbl.TextColor3, statLbl.TextSize, statLbl.Font = Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold
    statLbl.TextXAlignment, statLbl.TextYAlignment, statLbl.TextWrapped, statLbl.RichText = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, true, true
    statLbl.Text = "FPS: --"

    -- thanh nổi: tự co giãn theo độ dài chữ
    local floatBar = Instance.new("Frame", ScreenGui)
    floatBar.AnchorPoint = Vector2.new(0.5, 0)
    floatBar.Size, floatBar.Position = UDim2.new(0, 0, 0, 22), UDim2.new(0.5, 0, 0, 8)
    floatBar.AutomaticSize = Enum.AutomaticSize.X
    floatBar.BackgroundColor3, floatBar.BackgroundTransparency, floatBar.BorderSizePixel = Color3.fromRGB(15,16,22), 0.25, 0
    floatBar.Visible, floatBar.Active, floatBar.Draggable = false, true, true
    Corner(floatBar, UDim.new(0, 6)); Stroke(floatBar, Color3.fromRGB(0,191,255), 1)
    local fbPad = Instance.new("UIPadding", floatBar); fbPad.PaddingLeft, fbPad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
    local floatLbl = Instance.new("TextLabel", floatBar)
    floatLbl.Size, floatLbl.AutomaticSize, floatLbl.BackgroundTransparency, floatLbl.RichText = UDim2.new(0, 0, 1, 0), Enum.AutomaticSize.X, 1, true
    floatLbl.TextColor3, floatLbl.TextSize, floatLbl.Font, floatLbl.Text = Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, ""
    floatLbl.TextWrapped, floatLbl.TextTruncate = false, Enum.TextTruncate.None
    CreateSettingRow(settingsContainer, "📈 Thanh tiện ích nổi", "toggle", function(s) floatBar.Visible = s end)

    local function col(c, txt) return '<font color="rgb(' .. c .. ')">' .. txt .. '</font>' end
    local acc, frames = 0, 0
    Track(RunService.RenderStepped:Connect(function(dt)
        acc, frames = acc + dt, frames + 1
        if acc < 0.5 then return end
        local fps = math.floor(frames / acc + 0.5); acc, frames = 0, 0
        if not settingsContainer.Visible and not floatBar.Visible then return end
        local EN = State.Language == "EN"

        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local mem = 0
        pcall(function() mem = math.floor(Stats:GetTotalMemoryUsageMb()) end)
        local cpu, gpu
        pcall(function() cpu = Stats.PerformanceStats.CPU:GetValue() end)
        pcall(function() gpu = Stats.PerformanceStats.GPU:GetValue() end)

        -- mức tải ước lượng (KHÔNG phải nhiệt độ °C thật)
        local heatLoad = 0
        if cpu then heatLoad = math.max(heatLoad, cpu / 16.6) end
        if gpu then heatLoad = math.max(heatLoad, gpu / 16.6) end
        if fps < 60 then heatLoad = math.max(heatLoad, (60 - fps) / 60) end
        heatLoad = math.clamp(heatLoad, 0, 1)
        local lvl, lvlColor, lvlName
        if heatLoad < 0.5 then lvlColor, lvlName = "80,255,80", (EN and "🟢 Cool" or "🟢 Mát")
        elseif heatLoad < 0.8 then lvlColor, lvlName = "255,200,50", (EN and "🟡 Warm" or "🟡 Ấm")
        else lvlColor, lvlName = "255,85,85", (EN and "🔴 Hot" or "🔴 Nóng") end
        local pct = math.floor(heatLoad * 100)
        local heatLong = col(lvlColor, (EN and "Load: " or "Tải máy: ") .. lvlName .. (EN and " (est. " or " (ước lượng ") .. pct .. "%)")
        local heatShort = col(lvlColor, lvlName .. " " .. pct .. "%")

        local fc = fps >= 50 and "80,255,80" or (fps >= 30 and "255,200,50" or "255,85,85")
        local pc = ping <= 100 and "80,255,80" or (ping <= 200 and "255,200,50" or "255,85,85")
        local fpsT, pingT = col(fc, "FPS: " .. fps), col(pc, "Ping: " .. ping .. "ms")
        local cpuT = "CPU: " .. (cpu and (string.format("%.1f", cpu) .. "ms") or "N/A")
        local gpuT = "GPU: " .. (gpu and (string.format("%.1f", gpu) .. "ms") or "N/A")
        local ramT = "RAM: " .. mem .. "MB"
        local plT = (EN and "Players: " or "Người chơi: ") .. #Players:GetPlayers()

        statLbl.Text = fpsT .. "  |  " .. pingT .. "\n" .. cpuT .. "  |  " .. gpuT .. "\n" .. heatLong .. "\n" .. ramT .. "  |  " .. plT
        floatLbl.Text = fpsT .. "  |  " .. pingT .. "  |  " .. cpuT .. "  |  " .. ramT .. "  |  " .. heatShort
    end))
end

cfgToggleBtn = CreateCustomButton(configScroll, " ↓ CẤU HÌNH", "Secondary"); cfgToggleBtn.LayoutOrder, cfgToggleBtn.Size = 3, UDim2.new(1, 0, 0, 30); State.AddHint(cfgToggleBtn, "Ấn để mở/đóng mục này", 30)
mainConfigContainer = Instance.new("Frame", configScroll); mainConfigContainer.LayoutOrder, mainConfigContainer.Size, mainConfigContainer.AutomaticSize, mainConfigContainer.BackgroundTransparency, mainConfigContainer.Visible = 4, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1, true
local mainCfgLayout = Instance.new("UIListLayout", mainConfigContainer); mainCfgLayout.SortOrder, mainCfgLayout.Padding, mainCfgLayout.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), Enum.HorizontalAlignment.Center
Track(cfgToggleBtn.MouseButton1Click:Connect(function() mainConfigContainer.Visible = not mainConfigContainer.Visible; cfgToggleBtn.Text = mainConfigContainer.Visible and " ↓ CẤU HÌNH" or " → CẤU HÌNH" end))

local CONFIG_FOLDER = "VzNamHub_Configs"; if typeof(makefolder) == "function" then pcall(makefolder, CONFIG_FOLDER) end
local function SerializeState(sName) return {Version=4, SavedTime=os.time(), ThemeBase={State.ThemeBase.R, State.ThemeBase.G, State.ThemeBase.B}, StrokeMode=State.StrokeMode, StrokeColor={State.StrokeColor.R, State.StrokeColor.G, State.StrokeColor.B}, Volume=State.Volume, SoundId=State.SoundId, SelectedScript=sName, Transparent=State.Transparent, OuterTransparent=State.OuterTransparent or 1, Background=State.Background, BackgroundUrl=State.BackgroundUrl, TextColor={State.TextColor.R, State.TextColor.G, State.TextColor.B}, TextMode=State.TextMode, FontId=State.FontId} end
local function ValidateConfig(d) return type(d)=="table" and d.Version==4 end
local function SaveConfig(n) if typeof(writefile) ~= "function" then return false end return pcall(writefile, CONFIG_FOLDER.."/"..n..".json", HttpService:JSONEncode(SerializeState(State.SelectedScript and State.SelectedScript.Name or nil))) end
local function LoadConfigRaw(n) if typeof(readfile) ~= "function" then return false end local ok, c = pcall(readfile, CONFIG_FOLDER.."/"..n..".json"); if not ok or not c then return false end local ok2, d = pcall(HttpService.JSONDecode, HttpService, c); if not ok2 or not ValidateConfig(d) then return false end return true, d end

local startupFrame = Instance.new("Frame", mainConfigContainer); startupFrame.LayoutOrder, startupFrame.Size, startupFrame.BackgroundColor3, startupFrame.BackgroundTransparency = 1, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70,15,50), 0; Corner(startupFrame); Stroke(startupFrame); RegTheme(startupFrame, "Primary")
local startupLabel = Instance.new("TextLabel", startupFrame); startupLabel.Size, startupLabel.Position, startupLabel.BackgroundTransparency, startupLabel.Text, startupLabel.TextColor3, startupLabel.TextSize, startupLabel.Font, startupLabel.TextXAlignment = UDim2.new(1, -8, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Startup: "..State.CurrentConfig, Color3.fromRGB(255,255,255), 9, Enum.Font.Gotham, Enum.TextXAlignment.Left
local newConfigFrame = Instance.new("Frame", mainConfigContainer); newConfigFrame.LayoutOrder, newConfigFrame.Size, newConfigFrame.BackgroundColor3, newConfigFrame.BackgroundTransparency = 2, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70,15,50), 0; Corner(newConfigFrame); Stroke(newConfigFrame); RegTheme(newConfigFrame, "Primary")
local ncLabel = Instance.new("TextLabel", newConfigFrame); ncLabel.Size, ncLabel.Position, ncLabel.BackgroundTransparency, ncLabel.Text, ncLabel.TextColor3, ncLabel.TextSize, ncLabel.Font, ncLabel.TextXAlignment = UDim2.new(0, 80, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Tên Config", Color3.fromRGB(255,255,255), 9, Enum.Font.Gotham, Enum.TextXAlignment.Left
local configNameBox = Instance.new("TextBox", newConfigFrame); configNameBox.Size, configNameBox.Position, configNameBox.BackgroundColor3, configNameBox.BackgroundTransparency, configNameBox.PlaceholderText, configNameBox.Text, configNameBox.TextColor3, configNameBox.TextSize, configNameBox.Font = UDim2.new(1, -95, 0, 20), UDim2.new(0, 85, 0.5, -10), Color3.fromRGB(50,10,35), 0, "Name...", "", Color3.fromRGB(255,255,255), 9, Enum.Font.Gotham; Corner(configNameBox, UDim.new(0, 4)); Stroke(configNameBox); RegTheme(configNameBox, "Input")
local createFrame = Instance.new("Frame", mainConfigContainer); createFrame.LayoutOrder, createFrame.Size, createFrame.BackgroundColor3, createFrame.BackgroundTransparency = 3, UDim2.new(1, 0, 0, 34), Color3.fromRGB(70,15,50), 0; Corner(createFrame); Stroke(createFrame); RegTheme(createFrame, "Primary")
local crTitle = Instance.new("TextLabel", createFrame); crTitle.Size, crTitle.Position, crTitle.BackgroundTransparency, crTitle.Text, crTitle.TextColor3, crTitle.TextSize, crTitle.Font, crTitle.TextXAlignment = UDim2.new(1, -75, 0, 15), UDim2.new(0, 5, 0, 2), 1, "Tạo Mới Cấu Hình", Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
State.RowHint(createFrame, crTitle, "Nhập tên rồi ấn Create để tạo", 75)
local createBtn = Instance.new("TextButton", createFrame); createBtn.Size, createBtn.Position, createBtn.BackgroundColor3, createBtn.Text, createBtn.TextColor3, createBtn.TextSize, createBtn.Font = UDim2.new(0, 65, 0, 22), UDim2.new(1, -70, 0.5, -11), Color3.fromRGB(220,50,50), "Create", Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold; Corner(createBtn, UDim.new(0, 4)); Stroke(createBtn); RegTheme(createBtn, "DropItem")
local deleteFrame = Instance.new("Frame", mainConfigContainer); deleteFrame.LayoutOrder, deleteFrame.Size, deleteFrame.BackgroundColor3, deleteFrame.BackgroundTransparency = 4, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70,15,50), 0; Corner(deleteFrame); Stroke(deleteFrame); RegTheme(deleteFrame, "Primary")
local delLabel = Instance.new("TextLabel", deleteFrame); delLabel.Size, delLabel.Position, delLabel.BackgroundTransparency, delLabel.Text, delLabel.TextColor3, delLabel.TextSize, delLabel.Font, delLabel.TextXAlignment = UDim2.new(0, 80, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Xóa Cấu Hình", Color3.fromRGB(255,255,255), 9, Enum.Font.Gotham, Enum.TextXAlignment.Left
State.RowHint(deleteFrame, delLabel, "Chọn config cần xóa bên phải", 100)
local delBtn = Instance.new("TextButton", deleteFrame); delBtn.Size, delBtn.Position, delBtn.BackgroundColor3, delBtn.BackgroundTransparency, delBtn.Text, delBtn.TextColor3, delBtn.TextSize, delBtn.Font, delBtn.TextXAlignment = UDim2.new(0, 85, 0, 20), UDim2.new(1, -90, 0.5, -10), Color3.fromRGB(50,10,35), 0, "Không có ∨", Color3.fromRGB(50,200,50), 8, Enum.Font.GothamBold, Enum.TextXAlignment.Center; Corner(delBtn, UDim.new(0, 4)); Stroke(delBtn); RegTheme(delBtn, "Input")
local delDropFrame = Instance.new("ScrollingFrame", mainConfigContainer); delDropFrame.LayoutOrder, delDropFrame.Size, delDropFrame.BackgroundColor3 = 5, UDim2.new(1, 0, 0, 80), Color3.fromRGB(80,20,60); delDropFrame.BackgroundTransparency, delDropFrame.CanvasSize, delDropFrame.ScrollBarThickness, delDropFrame.Visible = 0, UDim2.new(0,0,0,0), 3, false; Corner(delDropFrame); Stroke(delDropFrame); RegTheme(delDropFrame, "DropFrame"); local delDropLayout = Instance.new("UIListLayout", delDropFrame); delDropLayout.Padding = UDim.new(0, 3)
local loadConfigFrame = Instance.new("Frame", mainConfigContainer); loadConfigFrame.LayoutOrder, loadConfigFrame.Size, loadConfigFrame.BackgroundColor3, loadConfigFrame.BackgroundTransparency = 6, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70,15,50), 0; Corner(loadConfigFrame); Stroke(loadConfigFrame); RegTheme(loadConfigFrame, "Primary")
local ldLabel = Instance.new("TextLabel", loadConfigFrame); ldLabel.Size, ldLabel.Position, ldLabel.BackgroundTransparency, ldLabel.Text, ldLabel.TextColor3, ldLabel.TextSize, ldLabel.Font, ldLabel.TextXAlignment = UDim2.new(0, 80, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Tải Config", Color3.fromRGB(255,255,255), 9, Enum.Font.Gotham, Enum.TextXAlignment.Left
State.RowHint(loadConfigFrame, ldLabel, "Chọn config cần tải bên phải", 100)
local ldBtn = Instance.new("TextButton", loadConfigFrame); ldBtn.Size, ldBtn.Position, ldBtn.BackgroundColor3, ldBtn.BackgroundTransparency, ldBtn.Text, ldBtn.TextColor3, ldBtn.TextSize, ldBtn.Font, ldBtn.TextXAlignment = UDim2.new(0, 85, 0, 20), UDim2.new(1, -90, 0.5, -10), Color3.fromRGB(50,10,35), 0, State.CurrentConfig.." ∨", Color3.fromRGB(50,200,50), 8, Enum.Font.GothamBold, Enum.TextXAlignment.Center; Corner(ldBtn, UDim.new(0, 4)); Stroke(ldBtn); RegTheme(ldBtn, "Input")
local ldDropFrame = Instance.new("ScrollingFrame", mainConfigContainer); ldDropFrame.LayoutOrder, ldDropFrame.Size, ldDropFrame.BackgroundColor3 = 7, UDim2.new(1, 0, 0, 80), Color3.fromRGB(80,20,60); ldDropFrame.BackgroundTransparency, ldDropFrame.CanvasSize, ldDropFrame.ScrollBarThickness, ldDropFrame.Visible = 0, UDim2.new(0,0,0,0), 3, false; Corner(ldDropFrame); Stroke(ldDropFrame); RegTheme(ldDropFrame, "DropFrame"); local ldDropLayout = Instance.new("UIListLayout", ldDropFrame); ldDropLayout.Padding = UDim.new(0, 3)
local saveFrame = Instance.new("Frame", mainConfigContainer); saveFrame.LayoutOrder, saveFrame.Size, saveFrame.BackgroundColor3, saveFrame.BackgroundTransparency = 8, UDim2.new(1, 0, 0, 34), Color3.fromRGB(70,15,50), 0; Corner(saveFrame); Stroke(saveFrame); RegTheme(saveFrame, "Primary")
local svTitle = Instance.new("TextLabel", saveFrame); svTitle.Size, svTitle.Position, svTitle.BackgroundTransparency, svTitle.Text, svTitle.TextColor3, svTitle.TextSize, svTitle.Font, svTitle.TextXAlignment = UDim2.new(1, -75, 0, 15), UDim2.new(0, 5, 0, 2), 1, "Lưu Cấu Hình", Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
local svSub = Instance.new("TextLabel", saveFrame); svSub.Size, svSub.Position, svSub.BackgroundTransparency, svSub.Text, svSub.TextColor3, svSub.TextSize, svSub.Font, svSub.TextXAlignment = UDim2.new(1, -75, 0, 14), UDim2.new(0, 5, 0, 17), 1, "Ấn Save để lưu vào: "..State.CurrentConfig, Color3.fromRGB(140,140,150), 7, Enum.Font.Gotham, Enum.TextXAlignment.Left
local saveBtn = Instance.new("TextButton", saveFrame); saveBtn.Size, saveBtn.Position, saveBtn.BackgroundColor3, saveBtn.Text, saveBtn.TextColor3, saveBtn.TextSize, saveBtn.Font = UDim2.new(0, 65, 0, 22), UDim2.new(1, -70, 0.5, -11), Color3.fromRGB(220,50,50), "Save", Color3.fromRGB(255,255,255), 9, Enum.Font.GothamBold; Corner(saveBtn, UDim.new(0, 4)); Stroke(saveBtn); RegTheme(saveBtn, "DropItem")

local function ApplyConfig(data) if type(data.FontId) == "string" and SetFontById then SetFontById(data.FontId) end; if data.TextMode == "Rainbow" then State.TextMode = "Rainbow" elseif type(data.TextColor) == "table" then State.TextMode = "Solid"; ApplyTextColor(Color3.new(data.TextColor[1], data.TextColor[2], data.TextColor[3])) end; if type(data.OuterTransparent) == "number" and SetOuterAlpha then SetOuterAlpha(math.clamp(data.OuterTransparent, 0, 1)) end; if data.Background and SetBackground then SetBackground(data.Background, data.BackgroundUrl) end; if type(data.Transparent) == "number" and SetPanelAlpha then SetPanelAlpha(math.clamp(data.Transparent, 0, 1)) end; if data.ThemeBase then ApplyTheme(Color3.new(data.ThemeBase[1], data.ThemeBase[2], data.ThemeBase[3])) end; if data.StrokeMode == "Rainbow" then State.StrokeMode = "Rainbow"; UpdateAllStrokes("Rainbow") elseif data.StrokeMode == "None" then State.StrokeMode = "None"; UpdateAllStrokes("None") elseif data.StrokeColor then State.StrokeMode = "Solid"; UpdateAllStrokes(Color3.new(data.StrokeColor[1], data.StrokeColor[2], data.StrokeColor[3])) end; if type(data.Volume) == "number" then State.Volume = math.clamp(data.Volume, 0, 1); HubSound.Volume = State.Volume end; if type(data.SoundId) == "string" then State.SoundId = data.SoundId; HubSound.SoundId = "rbxassetid://"..State.SoundId end; if data.SelectedScript then for _, scr in ipairs(RegisteredScripts) do if scr.Name == data.SelectedScript then State.SelectedScript = scr; _G.__vznam_log("INFO", "Chọn script auto load: " .. scr.Name); dropBtn.Text = " 📜 "..scr.Name; break end end end end
local function refreshAllDropdowns() for _, drop in ipairs({delDropFrame, ldDropFrame}) do for _, child in ipairs(drop:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end end; local filesList = {}; if typeof(listfiles) == "function" then local ok, files = pcall(listfiles, CONFIG_FOLDER); if ok and type(files) == "table" then for _, file in ipairs(files) do if type(file) == "string" and string.sub(file, -5) == ".json" then table.insert(filesList, string.sub(string.match(file, "[^/\\]+$") or file, 1, -6)) end end end end; if #filesList == 0 then delBtn.Text = "Không có ∨" end
    for _, name in ipairs(filesList) do local f1 = Instance.new("TextButton", delDropFrame); f1.Size, f1.BackgroundColor3, f1.BackgroundTransparency = UDim2.new(1, 0, 0, 22), State.ThemeBase:Lerp(Color3.new(1,1,1), 0.3), 0; f1.Text, f1.TextColor3, f1.TextSize, f1.Font, f1.TextXAlignment = " 🗑️ "..name, Color3.fromRGB(255,100,100), 9, Enum.Font.Gotham, Enum.TextXAlignment.Left; Corner(f1, UDim.new(0, 4)); Stroke(f1); RegTheme(f1, "DropItem"); Track(f1.MouseButton1Click:Connect(function() if typeof(delfile) == "function" then pcall(delfile, CONFIG_FOLDER.."/"..name..".json"); _G.__vznam_log("WARNING", "Đã xóa config: " .. name) else _G.__vznam_log("ERROR", "Executor không hỗ trợ delfile!") end; delBtn.Text = name.." ∨"; delDropFrame.Visible = false; refreshAllDropdowns() end))
        local f3 = Instance.new("TextButton", ldDropFrame); f3.Size, f3.BackgroundColor3, f3.BackgroundTransparency = UDim2.new(1, 0, 0, 22), State.ThemeBase:Lerp(Color3.new(1,1,1), 0.3), 0; f3.Text, f3.TextColor3, f3.TextSize, f3.Font, f3.TextXAlignment = " 📂 "..name, Color3.fromRGB(255,255,255), 9, Enum.Font.Gotham, Enum.TextXAlignment.Left; Corner(f3, UDim.new(0, 4)); Stroke(f3); RegTheme(f3, "DropItem"); Track(f3.MouseButton1Click:Connect(function() State.CurrentConfig = name; ldBtn.Text = name.." ∨"; svSub.Text = "Ấn Save để lưu vào: "..name; ldDropFrame.Visible = false; local ok, d = LoadConfigRaw(name); if ok then ApplyConfig(d); _G.__vznam_log("SUCCESS", "Đã tải config: " .. name) else _G.__vznam_log("ERROR", "Tải config '" .. name .. "' thất bại (file lỗi hoặc sai version)!") end end)) end
    delDropFrame.CanvasSize, ldDropFrame.CanvasSize = UDim2.new(0, 0, 0, #filesList * 25), UDim2.new(0, 0, 0, #filesList * 25) end

Track(delBtn.MouseButton1Click:Connect(function() refreshAllDropdowns(); delDropFrame.Visible = not delDropFrame.Visible; ldDropFrame.Visible = false end))
Track(ldBtn.MouseButton1Click:Connect(function() refreshAllDropdowns(); ldDropFrame.Visible = not ldDropFrame.Visible; delDropFrame.Visible = false end))
Track(createBtn.MouseButton1Click:Connect(function() local name = configNameBox.Text; if name == "" then _G.__vznam_log("WARNING", "Tạo config: chưa nhập tên!") elseif string.find(name, "[\\/:*?\"<>|]") then _G.__vznam_log("WARNING", "Tạo config: tên chứa ký tự không hợp lệ!") elseif typeof(writefile) ~= "function" then _G.__vznam_log("ERROR", "Executor không hỗ trợ writefile!") end; if name ~= "" and not string.find(name, "[\\/:*?\"<>|]") and typeof(writefile) == "function" then if SaveConfig(name) then _G.__vznam_log("SUCCESS", "Đã tạo config: " .. name); State.CurrentConfig = name; ldBtn.Text = name.." ∨"; svSub.Text = "Ấn Save để lưu vào: "..name; configNameBox.Text = ""; refreshAllDropdowns() end end end))
Track(saveBtn.MouseButton1Click:Connect(function() if SaveConfig(State.CurrentConfig) then svSub.Text = "Ấn Save để lưu vào: "..State.CurrentConfig; _G.__vznam_log("SUCCESS", "Đã lưu config: " .. State.CurrentConfig) else _G.__vznam_log("ERROR", "Lưu config thất bại (executor không hỗ trợ writefile?)") end end))

-- AUTO LOAD CẤU HÌNH
;(function()
    local AUTOCFG_FILE = "VzNamHub_AutoLoadConfig.json"
    State.AutoCfgName, State.AutoCfgEnabled = nil, false

    if typeof(readfile) == "function" then
        local ok, c = pcall(readfile, AUTOCFG_FILE)
        if ok and type(c) == "string" then
            local ok2, d = pcall(HttpService.JSONDecode, HttpService, c)
            if ok2 and type(d) == "table" then
                State.AutoCfgEnabled = d.Enabled == true
                if type(d.Name) == "string" and d.Name ~= "" then State.AutoCfgName = d.Name end
            end
        end
    end
    local function saveAuto()
        if typeof(writefile) ~= "function" then return end
        pcall(writefile, AUTOCFG_FILE, HttpService:JSONEncode({Enabled = State.AutoCfgEnabled, Name = State.AutoCfgName}))
    end
    local function pickText() return (State.AutoCfgName or "Chưa chọn") .. " ∨" end

    local function listNames()
        local names = {}
        if typeof(listfiles) == "function" then
            local ok, files = pcall(listfiles, CONFIG_FOLDER)
            if ok and type(files) == "table" then
                for _, f in ipairs(files) do
                    if type(f) == "string" and string.sub(f, -5) == ".json" then
                        table.insert(names, string.sub(string.match(f, "[^/\\]+$") or f, 1, -6))
                    end
                end
            end
        end
        return names
    end

    local function applyByName(name)
        local ok, d = LoadConfigRaw(name)
        if not ok then _G.__vznam_log("WARNING", "Auto Load: không tìm thấy cấu hình '" .. tostring(name) .. "'!"); return false end
        State.CurrentConfig = name
        ldBtn.Text = name .. " ∨"; svSub.Text = "Ấn Save để lưu vào: " .. name
        ApplyConfig(d)
        _G.__vznam_log("SUCCESS", "Đã tự động tải cấu hình: " .. name)
        return true
    end

    local row = Instance.new("Frame", mainConfigContainer)
    row.LayoutOrder, row.Size, row.BackgroundColor3, row.BackgroundTransparency = 9, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70, 15, 50), 0
    Corner(row); Stroke(row); RegTheme(row, "Primary")
    local rowTitle = Instance.new("TextLabel", row)
    rowTitle.Size, rowTitle.Position, rowTitle.BackgroundTransparency, rowTitle.Text = UDim2.new(1, -45, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Auto Load Cấu Hình"
    rowTitle.TextColor3, rowTitle.TextSize, rowTitle.Font, rowTitle.TextXAlignment = Color3.fromRGB(255, 255, 255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
    State.RowHint(row, rowTitle, "Bật để tự tải config khi mở hub", 45)
    local tgl = Instance.new("TextButton", row)
    tgl.Size, tgl.Position, tgl.BackgroundColor3, tgl.Text = UDim2.new(0, 30, 0, 15), UDim2.new(1, -34, 0.5, -7.5), Color3.fromRGB(60, 65, 75), ""
    Corner(tgl, UDim.new(1, 0)); Stroke(tgl)
    local dot = Instance.new("Frame", tgl)
    dot.Size, dot.Position, dot.BackgroundColor3 = UDim2.new(0, 11, 0, 11), UDim2.new(0, 2, 0.5, -5.5), Color3.fromRGB(255, 255, 255); Corner(dot, UDim.new(1, 0))
    local function paintToggle()
        State.SlideToggle(tgl, dot, State.AutoCfgEnabled, UDim2.new(1, -13, 0.5, -5.5), UDim2.new(0, 2, 0.5, -5.5))
    end

    local pickRow = Instance.new("Frame", mainConfigContainer)
    pickRow.LayoutOrder, pickRow.Size, pickRow.BackgroundColor3, pickRow.BackgroundTransparency = 10, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70, 15, 50), 0
    Corner(pickRow); Stroke(pickRow); RegTheme(pickRow, "Primary")
    local pickLabel = Instance.new("TextLabel", pickRow)
    pickLabel.Size, pickLabel.Position, pickLabel.BackgroundTransparency, pickLabel.Text = UDim2.new(0, 80, 1, 0), UDim2.new(0, 5, 0, 0), 1, "Chọn Config"
    pickLabel.TextColor3, pickLabel.TextSize, pickLabel.Font, pickLabel.TextXAlignment = Color3.fromRGB(255, 255, 255), 9, Enum.Font.Gotham, Enum.TextXAlignment.Left
    State.RowHint(pickRow, pickLabel, "Chọn config tự tải bên phải", 120)
    local pickBtn = Instance.new("TextButton", pickRow)
    pickBtn.Size, pickBtn.Position, pickBtn.BackgroundColor3, pickBtn.BackgroundTransparency = UDim2.new(0, 110, 0, 20), UDim2.new(1, -115, 0.5, -10), Color3.fromRGB(50, 10, 35), 0
    pickBtn.Text, pickBtn.TextColor3, pickBtn.TextSize, pickBtn.Font, pickBtn.TextXAlignment = pickText(), Color3.fromRGB(50, 200, 50), 8, Enum.Font.GothamBold, Enum.TextXAlignment.Center
    pickBtn.TextTruncate = Enum.TextTruncate.AtEnd
    Corner(pickBtn, UDim.new(0, 4)); Stroke(pickBtn); RegTheme(pickBtn, "Input")

    local drop = Instance.new("ScrollingFrame", mainConfigContainer)
    drop.LayoutOrder, drop.Size, drop.BackgroundColor3 = 11, UDim2.new(1, 0, 0, 80), Color3.fromRGB(80, 20, 60)
    drop.BackgroundTransparency, drop.CanvasSize, drop.ScrollBarThickness, drop.Visible = 0, UDim2.new(0, 0, 0, 0), 3, false
    Corner(drop); Stroke(drop); RegTheme(drop, "DropFrame")
    local dropLayout = Instance.new("UIListLayout", drop); dropLayout.Padding = UDim.new(0, 3)

    local function rebuild()
        for _, c in ipairs(drop:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local names = listNames()
        for i, name in ipairs(names) do
            local b = CreateCustomButton(drop, " 📂 " .. name, "DropItem"); b.LayoutOrder, b.Size = i, UDim2.new(1, 0, 0, 22)
            Track(b.MouseButton1Click:Connect(function()
                State.AutoCfgName = name; _G.__vznam_log("INFO", "Chọn config auto load: " .. name)
                pickBtn.Text = pickText(); drop.Visible = false
                saveAuto()
            end))
        end
        drop.CanvasSize = UDim2.new(0, 0, 0, #names * 25)
    end

    Track(pickBtn.MouseButton1Click:Connect(function() rebuild(); drop.Visible = not drop.Visible end))
    Track(tgl.MouseButton1Click:Connect(function()
        if not State.AutoCfgName then _G.__vznam_log("WARNING", "Auto load cấu hình: chưa chọn config!")
            pickBtn.Text = "⚠️ Chọn config trước!"
            task.delay(1.5, function() if pickBtn.Parent then pickBtn.Text = pickText() end end)
            return
        end
        State.AutoCfgEnabled = not State.AutoCfgEnabled; _G.__vznam_log("INFO", "Auto load cấu hình: " .. (State.AutoCfgEnabled and "BẬT" or "TẮT"))
        paintToggle(); saveAuto()
        if State.AutoCfgEnabled then
            applyByName(State.AutoCfgName)
            ShowToast("✅ Auto load cấu hình: " .. State.AutoCfgName)
        end
    end))
    paintToggle()

    State.RunAutoCfg = function()
        if State.AutoCfgEnabled and State.AutoCfgName then applyByName(State.AutoCfgName) end
    end
end)()

end -- hết khối CẤU HÌNH
-- ===================================================================
-- hàng công tắc dùng chung (tab KEY PREMIUM dùng lại)
do
    State.MakeToggleRow = function(parent, order, text, init, onChange)
        local fr = Instance.new("Frame", parent)
        fr.LayoutOrder, fr.Size, fr.BackgroundColor3, fr.BackgroundTransparency = order, UDim2.new(1, 0, 0, 30), Color3.fromRGB(70, 15, 50), 0
        Corner(fr); Stroke(fr); RegTheme(fr, "Primary")
        local lbl = Instance.new("TextLabel", fr)
        lbl.Size, lbl.Position, lbl.BackgroundTransparency, lbl.Text = UDim2.new(1, -45, 1, 0), UDim2.new(0, 5, 0, 0), 1, text
        lbl.TextColor3, lbl.TextSize, lbl.Font, lbl.TextXAlignment = Color3.fromRGB(255, 255, 255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        local sub = State.GetRowHint(text); if sub then State.RowHint(fr, lbl, sub, 45) end
        local btn = Instance.new("TextButton", fr)
        btn.Size, btn.Position, btn.BackgroundColor3, btn.Text = UDim2.new(0, 30, 0, 15), UDim2.new(1, -34, 0.5, -7.5), Color3.fromRGB(60, 65, 75), ""
        Corner(btn, UDim.new(1, 0)); Stroke(btn)
        local dot = Instance.new("Frame", btn)
        dot.Size, dot.Position, dot.BackgroundColor3 = UDim2.new(0, 11, 0, 11), UDim2.new(0, 2, 0.5, -5.5), Color3.fromRGB(255, 255, 255); Corner(dot, UDim.new(1, 0))
        local state = false
        local function paint(v)
            state = v and true or false
            State.SlideToggle(btn, dot, state, UDim2.new(1, -13, 0.5, -5.5), UDim2.new(0, 2, 0.5, -5.5))
        end
        Track(btn.MouseButton1Click:Connect(function()
            local nv = not state
            if onChange(nv) ~= false then paint(nv) end
        end))
        paint(init)
        return paint
    end
end

-- THU GỌN MẶC ĐỊNH CÁC MỤC
for _, s in ipairs({
    {autoLoadToggleBtn, autoLoadContainer, " → auto load script"},
    {musicToggleBtn, musicContainer, " → âm nhạc"},
    {menuColorToggleBtn, menuColorContainer, " → màu menu"},
    {cfgToggleBtn, mainConfigContainer, " → CẤU HÌNH"},
}) do s[2].Visible = false; s[1].Text = s[3]; local nm = ({[autoLoadToggleBtn] = "auto load script", [musicToggleBtn] = "âm nhạc", [menuColorToggleBtn] = "màu menu", [cfgToggleBtn] = "cấu hình"})[s[1]]; Track(s[1].MouseButton1Click:Connect(function() task.defer(function() _G.__vznam_log("INFO", (s[2].Visible and "Mở mục: " or "Đóng mục: ") .. tostring(nm)) end) end)) end

-- NÚT MỞ MENU VÀ TRẠNG THÁI HUB
local OpenButton = Instance.new("TextButton", ScreenGui); OpenButton.Size, OpenButton.Position, OpenButton.BackgroundColor3, OpenButton.BackgroundTransparency = UDim2.new(0, 46, 0, 46), UDim2.new(0, 15, 0.25, 0), Color3.fromRGB(50, 10, 10), 0.2
OpenButton.Text, OpenButton.TextSize, OpenButton.Active, OpenButton.Draggable = "🌸", 24, true, true; Corner(OpenButton, UDim.new(0, 8))
local OpenImage = Instance.new("ImageLabel", OpenButton); OpenImage.Size, OpenImage.BackgroundTransparency, OpenImage.ScaleType, OpenImage.Visible = UDim2.new(1,0,1,0), 1, Enum.ScaleType.Crop, false; Corner(OpenImage, UDim.new(0, 8))
ApplyIconImage(OpenImage, OpenButton, IconCfg.OpenButton, "VzNamHub_open.png")

local OpenStroke = Instance.new("UIStroke", OpenButton)
OpenStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
OpenStroke.Thickness, OpenStroke.Color = 3, Color3.fromRGB(255, 255, 255)
local FireGradient = Instance.new("UIGradient", OpenStroke)
FireGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(120, 0, 0)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 30, 0)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(255, 190, 40)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 30, 0)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(120, 0, 0)),
})
Track(RunService.RenderStepped:Connect(function()
    FireGradient.Rotation = (tick() * 95) % 360
end))
TweenService:Create(OpenStroke, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness = 5}):Play()

-- [MỚI] ANIMATION NÚT HOME: nảy + xoay vòng + phóng nhẹ khi rê chuột
do
    local OpenScale = Instance.new("UIScale", OpenButton); OpenScale.Scale = 1
        local function Bounce(opening)
        OpenScale.Scale = 1.22
        TweenService:Create(OpenScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end
    Track(OpenButton.MouseEnter:Connect(function()
        TweenService:Create(OpenScale, TweenInfo.new(0.15), {Scale = 1.12}):Play()
    end))
    Track(OpenButton.MouseLeave:Connect(function()
        TweenService:Create(OpenScale, TweenInfo.new(0.15), {Scale = 1}):Play()
    end))
    Track(OpenButton.MouseButton1Click:Connect(function()
        local show = not State.MenuOpen
        Bounce(show); State.SetMenu(show)
        _G.__vznam_log("INFO", show and "Mở menu" or "Ẩn menu")
    end))
end

-- ✨ [MỚI] THANH ÁNH SÁNG TRẮNG NHẸ QUÉT CHÉO (từ góc trên trái → góc dưới phải)
do
    local ShineClip = Instance.new("Frame", MainFrame)
    ShineClip.Name, ShineClip.Size, ShineClip.BackgroundTransparency, ShineClip.BorderSizePixel, ShineClip.ZIndex = "ShineClip", UDim2.new(1, 0, 1, 0), 1, 0, 15
    ShineClip.ClipsDescendants = true
    ShineClip.Active = false

    local Shine = Instance.new("Frame", ShineClip)
    Shine.Name = "Shine"
    Shine.AnchorPoint = Vector2.new(0.5, 0.5)
    Shine.Size = UDim2.new(0, 46, 0, 900)
    Shine.Rotation = 45
    Shine.BackgroundColor3, Shine.BackgroundTransparency, Shine.BorderSizePixel, Shine.ZIndex = Color3.fromRGB(255, 255, 255), 0, 0, 16
    Shine.Active = false
    Shine.Position = UDim2.new(-0.2, 0, -0.2, 0)

    local ShineGrad = Instance.new("UIGradient", Shine)
    ShineGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   1),
        NumberSequenceKeypoint.new(0.5, 0.86), -- độ sáng nhẹ (số càng lớn càng mờ)
        NumberSequenceKeypoint.new(1,   1),
    })

    task.spawn(function()
        while ShineClip.Parent do
            Shine.Position = UDim2.new(-0.2, 0, -0.2, 0)
            TweenService:Create(Shine, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(1.2, 0, 1.2, 0)}):Play()
            task.wait(1.8 + 2.5) -- quét 1.8s rồi nghỉ 2.5s
        end
    end)
end

-- ĐA NGÔN NGỮ + MÀU CHỮ + KIỂU CHỮ
do
local Orig = setmetatable({}, {__mode = "k"})
local MainTextObjs = setmetatable({}, {__mode = "k"})
local WHITE = Color3.new(1, 1, 1)
local function esc(x) return (x:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end

local PHRASES = {
    {"THÔNG TIN", "INFO"}, {"NHẬT KÍ", "LOGS"}, {"SEVER", "SERVER"}, {"CẤU HÌNH", "CONFIG"}, {"CÀI ĐẶT", "SETTINGS"},
    {"Tạo Mới Cấu Hình", "Create New Config"}, {"Xóa Cấu Hình", "Delete Config"}, {"Tải Config", "Load Config"}, {"Tên Config", "Config Name"}, {"Lưu Cấu Hình", "Save Config"}, {"Không có", "None"},
    {"thông tin", "info"}, {"âm nhạc", "music"}, {"màu menu", "menu colors"}, {"màu chữ", "text color"}, {"Xem trước", "Preview"},
    {"Chào mừng trở lại", "Welcome back"}, {"CÓ GÌ MỚI", "WHAT'S NEW"}, {"MỚI", "NEW"}, {"Chép Link Mời", "Copy Invite Link"}, {"Đã chép!", "Copied!"}, {"Cập nhật, nhận key, hỗ trợ", "Updates, keys, support"}, {"Hôm nay", "Today"}, {"ngày trước", "days ago"},
    {"Chọn Script Auto Load...", "Select Auto Load Script..."}, {"Chọn script trước!", "Select a script first!"}, {"Auto Load Script Chạy", "Auto Load Script Run"},
    {"Nhập Sound ID...", "Enter Sound ID..."}, {"Chọn Nhạc...", "Select Music..."}, {"Phát Nhạc Nền", "Play Background Music"}, {"Âm lượng", "Volume"},
    {"Trong suốt", "Transparency"}, {"Khung ngoài", "Outer frame"}, {"Viền:", "Border:"}, {"Nền:", "Background:"}, {"Bình Thường", "Normal"},
    {"Hồng Pastel", "Pastel Pink"}, {"Đêm Đen Sâu", "Deep Night"}, {"Đỏ Lửa", "Fire Red"}, {"Xanh Đại Dương", "Ocean Blue"}, {"Xanh Dương", "Blue"},
    {"Cầu Vồng (Rainbow)", "Rainbow"}, {"Cầu Vồng", "Rainbow"}, {"Hồng Kẹo", "Candy Pink"}, {"Đỏ Đậm", "Crimson"}, {"Không Viền", "No Border"}, {"Link riêng", "Custom link"},
    {"Dán link ảnh nền riêng rồi Enter...", "Paste your own background link then Enter..."},
    {"Nền động:", "Animated BG:"}, {"Tắt nền động", "Turn off animated BG"}, {"Tắt", "Off"},
    {"Màu chữ:", "Text color:"}, {"⚪ Trắng", "⚪ White"}, {"🟡 Vàng", "🟡 Yellow"}, {"🟢 Xanh Lá", "🟢 Green"}, {"🟠 Cam", "🟠 Orange"}, {"🔴 Đỏ", "🔴 Red"}, {"🎯 Tùy chỉnh", "🎯 Custom"},
    {"Nhập mã màu (#FF66AA hoặc 255,100,170) rồi Enter...", "Enter color code (#FF66AA or 255,100,170) then Enter..."},
    {"Chưa có script nào chạy", "No script running"}, {"Đang bật:", "Running:"}, {"Đang chạy:", "Running:"},
    {"Nhập tên script...", "Enter script name..."}, {"Tìm", "Search"}, {"Trang Trước", "Prev Page"}, {"Trang Sau", "Next Page"}, {"Trang", "Page"},
    {"Đang tải...", "Loading..."}, {"Lỗi!", "Error!"}, {"Tác giả", "Author"}, {"Load lại", "Load again"},
    {"Dán JobID vào đây...", "Paste JobID here..."}, {"Vào server", "Join server"}, {"Code vào sever này!", "Code to join this server!"}, {"Đổi server", "Switch server"},
    {"Server vắng nhất", "Emptiest server"}, {"Vào lại", "Rejoin"},
    {"Xóa log", "Clear log"}, {"Log Hệ Thống", "System Log"}, {"Khung log nổi", "Floating log"}, {"Màn trắng (AFK)", "White screen (AFK)"}, {"Màn đen (AFK)", "Black screen (AFK)"},
    {"ĐƯỢC TẠO BỞI", "CREATED BY"}, {"Tổng Hợp", "All-in-One"}, {"Toa Độ", "Coordinates"}, {"Lấy Dữ Liệu Game", "Get Game Data"},
    {"mẫu (không nên ấn)", "sample (don't press)"}, {"Hop sv1 người", "Hop 1-player server"}, {"join trứng", "egg join"}, {"thường", "normal"}, {"bảng to", "big UI"}, {"Chữ A", "Letter A"},
    {"đã bật", "enabled"}, {"Chưa nhập JobID", "JobID not entered"}, {"Đã copy code vào server!", "Code copied!"}, {"Đã copy JobID!", "JobID copied!"},
    {"Script này có key, ấn Load lại để bật", "This script needs a key, press Load again to run"},
    {"[THÀNH CÔNG]", "[SUCCESS]"}, {"[CẢNH BÁO]", "[WARNING]"}, {"[LỖI]", "[ERROR]"},
    {"Host bị chặn!", "Host blocked!"}, {"Tải thất bại!", "Download failed!"}, {"Lỗi cú pháp!", "Syntax error!"}, {"Lỗi Runtime", "Runtime error"},
    {"Quá trình tải thành công!", "Loaded successfully!"}, {"Đã xóa log.", "Log cleared."}, {"Đã bật:", "Enabled:"}, {"Mã màu không hợp lệ!", "Invalid color code!"},
    {"Đang vào server", "Joining server"}, {"Đang vào lại server này...", "Rejoining this server..."}, {"Đang tìm server khác...", "Looking for another server..."}, {"Đang tìm server vắng nhất...", "Looking for the emptiest server..."},
    {"Đã tải xong trang", "Finished loading page"}, {"Đang tìm", "Searching"}, {"người", "players"},
    {"có key", "has key"}, {"Tải", "Load"}, {"Đang tải", "Loading"},
    {"Lỗi API ScriptBlox!", "ScriptBlox API error!"}, {"Không có dữ liệu!", "No data!"}, {"Script lỗi cú pháp!", "Script syntax error!"},
    {"Không có thêm kết quả nào ở trang này!", "No more results on this page!"}, {"Đang ở trang đầu tiên!", "Already on the first page!"}, {"Đang ở trang cuối!", "Already on the last page!"},
    {"Không lấy được danh sách server!", "Couldn't get the server list!"}, {"Dữ liệu server lỗi!", "Invalid server data!"},
    {"Không có server nào để đổi!", "No server to switch to!"}, {"Không tìm thấy server nào!", "No server found!"},
    {"Đổi sang server", "Switching to server"}, {"Server vắng nhất:", "Emptiest server:"},
    {"Executor không hỗ trợ setclipboard!", "Executor doesn't support setclipboard!"},
    {"Đã copy code vào server này.", "Join code copied."}, {"Đã copy JobID.", "JobID copied."}, {"Teleport lỗi", "Teleport error"},
    {"Không tải được ảnh icon", "Failed to load icon image"}, {"Không tải được nền", "Failed to load background"},
    {"Chưa nhập JobID!", "JobID not entered!"},
    {"Kiểu chữ:", "Font:"}, {"Mặc định", "Default"}, {"viết tay", "handwriting"},
    {"Auto Load Cấu Hình", "Auto Load Config"}, {"Chọn Config", "Select Config"}, {"Chưa chọn", "Not selected"}, {"Chọn config trước!", "Select a config first!"},
    {"Auto load cấu hình:", "Auto load config:"}, {"Auto Load: không tìm thấy cấu hình", "Auto Load: config not found"}, {"Đã tự động tải cấu hình", "Auto-loaded config"},
    {"Bấm nút:", "Button pressed:"}, {"Mở menu", "Menu opened"}, {"Ẩn menu", "Menu hidden"}, {"Đã tạo config:", "Config created:"}, {"Đã lưu config:", "Config saved:"}, {"Đã tải config:", "Config loaded:"}, {"Đã xóa config:", "Config deleted:"}, {"Đổi nền:", "Background changed:"}, {"Đổi theme:", "Theme changed:"}, {"Đổi viền:", "Border changed:"}, {"Đổi màu chữ:", "Text color changed:"}, {"Đổi kiểu chữ:", "Font changed:"}, {"Đổi ngôn ngữ:", "Language changed:"}, {"Mở mục:", "Opened section:"}, {"Đóng mục:", "Closed section:"}, {"Thông báo:", "Notice:"}, {"Cài đặt", "Setting"}, {"BẬT", "ON"}, {"TẮT", "OFF"}, {"Đã tải file nền:", "Background file downloaded:"}, {"Đang tải nền:", "Downloading background:"}, {"Đã nhập JobID:", "JobID entered:"}, {"Chọn nhạc:", "Selected music:"}, {"Phát nhạc ID:", "Playing music ID:"}, {"Nhạc nền:", "Background music:"}, {"Đổi kích thước menu:", "Menu resized:"}, {"Đóng VzNamHub", "Closing VzNamHub"},
    {"Đã bật nền động", "Animated background enabled"}, {"Đang tải nền động:", "Downloading animated background:"}, {"Nền động lỗi", "Animated background error"}, {"quay về nền ảnh", "back to image background"},
    {"Nền động lỗi, đã quay về nền ảnh", "Animated BG failed, switched back to image"},{"Thanh tiện ích nổi", "Floating stats bar"},
    -- [MỚI] TAB KEY PREMIUM
    {"KEY PREMIUM", "PREMIUM KEY"},
    {"Key premium khoá theo tài khoản", "Premium key locked to account"},
    {"Dán key premium rồi Enter...", "Paste premium key then Enter..."},
    {"Thêm & Verify key", "Add & Verify key"},
    {"Chọn key premium trước!", "Select a premium key first!"},
    {"Chưa chọn key premium", "No premium key selected"},
    {"Chọn key premium", "Select premium key"},
    {"Xóa key đã chọn", "Delete selected key"},
    {"Kiểm tra key đã chọn", "Check selected key"},
    {"Auto verify key premium", "Auto verify premium key"},
    {"Auto verify đã bật: lần sau mở script sẽ tự nhập key premium đã chọn", "Auto verify enabled: the selected premium key will be entered automatically next time"},
    {"Auto verify đã tắt", "Auto verify disabled"},
    {"Key này không phải premium hoặc không khoá cho tài khoản này!", "This key is not premium or not locked to this account!"},
    {"Đã thêm key premium (khoá vào tài khoản của bạn)", "Premium key added (locked to your account)"},
    {"Key đã có trong danh sách", "Key already in list"},
    {"Chưa nhập key!", "No key entered!"},
    {"Đang kiểm tra...", "Checking..."},
    {"Key hợp lệ (premium, khoá theo tài khoản)", "Key valid (premium, locked to account)"},
    {"Key sai hoặc hết hạn!", "Wrong or expired key!"},
    {"Không kết nối được server key!", "Can't reach the key server!"},
    {"Key premium không còn hợp lệ với tài khoản này, đã gỡ khỏi danh sách", "Premium key no longer valid for this account, removed from list"},
    {"Đã xóa key premium", "Premium key deleted"},
    {"Chưa có key nào được chọn", "No key selected"},
    -- [MỚI] → SETUP
    {"Anti AFK (treo không văng)", "Anti AFK (idle without kick)"},
    {"Auto load hub khi vào game", "Auto load hub on join"},
    {"Tự bật lại VzNamHub khi vào game", "Auto re-run VzNamHub on join"},
    {"Auto join lại khi bị văng", "Auto rejoin when kicked"},
    {"Link loader của hub (raw)...", "Hub loader link (raw)..."},
    {"Script sẽ tự bật:", "Script to auto run:"},
    {"Chưa có", "None yet"},
    {"Chưa chọn script ở mục Auto Load!", "Select a script in Auto Load first!"},
    {"Chọn script ở Misc › Auto Load trước!", "Select a script in Misc › Auto Load first!"},
    {"Cần executor hỗ trợ queue_on_teleport. Hub sẽ chạy lại sau mỗi lần dịch chuyển hoặc vào lại.", "Requires executor support for queue_on_teleport. The hub re-runs after every teleport or rejoin."},
    {"Executor không hỗ trợ queue_on_teleport!", "Executor doesn't support queue_on_teleport!"},
    {"Link loader không hợp lệ hoặc host bị chặn!", "Invalid loader link or blocked host!"},
    {"Đã lưu link loader", "Loader link saved"},
    {"Đã đưa hub vào hàng chờ chạy sau khi dịch chuyển", "Hub queued to run after teleport"},
    {"Bị văng khỏi game, đang vào lại...", "Disconnected from the game, rejoining..."},
    {"Bị văng, đang vào lại...", "Kicked, rejoining..."},
    {"Vào lại thất bại:", "Rejoin failed:"},
    {"Auto load: tự bật script", "Auto load: auto-running script"},
    {"Không tìm thấy script đã lưu:", "Saved script not found:"},
    {"Auto verify key premium thành công!", "Auto verify premium key succeeded!"},
    {"Ấn để mở script", "Press to run script"},
    {"Ấn để mở script (cần key)", "Press to run script (needs key)"},
    {"Ấn để vào server theo JobID đã dán", "Press to join the pasted JobID"},
    {"Ấn để chép code vào server này", "Press to copy this server's join code"},
    {"Ấn để nhảy sang server ngẫu nhiên", "Press to hop to a random server"},
    {"Ấn để vào server ít người nhất", "Press to join the emptiest server"},
    {"Ấn để vào lại server này", "Press to rejoin this server"},
    {"Ấn để chép JobID server này", "Press to copy this server's JobID"},
    {"Ấn để mở/đóng mục này", "Press to expand/collapse"},
    {"Ấn để chọn script tự chạy", "Press to pick the auto-run script"},
    {"Bật để tự chạy script đã chọn", "Turn on to auto-run the chosen script"},
    {"Ấn để chọn bài nhạc có sẵn", "Press to pick a preset song"},
    {"Bật để phát nhạc nền", "Turn on to play background music"},
    {"Kéo thanh để chỉnh âm lượng", "Drag the bar to set volume"},
    {"Ấn để đổi màu menu", "Press to change menu color"},
    {"Kéo thanh để chỉnh độ trong suốt", "Drag to set transparency"},
    {"Kéo thanh để chỉnh khung ngoài", "Drag to set outer frame"},
    {"Ấn để đổi màu viền menu", "Press to change border color"},
    {"Ấn để chọn ảnh nền menu", "Press to pick the menu background"},
    {"Ấn để chọn màu chữ có sẵn", "Press to pick a preset text color"},
    {"Kéo thanh để chỉnh màu", "Drag the bar to adjust color"},
    {"Ấn để đổi kiểu chữ", "Press to change the font"},
    {"Ấn bên phải để đổi ngôn ngữ", "Press right to switch language"},
    {"Bật để phủ màn trắng (treo AFK)", "Turn on for a white screen (AFK)"},
    {"Bật để phủ màn đen (treo AFK)", "Turn on for a black screen (AFK)"},
    {"Bật để hiện khung log nổi", "Turn on to show the floating log"},
    {"Bật để hiện FPS, Ping, RAM nổi", "Turn on to show floating FPS, Ping, RAM"},
    {"Nhập tên rồi ấn Create để tạo", "Enter a name, then press Create"},
    {"Chọn config cần xóa bên phải", "Pick the config to delete →"},
    {"Chọn config cần tải bên phải", "Pick the config to load →"},
    {"Bật để tự tải config khi mở hub", "Turn on to auto-load config on start"},
    {"Chọn config tự tải bên phải", "Pick the auto-load config →"},
    {"Bật để không bị văng khi đứng yên", "Turn on to avoid idle kick"},
    {"Bật để hub tự chạy lại khi dịch chuyển", "Turn on to re-run hub after teleport"},
    {"Bật để tự vào lại khi bị văng", "Turn on to auto rejoin when kicked"},
    {"Ấn để kiểm tra & thêm key vừa dán", "Press to verify & add the pasted key"},
    {"Ấn để chọn key premium đã lưu", "Press to pick a saved premium key"},
    {"Ấn để kiểm tra key đang chọn", "Press to check the selected key"},
    {"Ấn để xóa key đang chọn", "Press to delete the selected key"},
    {"Bật để tự nhập key premium đã chọn", "Turn on to auto-enter the chosen key"},
    {"Ấn để chép link mời Discord", "Press to copy the Discord invite"},
    {"Ấn Save để lưu vào:", "Press Save to save to:"},
    {"Thử nhiều server nhưng đều không vào được!", "Tried several servers but none worked!"},
    {"Thử vào server", "Trying server"},
    {"Dịch chuyển thất bại:", "Teleport failed:"},
    {"Lỗi chức năng server:", "Server function error:"},
    {"Lỗi nút server:", "Server button error:"},
    {"⏳ Đang xử lý, đợi chút...", "⏳ Working, please wait..."},
    {"🔎 Đang tìm server...", "🔎 Searching for servers..."},
}
table.sort(PHRASES, function(a, b) return #a[1] > #b[1] end)
for _, p in ipairs(PHRASES) do p[3] = esc(p[1]); p[4] = (p[2]:gsub("%%", "%%%%")) end

local function Translate(str)
    if type(str) ~= "string" then return str end
    for _, p in ipairs(PHRASES) do
        if str:find(p[1], 1, true) then str = (str:gsub(p[3], p[4])) end
    end
    return str
end

local function trProp(o, prop)
    local rec = Orig[o]
    if not rec then rec = {src = {}, last = {}}; Orig[o] = rec end
    local cur = o[prop]
    if rec.last[prop] == nil or cur ~= rec.last[prop] then rec.src[prop] = cur end
    local out = (State.Language == "EN") and Translate(rec.src[prop]) or rec.src[prop]
    rec.last[prop] = out
    if cur ~= out then o[prop] = out end
end

local FontObjs = setmetatable({}, {__mode = "k"})
local BOLD_FONTS = {GothamBold = true, GothamBlack = true, SourceSansBold = true, ArialBold = true}
local function applyFontTo(o)
    local orig = FontObjs[o]
    if not orig then return end
    local fam = State.FontFamily
    if not fam then o.Font = orig; return end
    o.Font = BOLD_FONTS[orig.Name] and fam.Bold or fam.Reg
end
ApplyFont = function(fam)
    State.FontFamily = fam
    for o in pairs(FontObjs) do if o.Parent then pcall(applyFontTo, o) end end
end

local function hookLoc(o)
    if Orig[o] then return end
    local isBox = o:IsA("TextBox")
    if not (o:IsA("TextLabel") or o:IsA("TextButton") or isBox) then return end
    if not o:GetAttribute("NoFont") and o.Font ~= Enum.Font.Code then FontObjs[o] = o.Font; applyFontTo(o) end
    local prop = isBox and "PlaceholderText" or "Text"
    trProp(o, prop)
    Track(o:GetPropertyChangedSignal(prop):Connect(function() pcall(trProp, o, prop) end))
    if o.TextColor3 == WHITE then
        MainTextObjs[o] = true
        if State.TextMode == "Solid" and State.TextColor ~= WHITE then o.TextColor3 = State.TextColor end
    end
end

RelocalizeAll = function()
    for _, d in ipairs(ScreenGui:GetDescendants()) do pcall(hookLoc, d) end
    for _, o in ipairs(ScreenGui:GetDescendants()) do
        local rec = Orig[o]
        if rec then
            local props = {}
            for prop in pairs(rec.src) do table.insert(props, prop) end
            for _, prop in ipairs(props) do pcall(trProp, o, prop) end
        end
    end
end

ApplyTextColor = function(col)
    State.TextColor = col
    for o in pairs(MainTextObjs) do if o.Parent then o.TextColor3 = col end end
end

for _, d in ipairs(ScreenGui:GetDescendants()) do pcall(hookLoc, d) end
Track(ScreenGui.DescendantAdded:Connect(function(d) task.defer(function() pcall(hookLoc, d) end) end))
Track(RunService.RenderStepped:Connect(function()
    if State.TextMode ~= "Rainbow" then return end
    local c = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    for o in pairs(MainTextObjs) do if o.Parent then o.TextColor3 = c end end
end))
end

-- Tự động mở tab THÔNG TIN khi mới load
for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end
homeScroll.Visible = true
homeIndicator.Visible = true
ActiveTabTitle.Text = TransDict[State.Language]["🏠 THÔNG TIN"]
ApplyTheme(Color3.fromRGB(15, 16, 22))
UpdateAllStrokes(Color3.fromRGB(0, 191, 255))
if State.RunAutoCfg then pcall(State.RunAutoCfg) end
do
    local okx, exn = pcall(function() return identifyexecutor and identifyexecutor() or "Unknown" end)
    _G.__vznam_log("SUCCESS", "VzNamHub v4.6 đã tải xong! Executor: " .. tostring(okx and exn or "Unknown"))
    _G.__vznam_log("INFO", "PlaceId: " .. tostring(game.PlaceId) .. " | JobID: " .. tostring(game.JobId))
    _G.__vznam_log("INFO", "Đã nạp " .. #RegisteredScripts .. " script vào menu")
    local caps = { writefile = writefile, readfile = readfile, getcustomasset = getcustomasset or getsynasset, setclipboard = setclipboard, listfiles = listfiles, delfile = delfile, gethui = gethui }
    local missing = {}
    for k, v in pairs(caps) do if v == nil then table.insert(missing, k) end end
    if #missing > 0 then _G.__vznam_log("WARNING", "Executor thiếu hàm: " .. table.concat(missing, ", ")) else _G.__vznam_log("SUCCESS", "Executor hỗ trợ đủ các hàm cần thiết.") end
end
task.defer(UpdateBgLayout)

-- ===== KEY SYSTEM =====
local KEY_CFG = {
    Worker   = "https://vznamkey.lenguyenvietnam0.workers.dev",
    SaveFile = "VzNamHub_Key.txt",
    BgUrl    = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubanhnen/main/IMG_20261024_125441.jpg",
}
local KEY_NET_ERR = "Không kết nối được server key!"

local function CheckKey(k)
    k = tostring(k):gsub("%s", "")
    if k == "" then return false, "Chưa nhập key!" end
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(KEY_CFG.Worker .. "/verify?uid=" .. localPlayer.UserId .. "&key=" .. HttpService:UrlEncode(k)))
    end)
    if not ok then return false, KEY_NET_ERR end
    if res.ok then return true, res.left, res.premium == true end
    return false, "Key sai hoặc hết hạn!"
end

-- ===================================================================
-- [MỚI] TAB 🔑 KEY PREMIUM (nằm ngay dưới tab THÔNG TIN)
--  * Key premium CHỈ được thêm khi server xác nhận (verify kèm UserId) => khoá vào đúng tài khoản này
--  * Danh sách key lưu theo UserId, mở danh sách sẽ verify lại, key không còn hợp lệ sẽ bị gỡ
--  * Công tắc "Auto verify key premium": lần sau bật script sẽ tự nhập key premium đã chọn
-- ===================================================================
do
    local PREM_FILE = "VzNamHub_Premium.json"
    local uidKey = tostring(localPlayer.UserId)

    local all = {}
    if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(PREM_FILE) then
        local ok, c = pcall(readfile, PREM_FILE)
        if ok and type(c) == "string" then
            local ok2, d = pcall(HttpService.JSONDecode, HttpService, c)
            if ok2 and type(d) == "table" then all = d end
        end
    end
    if type(all[uidKey]) ~= "table" then all[uidKey] = {} end
    local me = all[uidKey]
    if type(me.Keys) ~= "table" then me.Keys = {} end
    if type(me.Selected) ~= "string" or not table.find(me.Keys, me.Selected) then me.Selected = nil end
    me.Auto = (me.Auto == true) and me.Selected ~= nil

    local function save()
        if typeof(writefile) ~= "function" then return end
        pcall(writefile, PREM_FILE, HttpService:JSONEncode(all))
    end
    local function mask(k) if #k <= 8 then return k end return k:sub(1, 4) .. "••••" .. k:sub(-4) end

    -- ShowKeyGate sẽ gọi hàm này để biết có tự nhập key premium không
    State.GetAutoPremiumKey = function()
        if me.Auto and me.Selected and table.find(me.Keys, me.Selected) then return me.Selected end
        return nil
    end

    -- ----- giao diện tab -----
    local tabBtn = CreateCustomButton(SidebarScroll, " 🔑 KEY PREMIUM", "Primary"); tabBtn.LayoutOrder, tabBtn.Size = 1, UDim2.new(1, 0, 0, 26)
    tabBtn:SetAttribute("OriginName", "🔑 KEY PREMIUM")
    local indicator = Instance.new("Frame", tabBtn); indicator.Size, indicator.Position, indicator.BackgroundColor3, indicator.BorderSizePixel, indicator.Visible = UDim2.new(0, 3, 0, 12), UDim2.new(0, 0, 0.5, -6), Color3.fromRGB(255,105,180), 0, false; Corner(indicator, UDim.new(0, 2))
    local scroll = Instance.new("ScrollingFrame", ContentContainer); scroll.Size, scroll.Position = UDim2.new(1, -12, 1, -29), UDim2.new(0, 6, 0, 28); scroll.BackgroundTransparency, scroll.BorderSizePixel = 1, 0; scroll.ScrollBarThickness, scroll.Visible, scroll.ClipsDescendants = 3, false, true
    local lay = Instance.new("UIListLayout", scroll); lay.SortOrder, lay.Padding, lay.HorizontalAlignment = Enum.SortOrder.LayoutOrder, UDim.new(0, 4), Enum.HorizontalAlignment.Center
    local pad = Instance.new("UIPadding", scroll); pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 10), UDim.new(0, 6), UDim.new(0, 4)
    Track(lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 15) end))
    Track(tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Container.Visible = false; if t.Indicator then t.Indicator.Visible = false end end
        scroll.Visible, indicator.Visible = true, true
        ActiveTabTitle.Text = "🔑 KEY PREMIUM"; SearchInputContent.Text = ""
    end))
    table.insert(Tabs, {Container = scroll, Indicator = indicator})

    -- thẻ thông tin
    local info = Instance.new("Frame", scroll)
    info.LayoutOrder, info.Size, info.BackgroundColor3, info.BackgroundTransparency = 1, UDim2.new(1, 0, 0, 42), Color3.fromRGB(70, 15, 50), 0
    Corner(info); Stroke(info); RegTheme(info, "Primary")
    local infoLbl = Instance.new("TextLabel", info)
    infoLbl.Size, infoLbl.Position, infoLbl.BackgroundTransparency = UDim2.new(1, -10, 1, -6), UDim2.new(0, 5, 0, 3), 1
    infoLbl.Text = "🔒 Key premium khoá theo tài khoản: " .. localPlayer.Name .. " (ID " .. uidKey .. ")"
    infoLbl.TextColor3, infoLbl.TextSize, infoLbl.Font, infoLbl.TextXAlignment, infoLbl.TextYAlignment, infoLbl.TextWrapped = Color3.fromRGB(255, 255, 255), 9, Enum.Font.GothamBold, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, true

    -- dòng trạng thái
    local statusLbl = Instance.new("TextLabel", scroll)
    statusLbl.LayoutOrder, statusLbl.Size, statusLbl.AutomaticSize, statusLbl.BackgroundTransparency, statusLbl.Text = 3, UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 1, ""
    statusLbl.TextColor3, statusLbl.TextSize, statusLbl.Font, statusLbl.TextXAlignment, statusLbl.TextWrapped = Color3.fromRGB(255, 200, 50), 8, Enum.Font.GothamBold, Enum.TextXAlignment.Left, true
    local function setStatus(t, c) statusLbl.TextColor3 = c or Color3.fromRGB(255, 200, 50); statusLbl.Text = t end

    -- ô nhập key + nút thêm
    local keyBox = Instance.new("TextBox", scroll)
    keyBox.LayoutOrder, keyBox.Size = 4, UDim2.new(1, 0, 0, 26)
    keyBox.BackgroundColor3, keyBox.BackgroundTransparency, keyBox.PlaceholderText, keyBox.Text = Color3.fromRGB(70, 15, 50), 0, "🔑 Dán key premium rồi Enter...", ""
    keyBox.PlaceholderColor3, keyBox.TextColor3, keyBox.TextSize, keyBox.Font, keyBox.ClearTextOnFocus, keyBox.ClipsDescendants = Color3.fromRGB(150, 155, 165), Color3.fromRGB(255, 255, 255), 8, Enum.Font.Gotham, false, true
    Corner(keyBox); Stroke(keyBox); RegTheme(keyBox, "Input")
    local addBtn = CreateCustomButton(scroll, "➕ Thêm & Verify key", "Primary"); addBtn.LayoutOrder, addBtn.Size, addBtn.TextXAlignment = 5, UDim2.new(1, 0, 0, 26), Enum.TextXAlignment.Center; State.AddHint(addBtn, "Ấn để kiểm tra & thêm key vừa dán")

    -- ô chọn key premium (dropdown)
    local dropBtnP = CreateCustomButton(scroll, "", "Primary"); dropBtnP.LayoutOrder, dropBtnP.Size = 6, UDim2.new(1, 0, 0, 26)
    dropBtnP.TextTruncate = Enum.TextTruncate.AtEnd; State.AddHint(dropBtnP, "Ấn để chọn key premium đã lưu")
    local function selText() return me.Selected and (" 💎 Chọn key premium: " .. mask(me.Selected)) or " 💎 Chưa chọn key premium" end
    dropBtnP.Text = selText()
    local dropList = Instance.new("ScrollingFrame", scroll)
    dropList.LayoutOrder, dropList.Size, dropList.BackgroundColor3 = 7, UDim2.new(1, 0, 0, 80), Color3.fromRGB(80, 20, 60)
    dropList.BackgroundTransparency, dropList.CanvasSize, dropList.ScrollBarThickness, dropList.Visible = 0, UDim2.new(0, 0, 0, 0), 3, false
    Corner(dropList); Stroke(dropList); RegTheme(dropList, "DropFrame")
    local dlLayout = Instance.new("UIListLayout", dropList); dlLayout.Padding = UDim.new(0, 3)

    local paintAuto -- gán sau khi tạo công tắc

    local function rebuild()
        for _, c in ipairs(dropList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for i, k in ipairs(me.Keys) do
            local b = CreateCustomButton(dropList, " 🔑 " .. mask(k), "DropItem"); b.LayoutOrder, b.Size = i, UDim2.new(1, 0, 0, 22)
            Track(b.MouseButton1Click:Connect(function()
                me.Selected = k; save()
                dropBtnP.Text = selText(); dropList.Visible = false
                _G.__vznam_log("INFO", "Chọn key premium: " .. mask(k))
            end))
        end
        dropList.CanvasSize = UDim2.new(0, 0, 0, #me.Keys * 25)
    end
    rebuild()

    -- verify lại các key đã lưu với tài khoản hiện tại, key nào không còn hợp lệ thì gỡ
    local function purge()
        local snapshot = {}
        for _, k in ipairs(me.Keys) do table.insert(snapshot, k) end
        task.spawn(function()
            local changed = false
            for _, k in ipairs(snapshot) do
                local ok, left, prem = CheckKey(k)
                if (not ok and left ~= KEY_NET_ERR) or (ok and not prem) then
                    local i = table.find(me.Keys, k)
                    if i then table.remove(me.Keys, i); changed = true end
                    if me.Selected == k then me.Selected = nil; me.Auto = false; if paintAuto then paintAuto(false) end end
                    _G.__vznam_log("WARNING", "Key premium không còn hợp lệ với tài khoản này, đã gỡ khỏi danh sách")
                end
            end
            if changed then save(); rebuild(); dropBtnP.Text = selText() end
        end)
    end

    Track(dropBtnP.MouseButton1Click:Connect(function()
        dropList.Visible = not dropList.Visible
        if dropList.Visible then rebuild(); purge() end
    end))

    -- thêm key (chỉ nhận khi server xác nhận là premium của tài khoản này)
    local function addKey(raw)
        local k = (tostring(raw):gsub("%s", ""))
        if k == "" then setStatus("⚠️ Chưa nhập key!"); return end
        if table.find(me.Keys, k) then setStatus("ℹ️ Key đã có trong danh sách"); return end
        setStatus("⏳ Đang kiểm tra...")
        task.spawn(function()
            local ok, left, prem = CheckKey(k)
            if ok and prem then
                table.insert(me.Keys, k); me.Selected = k; save()
                rebuild(); dropBtnP.Text = selText(); keyBox.Text = ""
                setStatus("✅ Đã thêm key premium (khoá vào tài khoản của bạn)", Color3.fromRGB(85, 255, 85))
                _G.__vznam_log("SUCCESS", "Đã thêm key premium (khoá vào tài khoản của bạn)")
            elseif ok then
                setStatus("❌ Key này không phải premium hoặc không khoá cho tài khoản này!", Color3.fromRGB(255, 85, 85))
            else
                setStatus("❌ " .. tostring(left), Color3.fromRGB(255, 85, 85))
            end
        end)
    end
    Track(addBtn.MouseButton1Click:Connect(function() addKey(keyBox.Text) end))
    Track(keyBox.FocusLost:Connect(function(enter) if enter then addKey(keyBox.Text) end end))

    -- công tắc auto verify
    paintAuto = State.MakeToggleRow(scroll, 8, "⚡ Auto verify key premium", me.Auto, function(v)
        if v and not me.Selected then
            setStatus("⚠️ Chọn key premium trước!")
            return false
        end
        me.Auto = v; save()
        if v then setStatus("✅ Auto verify đã bật: lần sau mở script sẽ tự nhập key premium đã chọn", Color3.fromRGB(85, 255, 85))
        else setStatus("Auto verify đã tắt", Color3.fromRGB(200, 200, 210)) end
        _G.__vznam_log("INFO", "Auto verify key premium: " .. (v and "BẬT" or "TẮT"))
    end)

    -- kiểm tra / xóa key đang chọn
    local checkBtn = CreateCustomButton(scroll, "🔎 Kiểm tra key đã chọn", "Primary"); checkBtn.LayoutOrder, checkBtn.Size, checkBtn.TextXAlignment = 9, UDim2.new(1, 0, 0, 26), Enum.TextXAlignment.Center; State.AddHint(checkBtn, "Ấn để kiểm tra key đang chọn")
    Track(checkBtn.MouseButton1Click:Connect(function()
        if not me.Selected then setStatus("⚠️ Chọn key premium trước!"); return end
        setStatus("⏳ Đang kiểm tra...")
        local k = me.Selected
        task.spawn(function()
            local ok, left, prem = CheckKey(k)
            if ok and prem then setStatus("✅ Key hợp lệ (premium, khoá theo tài khoản)", Color3.fromRGB(85, 255, 85))
            elseif ok then setStatus("❌ Key này không phải premium hoặc không khoá cho tài khoản này!", Color3.fromRGB(255, 85, 85))
            else setStatus("❌ " .. tostring(left), Color3.fromRGB(255, 85, 85)) end
        end)
    end))
    local delBtnP = CreateCustomButton(scroll, "🗑️ Xóa key đã chọn", "Primary"); delBtnP.LayoutOrder, delBtnP.Size, delBtnP.TextXAlignment = 10, UDim2.new(1, 0, 0, 26), Enum.TextXAlignment.Center; State.AddHint(delBtnP, "Ấn để xóa key đang chọn")
    Track(delBtnP.MouseButton1Click:Connect(function()
        if not me.Selected then setStatus("⚠️ Chọn key premium trước!"); return end
        local i = table.find(me.Keys, me.Selected)
        if i then table.remove(me.Keys, i) end
        me.Selected = nil; me.Auto = false; paintAuto(false); save()
        rebuild(); dropBtnP.Text = selText()
        setStatus("🗑️ Đã xóa key premium", Color3.fromRGB(200, 200, 210))
        _G.__vznam_log("WARNING", "Đã xóa key premium")
    end))
    ApplyTheme(State.ThemeBase) -- tô lại màu theme cho các phần tử vừa tạo (tránh bị màu hồng mặc định)
end

local function ShowKeyGate(onSuccess)
    local f = Instance.new("Frame", CoverGui)
    f.AnchorPoint, f.Position, f.Size = Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, 400, 0, 250)
    f.BackgroundColor3, f.BorderSizePixel, f.ZIndex = Color3.fromRGB(15, 16, 22), 0, 60
    f.ClipsDescendants, f.Active, f.Draggable = true, true, true
    Corner(f, UDim.new(0, 16))
    local fs = Instance.new("UIStroke", f); fs.Color, fs.Thickness, fs.Transparency = Color3.new(1, 1, 1), 2, 0.2
    local fsg = Instance.new("UIGradient", fs)
    fsg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 140, 190)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(105, 85, 190)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(185, 85, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 140, 190)),
    })
    Track(RunService.RenderStepped:Connect(function() if fsg.Parent then fsg.Rotation = (tick() * 40) % 360 end end))
    local fScale = Instance.new("UIScale", f); fScale.Scale = 0.85
    TweenService:Create(fScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

    local bg = Instance.new("ImageLabel", f)
    bg.Size, bg.BackgroundTransparency, bg.ScaleType, bg.ZIndex, bg.Visible = UDim2.new(1,0,1,0), 1, Enum.ScaleType.Crop, 61, false
    Corner(bg, UDim.new(0, 16))
    ApplyIconImage(bg, nil, KEY_CFG.BgUrl, "VzNamHub_keybg.png")
    local shade = Instance.new("Frame", f)
    shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency, shade.BorderSizePixel, shade.ZIndex = UDim2.new(1,0,1,0), Color3.new(1, 1, 1), 0, 0, 62; Corner(shade, UDim.new(0, 16))
    local shg = Instance.new("UIGradient", shade)
    shg.Color, shg.Rotation = ColorSequence.new(Color3.fromRGB(8, 10, 22), Color3.fromRGB(34, 14, 54)), 90
    shg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.6)})

    local t = Instance.new("TextLabel", f)
    t.BackgroundTransparency, t.Size, t.Position = 1, UDim2.new(1, -70, 0, 32), UDim2.new(0, 20, 0, 12)
    t.Text, t.TextColor3, t.TextSize, t.Font, t.ZIndex = "🔑 VzNamHub - Nhập Key", Color3.new(1, 1, 1), 24, Enum.Font.GothamBold, 63
    t.TextXAlignment = Enum.TextXAlignment.Left
    local tg = Instance.new("UIGradient", t); tg.Color = ColorSequence.new(Color3.fromRGB(0, 220, 255), Color3.fromRGB(255, 120, 190))
    local sub = Instance.new("TextLabel", f)
    sub.BackgroundTransparency, sub.Size, sub.Position = 1, UDim2.new(1, -40, 0, 16), UDim2.new(0, 20, 0, 46)
    sub.Text, sub.TextColor3, sub.TextSize, sub.Font, sub.ZIndex = "✨ Lấy key ở web rồi dán vào ô bên dưới để mở menu", Color3.fromRGB(205, 210, 228), 11, Enum.Font.Gotham, 63
    sub.TextXAlignment, sub.TextTruncate = Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd

    local closeBtn = Instance.new("TextButton", f)
    closeBtn.Size, closeBtn.Position, closeBtn.BackgroundColor3 = UDim2.new(0, 30, 0, 30), UDim2.new(1, -42, 0, 12), Color3.fromRGB(230, 50, 60)
    closeBtn.Text, closeBtn.TextColor3, closeBtn.TextSize, closeBtn.Font, closeBtn.ZIndex = "X", Color3.fromRGB(255,255,255), 15, Enum.Font.GothamBold, 64
    Corner(closeBtn, UDim.new(0, 8))

    local box = Instance.new("TextBox", f)
    box.Size, box.Position, box.BackgroundColor3, box.BackgroundTransparency = UDim2.new(1, -40, 0, 44), UDim2.new(0, 20, 0, 78), Color3.fromRGB(22, 24, 38), 0.2
    box.PlaceholderText, box.Text, box.TextColor3, box.TextSize, box.Font, box.ZIndex = "🔑 Dán key vào đây...", "", Color3.fromRGB(255,255,255), 14, Enum.Font.GothamBold, 63
    box.PlaceholderColor3, box.ClearTextOnFocus, box.ClipsDescendants = Color3.fromRGB(170,175,190), false, true
    Corner(box, UDim.new(0, 10))
    do local bs = Instance.new("UIStroke", box); bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; bs.Color, bs.Thickness, bs.Transparency = Color3.fromRGB(0, 160, 210), 1.5, 0.2 end

    local status = Instance.new("TextLabel", f)
    status.BackgroundTransparency, status.Size, status.Position = 1, UDim2.new(1, -40, 0, 20), UDim2.new(0, 20, 0, 128)
    status.Text, status.TextColor3, status.TextSize, status.Font, status.ZIndex = "", Color3.fromRGB(255,200,50), 12, Enum.Font.GothamBold, 63

    -- nút 2 dòng (tên + phụ đề), có màu chuyển + viền sáng
    local function mkBtn(text, subText, x, color, w)
        local b = Instance.new("TextButton", f)
        b.Size, b.Position, b.BackgroundColor3 = UDim2.new(0, w or 100, 0, 52), UDim2.new(0, x, 0, 160), color
        b.RichText, b.TextWrapped = true, true
        b.Text = text .. '\n<font size="10" color="rgb(225,230,245)">' .. subText .. '</font>'
        b.TextColor3, b.TextSize, b.Font, b.ZIndex = Color3.fromRGB(255,255,255), 14, Enum.Font.GothamBold, 63
        Corner(b, UDim.new(0, 12))
        local g = Instance.new("UIGradient", b)
        g.Color, g.Rotation = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 218)), 90
        local st = Instance.new("UIStroke", b); st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Color, st.Thickness, st.Transparency = Color3.new(1, 1, 1), 1.5, 0.7
        return b
    end
    local webBtn = mkBtn("🌐 Chép link web lấy key", "Ấn để chép link, dán vào trình duyệt", 20, Color3.fromRGB(88, 101, 242), 225)
    local verBtn = mkBtn("✅ Verify", "Ấn để kiểm tra key", 255, Color3.fromRGB(50, 180, 80), 125)

    local foot = Instance.new("TextLabel", f)
    foot.BackgroundTransparency, foot.Size, foot.Position = 1, UDim2.new(1, -40, 0, 16), UDim2.new(0, 20, 1, -26)
    foot.Text, foot.TextColor3, foot.TextSize, foot.Font, foot.ZIndex = "👑 VzNamHub v4.6 : Tổng Hợp", Color3.fromRGB(160, 165, 190), 10, Enum.Font.GothamMedium, 63

    local passed, closed = false, false

    closeBtn.MouseButton1Click:Connect(function()
        closed = true
        _G.__vznam_log("WARNING", "Đóng menu nhập key")
        DisconnectAll()
        if SoundService:FindFirstChild("VzNamHubSound") then SoundService.VzNamHubSound:Destroy() end
        if CoverGui then CoverGui:Destroy() end
        ScreenGui:Destroy()
    end)

    local function pass(k, left, prem)
        if passed or closed then return end
        passed = true
        local txt = "Vĩnh viễn"
        if prem then
            pcall(function() if delfile and isfile and isfile(KEY_CFG.SaveFile) then delfile(KEY_CFG.SaveFile) end end)
        else
            pcall(function() if writefile then writefile(KEY_CFG.SaveFile, k) end end)
            if left then
                txt = math.floor(left / 86400) .. " ngày " .. math.floor(left % 86400 / 3600) .. " giờ"
            end
        end
        _G.__vznam_log("SUCCESS", "Key hợp lệ! Còn lại: " .. txt)
        f:Destroy(); onSuccess()
        task.delay(3, function() pcall(ShowToast, "🔑 Key còn lại: " .. txt) end)
    end

    -- [MỚI] chép link web (kèm uid) để dán lên trình duyệt
    webBtn.MouseButton1Click:Connect(function()
        local link = KEY_CFG.Worker .. "/?uid=" .. localPlayer.UserId
        if typeof(setclipboard) == "function" then
            setclipboard(link); status.Text = "📋 Đã chép link web, dán vào trình duyệt!"
            _G.__vznam_log("INFO", "Đã chép link web lấy key")
        else
            status.Text = link
        end
    end)

    verBtn.MouseButton1Click:Connect(function()
        status.Text = "Đang kiểm tra..."
        task.spawn(function()
            local clean = (box.Text:gsub("%s", ""))
            local ok, left, prem = CheckKey(clean)
            if ok then pass(clean, left, prem) else status.Text = "❌ " .. tostring(left) end
        end)
    end)

    task.spawn(function()
        -- [MỚI] 1) Tự verify key PREMIUM đã chọn (nếu bật "Auto verify key premium" trong tab KEY PREMIUM)
        local pk = State.GetAutoPremiumKey and State.GetAutoPremiumKey()
        if pk then
            status.Text = "⏳ Đang tự verify key premium..."
            local okp, leftp, premp = CheckKey(pk)
            if okp and premp then
                _G.__vznam_log("SUCCESS", "Auto verify key premium thành công!")
                pass(pk, leftp, true)
                return
            end
            status.Text = "❌ Auto verify premium thất bại: " .. tostring(okp and "key không phải premium" or leftp)
        end

        -- 2) Key thường đã lưu (như cũ)
        if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(KEY_CFG.SaveFile) then
            local okr, saved = pcall(readfile, KEY_CFG.SaveFile)
            if okr and type(saved) == "string" then
                local okc, left, prem = CheckKey(saved)
                if okc and not prem then
                    pass((saved:gsub("%s", "")), left, false)
                end
            end
        end
    end)
end

-- ===== THANH LOADING 1 -> 10 RỒI MỞ MENU =====
OpenButton.Visible = false
State.Ld.Frame.Visible = false

local function RunLoading()
    State.Ld.Frame.Visible = true
    task.spawn(function()
        local TOTAL = 10
        local loadingTxt = (State.Language == "EN") and "Loading... " or "Đang load... "
        for i = 1, TOTAL do
            if not State.Ld.Frame.Parent then return end
            State.Ld.Sub.Text = loadingTxt .. i .. "/" .. TOTAL
            TweenService:Create(State.Ld.Fill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(i / TOTAL, 0, 1, 0)}):Play()
            task.wait(0.2)
        end
        task.wait(0.15)
        if State.Ld.Frame.Parent then State.Ld.Frame:Destroy() end
        if ScreenGui.Parent then
            OpenButton.Visible = true
            if not State.IsAutoLoad then State.SetMenu(true) end
        end
    end)
end

RunLoading()
print("[VzNamHub v4.6 : Tổng Hợp] ✅ Loaded.")
