local plugin = require("kong.plugins.base_plugin"):extend()

local aws_v4 = require "kong.plugins.aws-lambda.v4"
local responses = require "kong.tools.responses"

function plugin:new()
  plugin.super.new(self, "aws")
end

function plugin:access(plugin_conf)
  plugin.super.access(self)

  ngx.req.read_body()

  local opts = {
    region = plugin_conf.aws_region,
    service = plugin_conf.aws_service,
    access_key = plugin_conf.aws_key,
    secret_key = plugin_conf.aws_secret,
    timestamp = plugin_conf.timestamp,
    method = ngx.req.get_method(),
    headers = ngx.req.get_headers(),
    body = ngx.req.get_body_data(),
    path = ngx.var.uri,
    canonical_querystring = ngx.var.args,
  }

  local request, err = aws_v4(opts)
  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  for key, val in pairs(request.headers) do
    ngx.req.set_header(key, val)
  end
end

plugin.PRIORITY = 1000

return plugin
