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
        },
      })

      local response_body = assert.res_status(200, res)

      -- Has AWS date header
      local amz_date_header_value = assert.request(res).has.header("X-Amz-Date")
      assert.equal("20170427T195449Z", amz_date_header_value)

      -- Has AWS signed headers
      assert.request(res).has.header("User-Agent")

      -- `Host` is preserved
      local host_header_value = assert.request(res).has.header("Host")
      assert.not_equal("mockbin.com", host_header_value)

      -- Has AWS authorization header
      local authorization_header_value = assert.request(res).has.header("Authorization")
      assert.equal(
        "AWS4-HMAC-SHA256 Credential=A6OM0YYOU01MIBT9IMGR/20170427/us-east-1/es/aws4_request, SignedHeaders=host;user-agent;x-amz-date, Signature=4d8a04280c8bd7c68ddb9d6acd227b1c0068e5e6f8eabb6492cfaf4729de32c2",
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
        },
        body = json_body,
      })

      local response_body = assert.res_status(200, res)

      -- Has AWS date header
      local amz_date_header_value = assert.request(res).has.header("X-Amz-Date")
      assert.equal("20170427T195449Z", amz_date_header_value)

      -- Has AWS signed headers
      assert.request(res).has.header("Content-Length")
      assert.request(res).has.header("User-Agent")

      -- `Host` is preserved
      local host_header_value = assert.request(res).has.header("Host")
      assert.not_equal("mockbin.com", host_header_value)

      -- Has AWS authorization
      local authorization_header_value = assert.request(res).has.header("Authorization")
      assert.equal(
        "AWS4-HMAC-SHA256 Credential=A6OM0YYOU01MIBT9IMGR/20170427/us-east-1/es/aws4_request, SignedHeaders=content-length;host;user-agent;x-amz-date, Signature=57f96a31b1521abf5a95998f4502f7d31aa450e222ecb98f9142a6c2a363a5ad",
        authorization_header_value
      )

      -- Original body is sent in request
      local req_body = assert.request(res).has.jsonbody()
      assert.equal(json_body, cjson.encode(req_body))
    end)
  end)
end)
