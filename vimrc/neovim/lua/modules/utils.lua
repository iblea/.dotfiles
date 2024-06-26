local utils = {}
local api = vim.api

local scopes = { o = vim.o, b = vim.bo, w = vim.wo }

local function get_map_options(custom_options)
  local options = { noremap = true, silent = true }
  if custom_options then
    options = vim.tbl_extend("force", options, custom_options)
  end
  return options
end

local function get_map_options_expr(custom_options)
  local options = { expr = true, noremap = true, silent = true }
  if custom_options then
    options = vim.tbl_extend("force", options, custom_options)
  end
  return options
end

function utils.opt(scope, key, value)
  scopes[scope][key] = value
  if scope ~= "o" then
    scopes["o"][key] = value
  end
end

function utils.map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, get_map_options(opts))
end

function utils.map_expr(mode, lhs, rhs, opts)
  api.nvim_set_keymap(mode, lhs, rhs, get_map_options_expr(opts))
end

function utils.buf_map(mode, target, source, opts, bufnr)
  api.nvim_buf_set_keymap(
    bufnr or 0,
    mode,
    target,
    source,
    get_map_options(opts)
  )
end

function utils.lua_command(name, command)
  vim.api.nvim_create_user_command(name, "lua " .. command, {})
end

function utils.some(tbl, cb)
  for key, value in pairs(tbl) do
    if cb(key, value) then
      return true
    end
  end
  return false
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2 
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "   
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end

return utils
