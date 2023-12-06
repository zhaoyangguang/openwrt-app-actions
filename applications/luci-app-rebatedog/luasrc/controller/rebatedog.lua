
module("luci.controller.rebatedog", package.seeall)

function index()
  entry({"admin", "services", "rebatedog"}, alias("admin", "services", "rebatedog", "config"), _("Rebatedog"), 30).dependent = true
  entry({"admin", "services", "rebatedog", "config"}, cbi("rebatedog"))
end
