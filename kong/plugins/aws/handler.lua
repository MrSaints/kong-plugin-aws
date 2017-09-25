local plugin = require("kong.plugins.base_plugin"):extend()
local responses = require "kong.tools.responses"

local aws_v4 = require "kong.plugins.aws.v4"

function plugin:new()
  plugin.super.new(self, "aws")
end

function plugin:access(plugin_conf)
  plugin.super.access(self)

  ngx.req.read_body()

  local incoming_headers = ngx.req.get_headers()
  local headers = {}

  -- Sign the request using the `Host` without
  -- a port, as this is what Kong uses.
  headers["host"] = ngx.var.host

  -- Proxy the content headers only as they are AWS requirements.
  -- They are also likely the only headers to remain consistent
  -- between Client -> Kong -> AWS.
  headers["content-length"] = incoming_headers["content-length"]
  headers["content-type"] = incoming_headers["content-type"]

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

  -- Use the same `Host` as the one used
  -- for signing the request.
  ngx.var.upstream_host = request.host
end

plugin.PRIORITY = 750

return plugin
