--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local rebatedog_model = require "luci.model.rebatedog"
local m, s, o

m = taskd.docker_map("rebatedog", "rebatedog", "/usr/libexec/istorec/rebatedog.sh",
	translate("Rebatedog"),
	translate("Rebatedog is a multi platform system for TaoKe.")
		.. translate("Official website:") .. ' <a href=\"https://www.yuque.com/sunnysoft\" target=\"_blank\">https://www.yuque.com/sunnysoft</a>'
)

s = m:section(SimpleSection, translate("Service Status"), translate("Rebatedog status:"))
s:append(Template("rebatedog/status"))

s = m:section(TypedSection, "rebatedog", translate("Setup"),
		translate("Please make sure that the Docker data directory has enough space. It is recommended to migrate Docker to a hard drive before installing Rebatedog.") 
		.. "<br>" .. translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Flag, "hostnet", translate("Host network"), translate("Rebatedog running in host network, port is always 15888 if enabled"))
o.default = 1
o.rmempty = false

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "15888"
o.datatype = "port"
o:depends("hostnet", 0)

local blocks = rebatedog_model.blocks()
local home = rebatedog_model.home()

o = s:option(Value, "config_path", translate("Config path"),translate("Important, Store database").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = rebatedog_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
