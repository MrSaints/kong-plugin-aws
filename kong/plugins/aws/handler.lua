local plugin = require("kong.plugins.base_plugin"):extend()
local responses = require "kong.tools.responses"

package.path = package.path .. ";../?.lua"
local aws_v4 = require "kong.plugins.aws.v4"

function plugin:new()
  plugin.super.new(self, "aws")
end

function plugin:access(plugin_conf)
  plugin.super.access(self)

  ngx.req.read_body()

  local headers = ngx.req.get_headers()
  headers['host'] = ngx.var.host
  headers['connection'] = nil

  local opts = {
    region = plugin_conf.aws_region,
    service = plugin_conf.aws_service,
    access_key = plugin_conf.aws_key,
    secret_key = plugin_conf.aws_secret,
    timestamp = plugin_conf.timestamp,
    body = ngx.req.get_body_data(),
    canonical_querystring = ngx.var.args,
    headers = headers,
    method = ngx.req.get_method(),
    path = ngx.var.uri,
    port = ngx.var.port,
  }

  local request, err = aws_v4(opts)
  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  for key, val in pairs(request.headers) do
    ngx.req.set_header(key, val)
  end

  -- Use the same `Host` as the one used for signing the request
  ngx.var.upstream_host = request.host
end

plugin.PRIORITY = 1000

return plugin
