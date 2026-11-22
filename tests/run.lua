-- Unit tests for the pure Core files, outside the game (docs/adr/0007).
--   luajit tests/run.lua
-- Files are loaded the way the client loads them: each gets the addon name
-- and the shared namespace table as its `...`.
local ADDON = "JunkAway"
local ns = {}
for _, file in ipairs({ "Locales/enUS.lua", "Core/Ranking.lua", "Core/Settings.lua", "Core/IgnoreList.lua", "Core/Display.lua" }) do
  assert(loadfile(file))(ADDON, ns)
end

local passed, failed = 0, 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL  " .. name .. "\n      " .. tostring(err))
  end
end

local function eq(actual, expected, what)
  if actual ~= expected then
    error((what or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

-- Each test file gets the namespace and the helpers: local ns, test, eq = ...
for _, file in ipairs({ "tests/ranking_test.lua", "tests/settings_test.lua", "tests/ignorelist_test.lua", "tests/display_test.lua" }) do
  assert(loadfile(file))(ns, test, eq)
end

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
