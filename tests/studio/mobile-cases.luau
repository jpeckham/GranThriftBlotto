return function(runtime, client, check, waitFor, errors)
	local Players = game:GetService("Players")
	local Http = game:GetService("HttpService")
	local player = Players:GetPlayers()[1]
	waitFor(function()
		return runtime.phase == "Heist"
	end, 45, "phone solo round")
	local report = client(player, { kind = "Inspect" })
	check(report.guideOpen, "phone guide stays visible until acknowledged")
	check(#report.clipped == 0, "phone first-time guide text fits: " .. table.concat(report.clipped, " | "))
	client(player, { kind = "Button", text = "Got it" })
	report = client(player, { kind = "Inspect" })
	check(not report.guideOpen, "phone player can dismiss guide through its button")
	check(
		math.abs(math.min(report.viewport[1], report.viewport[2]) - 320) <= 1,
		"native phone simulation uses 320-pixel short edge: " .. Http:JSONEncode(report.viewport)
	)
	local function disjoint(a, b)
		return a.x + a.w <= b.x + 1 or b.x + b.w <= a.x + 1 or a.y + a.h <= b.y + 1 or b.y + b.h <= a.y + 1
	end
	check(
		report.boxes.stats and report.boxes.cars and disjoint(report.boxes.stats, report.boxes.cars),
		"phone stash panel and Buick status do not overlap " .. Http:JSONEncode(report.boxes)
	)
	check(disjoint(report.boxes.stats, report.boxes.actions), "phone action buttons do not overlap the stash panel")
	for name, box in report.boxes do
		check(
			box.x >= -1
				and box.y >= -1
				and box.x + box.w <= report.safeSize[1] + 1
				and box.y + box.h <= report.safeSize[2] + 1,
			"phone " .. name .. " stays inside safe UI area"
		)
	end
	check(#report.clipped == 0, "phone HUD text fits: " .. table.concat(report.clipped, " | "))
	client(player, { kind = "Key", key = "M" })
	local menu = client(player, { kind = "Inspect" })
	check(#menu.clipped == 0, "phone help menu text fits: " .. table.concat(menu.clipped, " | "))
	client(player, { kind = "Button", text = "Classes" })
	local classes = client(player, { kind = "Inspect" })
	check(#classes.clipped == 0, "phone class descriptions fit: " .. table.concat(classes.clipped, " | "))
	client(player, { kind = "Key", key = "M" })
	-- A UI fixture presents the Cop view without ending the one-player test.
	runtime.phase = "UI Verification"
	runtime:state(player).role = "Cop"
	task.wait(0.5)
	local cop = client(player, { kind = "Inspect" })
	check(
		cop.boxes.cameraExit and cop.boxes.cameraExit.x + cop.boxes.cameraExit.w <= cop.safeSize[1] + 1,
		"phone cop CCTV exit remains accessible"
	)
	check(#cop.clipped == 0, "phone cop HUD text fits: " .. table.concat(cop.clipped, " | "))
	for _, name in { "cameraNext", "cameraExit" } do
		local box = cop.boxes[name]
		check(
			box
				and disjoint(box, cop.boxes.stats)
				and disjoint(box, cop.boxes.cars)
				and disjoint(box, cop.boxes.actions),
			"phone " .. name .. " does not overlap other HUD controls"
		)
	end
	check(disjoint(cop.boxes.cameraNext, cop.boxes.cameraExit), "phone CCTV buttons do not overlap each other")
	client(player, { kind = "Key", key = "M" })
	client(player, { kind = "Button", text = "Help" })
	local copGuide = client(player, { kind = "Inspect" })
	check(#copGuide.clipped == 0, "phone Cop instructions fit: " .. table.concat(copGuide.clipped, " | "))
	check(#cop.errors == 0 and #errors == 0, "no game-script errors in phone UI scenario")
	return { passed = true, suite = "mobile", viewport = report.viewport, platformErrors = cop.platformErrors }
end
