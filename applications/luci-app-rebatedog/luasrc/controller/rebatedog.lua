local util  = require "luci.util"
local http = require "luci.http"
local docker = require "luci.model.docker"
local iform = require "luci.iform"

module("luci.controller.rebatedog", package.seeall)

function index()

  entry({"admin", "services", "rebatedog"}, call("redirect_index"), _("Rebatedog"), 30).dependent = true
  entry({"admin", "services", "rebatedog", "pages"}, call("rebatedog_index")).leaf = true
  entry({"admin", "services", "rebatedog", "form"}, call("rebatedog_form"))
  entry({"admin", "services", "rebatedog", "submit"}, call("rebatedog_submit"))

end

local appname = "rebatedog"
local page_index = {"admin", "services", "rebatedog", "pages"}
local rebatedog_model = require "luci.model.rebatedog"

local blocks = rebatedog_model.blocks()
local home = rebatedog_model.home()

local default_path = rebatedog_model.find_paths(blocks, home, "DogData")


function redirect_index()
    http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function rebatedog_index()
    luci.template.render("rebatedog/main", {prefix=luci.dispatcher.build_url(unpack(page_index))})
end

function rebatedog_form()
    local error = ""
    local scope = ""
    local success = 0

    local data = get_data()
    local result = {
        data = data,
        schema = get_schema(data)
    } 
    local response = {
            error = error,
            scope = scope,
            success = success,
            result = result,
    }
    http.prepare_content("application/json")
    http.write_json(response)
end

function get_schema(data)
  local actions
  if data.container_install then
    actions = {
      {
          name = "restart",
          text = "重启",
          type = "apply",
      },
      {
          name = "upgrade",
          text = "更新",
          type = "apply",
      },
      {
          name = "remove",
          text = "删除",
          type = "apply",
      },
    } 
  else
    actions = {
      {
          name = "install",
          text = "安装",
          type = "apply",
      },
    }
  end
    local schema = {
      actions = actions,
      containers = get_containers(data),
      description = "跨平台的淘客发单返利工具 访问教程 <a href=\"https://www.yuque.com/sunnysoft\" target=\"_blank\">https://www.yuque.com/sunnysoft</a>",
      title = "旺财狗"
    }
    return schema
end

function get_containers(data) 
    local containers = {
        status_container(data),
        main_container(data)
    }
    return containers
end

function status_container(data)
  local status_value

  if data.container_install then
    status_value = "旺财狗 运行中"
  else
    status_value = "旺财狗 未运行"
  end
  local status_c1 = {
    labels = {
      {
        key = "状态：",
        value = status_value
      },
      {
        key = "访问：",
        value = "",
        --value="'<a href=\"https://' + location.host + ':' + port + '\" target=\"_blank\">旺财狗管理页</a>'"
      }

    },
    description = "请认真配置数据目录，程序运行数据都保存在您设置的数据目录中。",
    title = "服务状态"
  }
  return status_c1
end

function main_container(data)
    local main_c2 = {
        properties = {
          {
            name = "port",
            required = true,
            title = "端口",
            type = "string"
          },
          {
            name = "data_path",
            required = true,
            title = "存储路径",
            type = "string"
          },         
        },
        description = "请配置好数据路径和端口号进行安装：",
        title = "服务操作"
      }
      return main_c2
end

function get_data() 
  local uci = require "luci.model.uci".cursor()
  local docker_path = util.exec("which docker")
  local docker_install = (string.len(docker_path) > 0)
  -- docker ps -aqf
  local container_id = util.trim(util.exec("docker ps -qf 'name="..appname.."'"))
  local container_install = (string.len(container_id) > 0)
  local port = tonumber(uci:get_first(appname, appname, "port", "15888"))
  local data = {
    port = port,
    data_path = uci:get_first(appname, appname, "data_path", default_path),
    image ="zhaoyangguang/rebatedog:latest",
    container_install = container_install
  }
  return data
end

function rebatedog_submit()
    local error = ""
    local scope = ""
    local success = 0
    local result
    
    local jsonc = require "luci.jsonc"
    local json_parse = jsonc.parse
    local content = http.content()
    local req = json_parse(content)
    if req["$apply"] == "upgrade" then
      result = install_upgrade_rebatedog(req)
    elseif req["$apply"] == "install" then 
      result = install_upgrade_rebatedog(req)
    elseif req["$apply"] == "restart" then 
      result = restart_rebatedog(req)
    else
      result = delete_rebatedog()
    end
    http.prepare_content("application/json")
    local resp = {
        error = error,
        scope = scope,
        success = success,
        result = result,
    }
    http.write_json(resp)
end

function install_upgrade_rebatedog(req)
  local data_path = req["data_path"]
  local port = req["port"]
  local image = req["image"]

  -- save config
  local uci = require "luci.model.uci".cursor()
  uci:tset(appname, "@"..appname.."[0]", {
    data_path = data_path or "",
    port = port or "15888",
    image = image or "zhaoyangguang/rebatedog:latest",
  })
  uci:save(appname)
  uci:commit(appname)

  local exec_cmd = string.format("/usr/libexec/istorec/rebatedog.sh %s", req["$apply"])
  exec_cmd = "/etc/init.d/tasks task_add rebatedog " .. luci.util.shellquote(exec_cmd)
  os.execute(exec_cmd .. " >/dev/null 2>&1")

  local result = {
    async = true,
    async_state = appname
  }
  return result
end

function delete_rebatedog()
  local log = iform.exec_to_log("docker rm -f rebatedog")
  local result = {
    async = false,
    log = log
  }
  return result
end

function restart_rebatedog()
  local log = iform.exec_to_log("docker restart rebatedog")
  local result = {
    async = false,
    log = log
  }
  return result
end

