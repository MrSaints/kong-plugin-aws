local helpers = require "spec.helpers"
local cjson = require "cjson.safe"
-- Useful for debugging
local plpretty = require "pl.pretty"

describe("Plugin: AWS (access)", function()
  local client

  setup(function()
    local api1 = assert(helpers.dao.apis:insert {
      name = "aws-elasticsearch",
      hosts = { "mockbin.org" },
      upstream_url = "http://mockbin.com",
    })

    assert(helpers.dao.plugins:insert {
      name = "aws",
      api_id = api1.id,
      config = {
        aws_region = "us-east-1",
        aws_service = "es",
        aws_key = "A6OM0YYOU01MIBT9IMGR",
        aws_secret = "X17gy7kSjAVEraVOWgl+SeLkR3jjv9NE/O6X1mdX",
        -- Freeze timestamp for deterministic test results (signature)
        timestamp = "1493322889",
      }
    })

    assert(helpers.start_kong {custom_plugins = "aws"})
  end)

  teardown(function()
    helpers.stop_kong()
  end)

  before_each(function()
    client = helpers.proxy_client()
  end)

  after_each(function()
    if client then client:close() end
  end)

  describe("request", function()
    it("GET contains AWS headers", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request/_cluster/health?level=shards&pretty",
        headers = {
          ["Host"] = "mockbin.org",
          ["Content-Type"] = "text/html; charset=utf-8",
          ["Ignored"] = "this should not be signed",
        },
      })

      local response_body = assert.res_status(200, res)

      -- Has AWS date header
      local amz_date_header_value = assert.request(res).has.header("X-Amz-Date")
      assert.equal("20170427T195449Z", amz_date_header_value)

      -- Has AWS signed headers
      assert.request(res).has.header("Content-Type")

      -- `Host` is preserved
      local host_header_value = assert.request(res).has.header("Host")
      assert.not_equal("mockbin.com", host_header_value)

      -- Has AWS authorization header
      local authorization_header_value = assert.request(res).has.header("Authorization")
      assert.equal(
        "AWS4-HMAC-SHA256 Credential=A6OM0YYOU01MIBT9IMGR/20170427/us-east-1/es/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=34b72395a1f1e1b000b01e97ee96280381fc682833225795f7cfcb79726d40bc",
        authorization_header_value
      )
    end)

    it("POST contains AWS headers, and original body", function()
      local request_body = {
        query = {
          match_phrase = {
            name = "harry waye",
          },
        },
      }
      local json_body = cjson.encode(request_body)
      local res = assert(client:send {
        method = "POST",
        path = "/request/_search",
        headers = {
          ["Host"] = "mockbin.org",
          ["Content-Type"] = "application/json",
          ["Ignored"] = "this should not be signed",
        },
        body = json_body,
      })

      local response_body = assert.res_status(200, res)

      -- Has AWS date header
      local amz_date_header_value = assert.request(res).has.header("X-Amz-Date")
      assert.equal("20170427T195449Z", amz_date_header_value)

      -- Has AWS signed headers
      assert.request(res).has.header("Content-Length")
      assert.request(res).has.header("Content-Type")

      -- `Host` is preserved
      local host_header_value = assert.request(res).has.header("Host")
      assert.not_equal("mockbin.com", host_header_value)

      -- Has AWS authorization
      local authorization_header_value = assert.request(res).has.header("Authorization")
      assert.equal(
        "AWS4-HMAC-SHA256 Credential=A6OM0YYOU01MIBT9IMGR/20170427/us-east-1/es/aws4_request, SignedHeaders=content-length;content-type;host;x-amz-date, Signature=ba457c73822620f9653cdf11e45c9de4bcd32d2fe63eee719f46a51c72ed0a18",
        authorization_header_value
      )

      -- Original body is sent in request
      local req_body = assert.request(res).has.jsonbody()
      assert.equal(json_body, cjson.encode(req_body))
    end)
  end)
end)
