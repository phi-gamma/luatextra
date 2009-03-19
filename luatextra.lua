do
    local luatextrapath = kpse.find_file("luatextra.lua")
    if luatextrapath then
        if luatextrapath:sub(1,2) == "./" then
            luatextrapath = luatextrapath:sub(3)
        end
        texio.write(' ('..luatextrapath) 
    end
end

luatextra = {}

module("luatextra", package.seeall)

luatextra.modules = luatextra.modules or {}

luatextra.modules['luatextra'] = {
    version     = 0.91,
    name        = "luatextra",
    date        = "2009/03/19",
    description = "Low level functions for LuaTeX basic usage",
    author      = "Elie Roux",
    copyright   = "Elie Roux, 2009",
    license     = "CC0",
}

local format = string.format

luatextra.internal_warning_spaces = "                   "

function luatextra.internal_warning(msg)
    if not msg then return end
    texio.write_nl(format("\nLuaTeXtra Warning: %s\n\n", msg))
end

luatextra.internal_error_spaces = "                 "

function luatextra.internal_error(msg)
    if not msg then return end
    tex.sprint(format("\\immediate\\write16{}\\errmessage{LuaTeXtra error: %s^^J^^J}", msg))
end

function luatextra.module_error(package, msg, helpmsg)
    if not package or not msg then
        return
    end
    if helpmsg then
        tex.sprint(format("\\errhelp{%s}", helpmsg))
    end
    tex.sprint(format("\\luaModuleError{%s}{%s}", package, msg))
end

function luatextra.module_warning(modulename, msg)
    if not modulename or not msg then
        return
    end
    texio.write_nl(format("\nModule %s Warning: %s\n\n", modulename, msg))
end

function luatextra.module_log(modulename, msg)
    if not modulename or not msg then
        return
    end
    texio.write_nl('log', format("%s: %s", modulename, msg))
end

function luatextra.module_term(modulename, msg)
    if not modulename or not msg then
        return
    end
    texio.write_nl('term', format("%s: %s", modulename, msg))
end

function luatextra.module_info(modulename, msg)
    if not modulename or not msg then
        return
    end
    texio.write_nl(format("%s: %s\n", modulename, msg))
end

function luatextra.find_module_file(name)
    if string.sub(name, -4) ~= '.lua' then
        name = name..'.lua'
    end
    path = kpse.find_file(name)
    return path, name
end

-- If I don't do this, module become a table instead of a function after its first call, which I don't understand...
luatextra.module = module

function luatextra.use_module(name)
    if not name or luatextra.modules[name] then
        return
    end
    local path, filename = luatextra.find_module_file(name)
    if not path then
        luatextra.internal_error(format("unable to find lua module %s", name))
    else
        if path:sub(1,2) == "./" then
            path = path:sub(3)
        end
        texio.write(' ('..path)
        dofile(path)
        if not luatextra.modules[name] then
            luatextra.internal_warning(format("You have requested module `%s',\n%s but the file %s does not provide it.", name, luatextra.internal_warning_spaces, filename))
        end
        if not package.loaded[name] then
            luatextra.module(name, package.seeall)
        end
        texio.write(')')
    end
end

function luatextra.datetonumber(date)
    numbers = string.gsub(date, "(%d+)/(%d+)/(%d+)", "%1%2%3")
    return tonumber(numbers)
end

function luatextra.isdate(date)
    for _, _ in string.gmatch(date, "%d+/%d+/%d+") do
        return true
    end
    return false
end

local date, number = 1, 2

function luatextra.versiontonumber(version)
    if luatextra.isdate(version) then
        return {type = date, version = luatextra.datetonumber(version), orig = version}
    else
        return {type = number, version = tonumber(version), orig = version}
    end
end

luatextra.requiredversions = {}

function luatextra.require_module(name, version)
    if not name then
        return
    end
    if not version then
        return luatextra.use_module(name)
    end
    luaversion = luatextra.versiontonumber(version)
    if luatextra.modules[name] then
        if luaversion.type == date then
            if luatextra.datetonumber(luatextra.modules[name].date) < luaversion.version then
                luatextra.internal_error(format("found module `%s' loaded in version %s, but version %s was required", name, luatextra.modules[name].date, version))
            end
        else
            if luatextra.modules[name].version < luaversion.version then
                luatextra.internal_error(format("found module `%s' loaded in version %.02f, but version %s was required", name, luatextra.modules[name].version, version))
            end
        end
    else
        luatextra.requiredversions[name] = luaversion
        luatextra.use_module(name)
    end
end

function luatextra.provides_module(mod)
    if not mod then
        luatextra.internal_error('cannot provide nil module')
        return
    end
    if not mod.version or not mod.name or not mod.date or not mod.description then
        luatextra.internal_error('invalid module registered, fields name, version, date and description are mandatory')
        return
    end
    requiredversion = luatextra.requiredversions[mod.name]
    if requiredversion then
        if requiredversion.type == date and requiredversion.version > luatextra.datetonumber(mod.date) then
            luatextra.internal_error(format("loading module %s in version %s, but version %s was required", mod.name, mod.date, requiredversion.orig))
        elseif requiredversion.type == number and requiredversion.version > mod.version then
            luatextra.internal_error(format("loading module %s in version %.02f, but version %s was required", mod.name, mod.version, requiredversion.orig))
        end
    end
    luatextra.modules[mod.name] = module
    texio.write_nl('log', format("Lua module: %s %s v%.02f %s\n", mod.name, mod.date, mod.version, mod.description))
