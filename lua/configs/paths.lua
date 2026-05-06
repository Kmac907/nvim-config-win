local M = {}
local python_venv_ready
local python_executable
local is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1

M.is_windows = is_windows
M.path_list_sep = is_windows and ";" or ":"

local function stat(path)
  return path and vim.uv.fs_stat(path)
end

local function executable_variants(name)
  if not is_windows or name:match "%.[^/\\]+$" then
    return { name }
  end

  return {
    name,
    name .. ".cmd",
    name .. ".exe",
    name .. ".bat",
  }
end

function M.mason_bin(name)
  local root = vim.fn.stdpath "data" .. "/mason/bin/"

  for _, candidate in ipairs(executable_variants(name)) do
    local path = root .. candidate
    if stat(path) then
      return path
    end
  end
end

function M.executable(name)
  for _, candidate in ipairs(executable_variants(name)) do
    if vim.fn.executable(candidate) == 1 then
      return vim.fn.exepath(candidate)
    end
  end

  local mason_bin = M.mason_bin(name)
  if mason_bin then
    return mason_bin
  end

  if is_windows then
    local appdata = vim.fn.expand "$APPDATA"
    if appdata ~= "" then
      for _, candidate in ipairs(executable_variants(name)) do
        local local_npm = vim.fs.joinpath(appdata, "npm", candidate)
        if stat(local_npm) then
          return local_npm
        end
      end
    end
  else
    local local_npm = vim.fn.expand("~/.local/npm/bin/" .. name)
    if stat(local_npm) then
      return local_npm
    end

    local local_npm_modules = vim.fn.expand("~/.local/npm/node_modules/.bin/" .. name)
    if stat(local_npm_modules) then
      return local_npm_modules
    end
  end
end

function M.mason_path(package, pattern)
  local root = vim.fn.stdpath "data" .. "/mason/packages/" .. package .. "/"
  local patterns = pattern

  if type(patterns) == "table" and (patterns.unix or patterns.win or patterns.windows) then
    patterns = is_windows and (patterns.win or patterns.windows) or patterns.unix
  end

  if type(patterns) == "string" then
    patterns = { patterns }
  end

  for _, current_pattern in ipairs(patterns or {}) do
    local matches = vim.fn.glob(root .. current_pattern, true, true)

    for _, match in ipairs(matches) do
      if stat(match) then
        return match
      end
    end
  end
end

function M.mason_package(package)
  local root = vim.fn.stdpath "data" .. "/mason/packages/" .. package
  if stat(root) then
    return root
  end
end

function M.python_executable()
  if python_executable ~= nil then
    return python_executable or nil
  end

  local candidates = is_windows and { "python", "python3" } or { "python3", "python" }

  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then
      python_executable = vim.fn.exepath(candidate)
      return python_executable
    end
  end

  python_executable = false
  return nil
end

function M.first(...)
  for _, value in ipairs { ... } do
    if value then
      return value
    end
  end
end

function M.python_venv_support()
  if python_venv_ready ~= nil then
    return python_venv_ready
  end

  local python = M.python_executable()
  if not python then
    python_venv_ready = false
    return python_venv_ready
  end

  vim.fn.system { python, "-c", "import ensurepip, venv" }
  python_venv_ready = vim.v.shell_error == 0

  return python_venv_ready
end

return M
