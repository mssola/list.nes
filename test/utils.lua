utils = {}

-- Returns the root path for the project.
function utils.RootPath()
  local fullpath = debug.getinfo(1,"S").source:sub(2)
  fullpath = io.popen("realpath '"..fullpath.."'", 'r'):read()
  fullpath = fullpath:gsub('[\n\r]*$','')

  local dirname, filename = fullpath:match('^(.*/)([^/]-)$')
  dirname = dirname or ''
  if dirname == '' then
    return ''
  end

  return io.popen("realpath '"..dirname.."/..'", 'r'):read()
end

-- At a `label` that exists on the assembly code grab the values for the given
-- addresses and write it all into the `test-results.txt` file. The `addresses`
-- array is made up of two-sized arrays, where the first element contains the
-- memory you are trying to test, and the second element is the value that we
-- are expecting.
function utils.MemTest(label, addresses)
  local cmd = "cat ".. utils.RootPath() .. "/tmp/labels.txt | grep .".. label .." | awk '{ print $2; }' | cut -c3-"
  local file = assert(io.popen(cmd, 'r'))
  local result = file:read("*a")

  -- Double check that the address that we grabbed has at least a good format.
  if string.len(result) ~= 5 then
    error("Error on '" .. label .. "': got a bad address! (".. result ..")")
  end

  -- Register a function to execute on the given test address. The function will
  -- simply iterate over the given `addresses` and compare them with the
  -- expected result. Everything will be saved into the `test-results.txt` file.
  memory.registerexecute(tonumber(result, 16), function()
    local expected = ""
    local got = ""

    for _, vals in ipairs(addresses) do
      expected = expected .. "$" .. string.format("%04X", vals[1]) .. " -> " .. vals[2] .. "; "
      got = got .. "$" .. string.format("%04X", vals[1]) .. " -> " .. string.format("%02X", memory.readbyte(vals[1])) .. "; "
    end

    file = io.open(utils.RootPath() .. "/tmp/test-results.txt", "a")
    io.output(file)

    if expected == got then
      io.write("-> Test '".. label .."': OK\n")
    else
      io.write("\n-> Test '".. label .."': FAIL\n")
      io.write("Expected: ".. expected .. "\n")
      io.write("Got: ".. got .. "\n")
      io.write("\n")
    end
    io.close(file)
  end)
end

function utils.StartRun(title)
    file = io.open(utils.RootPath() .. "/tmp/test-results.txt", "a")
    io.output(file)
    io.write("\n== " .. title .. " ==\n")
    io.close(file)
end

-- Ends the given test run. That is, it will exit from the emulator so we can
-- turn back to the runner.
function utils.EndRun()
  -- I'm not entirely sure why this is needed, but if we don't advance for
  -- several frames fceux won't exit. Thus, let's advance for some frames and
  -- then quit.
  for i = 0, 10, 1 do
    emu.frameadvance();
  end

  emu.exit()
end

return utils