end

luatextra.use_module('luaextra')

function luatextra.kpse_module_loader(mod)
  local script = mod .. ".lua"
  local file = kpse.find_file(script, "texmfscripts")
  if file then
    local loader, error = loadfile(file)
    if loader then
      texio.write_nl("(" .. file .. ")")
      return loader
    end
    return "\n\t[luatextra.kpse_module_loader] Loading error:\n\t"
           .. error
  end
  return "\n\t[luatextra.kpse_module_loader] Search failed"
end

table.insert(package.loaders, luatextra.kpse_module_loader)

luatextra.attributes = {}

tex.attributenumber = luatextra.attributes

function luatextra.attributedef(name, number)
    truename = name:gsub('[\\ ]', '')
    luatextra.attributes[truename] = tonumber(number)
end

luatextra.catcodetables = {}

tex.catcodetablenumber = luatextra.catcodetables

function luatextra.catcodetabledef(name, number)
    truename = name:gsub('[\\ ]', '')
    luatextra.catcodetables[truename] = tonumber(number)
end

function luatextra.open_read_file(filename)
    local path = kpse.find_file(filename)
    local env = {
      ['filename'] = filename,
      ['path'] = path,
    }
    luamcallbacks.call('pre_read_file', env)
    path = env.path
    if not path then
        return
    end
    local f = env.file
    if not f then
        f = io.open(path)
        env.file = f
    end
    if not f then
        return
    end
    env.reader = luatextra.reader
    env.close = luatextra.close
    return env
end

function luatextra.reader(env)
    local line = (env.file):read()
    line = luamcallbacks.call('file_reader', env, line)
    return line
end

function luatextra.close(env)
    (env.file):close()
    luamcallbacks.call('file_close', env)
end

function luatextra.default_reader(env, line)
    return line
end

function luatextra.default_close(env)
    return
end

function luatextra.default_pre_read(env)
    return env
end

function luatextra.find_font(name)
    local types = {'ofm', 'ovf', 'opentype fonts', 'truetype fonts'}
    local path = kpse.find_file(name)
    if path then return path end
    for _,t in pairs(types) do
        path = kpse.find_file(name, t)
        if path then return path end
    end
    return nil
end

function luatextra.font_load_error(error)
    luatextra.module_warning('luatextra', string.format('%s\nloading lmr10 instead...', error))
end

function luatextra.load_default_font(size)
    return font.read_tfm("lmr10", size)
end

function luatextra.define_font(name, size)
    if (size < 0) then size = (- 655.36) * size end
    local fontinfos = {
        asked_name = name,
        name = name,
        size = size
        }
    callback.call('font_syntax', fontinfos)
    local path = fontinfos.path
    if not path then
        path = luatextra.find_font(name)
        fontinfos.path = luatextra.find_font(name)
    end
    if not path then
        luatextra.font_load_error("unable to find font "..name)
        return luatextra.load_default_font(size)
    end
    if not fontinfos.filename then
        fontinfos.filename = fpath.basename(path)
    end
    local ext = fpath.suffix(path)
    local f
    if ext == 'tfm' or ext == 'ofm' then
        f =  font.read_tfm(name, size)
    elseif ext == 'vf' or ext == 'ovf' then
        f =  font.read_vf(name, size)
    elseif ext == 'ttf' or ext == 'otf' or ext == 'ttc' then
        f = callback.call('open_otf_font', fontinfos)
    else
        luatextra.font_load_error("unable to find font "..name)
        f = luatextra.load_default_font(size)
    end
    if not f then
        luatextra.font_load_error("unable to find font "..name)
        f = luatextra.load_default_font(size)
    end
    callback.call('post_font_opening', f, fontinfos)
    return f
end

function luatextra.default_font_syntax(fontinfos)
    return
end

function luatextra.default_open_otf(fontinfos)
    return nil
end

function luatextra.default_post_font(f, fontinfos)
    return true
end

do
    luatextra.use_module('luamcallbacks')
    callback.create('pre_read_file', 'simple', luatextra.default_pre_read)
    callback.create('file_reader', 'data', luatextra.default_reader)
    callback.create('file_close', 'simple', luatextra.default_close)
    callback.add('open_read_file', luatextra.open_read_file, 'luatextra.open_read_file')
    callback.create('font_syntax', 'simple', luatextra.default_font_syntax)
    callback.create('open_otf_font', 'first', luatextra.default_open_otf)
    callback.create('post_font_opening', 'simple', luatextra.default_post_font)
    callback.add('define_font', luatextra.define_font, 'luatextra.define_font')

    if luatextrapath then
        texio.write(')')
    end
end
