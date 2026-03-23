local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--
local espEnabled = false
local aimbotEnabled = false
local BOX_COLOR = Color3.fromRGB(0, 0, 0) -- Xanh lá cho Box
local TRACER_COLOR = Color3.fromRGB(0, 0, 0) -- Trắng cho đường kẻ
local AIM_PART = "Head"

-- Bảng lưu trữ các đường kẻ để quản lý
local Tracers = {}

-- Hàm gửi thông báo
local function sendNotification(title, message, duration)
	StarterGui:SetCore("SendNotification", {
		Title = title,
		Text = message,
		Duration = duration or 3
	})
end

-- Thông báo khởi chạy
task.spawn(function()
	task.wait(1)
	sendNotification("We love Argo <3", "Press U to use ESP/Hold E to use Aimbot", 10)
end)

-- === HÀM TẠO ĐƯỜNG KẺ (TRACERS) ===
local function createTracer(player)
	local line = Drawing.new("Line")
	line.Visible = false
	line.Color = TRACER_COLOR
	line.Thickness = 1
	line.Transparency = 1
	Tracers[player] = line
end

-- === PHẦN ESP BOX ===
local function createBox(player)
    createTracer(player) -- Tạo thêm tracer cho mỗi player
	local function onCharacterAdded(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if not hrp then return end

		local bgui = Instance.new("BillboardGui")
		bgui.Name = "ArgoBoxESP"
		bgui.Adornee = hrp
		bgui.AlwaysOnTop = true
		bgui.Size = UDim2.new(4.5, 0, 6, 0)
		bgui.Enabled = espEnabled
		bgui.Parent = hrp

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.Parent = bgui

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Color = BOX_COLOR
		stroke.Parent = frame
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then onCharacterAdded(player.Character) end
end

-- Khởi tạo ban đầu
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then createBox(player) end
end
Players.PlayerAdded:Connect(createBox)
Players.PlayerRemoving:Connect(function(player)
	if Tracers[player] then
		Tracers[player]:Remove()
		Tracers[player] = nil
	end
end)

-- === VÒNG LẶP CẬP NHẬT (RENDERSTEPPED) ===
RunService.RenderStepped:Connect(function()
	-- Xử lý Aimbot
	if aimbotEnabled then
		local closest = nil
		local dist = math.huge
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(AIM_PART) then
				local pos, onScreen = Camera:WorldToViewportPoint(p.Character[AIM_PART].Position)
				if onScreen then
					local mPos = UserInputService:GetMouseLocation()
					local mag = (Vector2.new(pos.X, pos.Y) - mPos).Magnitude
					if mag < dist then dist = mag; closest = p end
				end
			end
		end
		if closest then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character[AIM_PART].Position)
		end
	end

	-- Xử lý Tracers (Mấy cái que)
	for player, line in pairs(Tracers) do
		if espEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)

			if onScreen then
				line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Gốc từ dưới giữa màn hình
				line.To = Vector2.new(vector.X, vector.Y)
				line.Visible = true
			else
				line.Visible = false
			end
		else
			line.Visible = false
		end
	end
end)

-- === ĐIỀU KHIỂN PHÍM BẤM ===
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.U then
		espEnabled = not espEnabled
		-- Bật tắt Box
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local gui = p.Character.HumanoidRootPart:FindFirstChild("ArgoBoxESP")
				if gui then gui.Enabled = espEnabled end
			end
		end
		sendNotification("Argo ESP", "nige esp : " .. (espEnabled and "on" or "off"), 3)
	elseif input.KeyCode == Enum.KeyCode.E then
		aimbotEnabled = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then aimbotEnabled = false end
end)
