local helpers = require "spec.helpers"
local cjson = require "cjson.safe"
-- Useful for debugging
local plpretty = require "pl.pretty"

describe("Plugin: AWS (access)", function()
  local client

  setup(function()
    local api1 = assert(helpers.dao.apis:insert {
      name = "es.aws.amazon.com",
      hosts = { "es.aws.amazon.com" },
      upstream_url = "http://mockbin.com",
    })

    assert(helpers.dao.plugins:insert {
      name = "aws",
      api_id = api1.id,
      config = {
        aws_region = "us-east-1",
        aws_service = "es",
        aws_key = "AKIAIDPNYYGMJOXN26SQ",
        aws_secret = "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",
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
          ["Host"] = "es.aws.amazon.com",
        },
      })

      local response_body = assert.res_status(200, res)

      local amz_date_header_value = assert.request(res).has.header("X-Amz-Date")
      assert.equal("20170427T195449Z", amz_date_header_value)

      -- Has signed headers
      assert.request(res).has.header("Host")
      assert.request(res).has.header("User-Agent")

      local authorization_header_value = assert.request(res).has.header("Authorization")
      assert.equal(
        "AWS4-HMAC-SHA256 Credential=AKIAIDPNYYGMJOXN26SQ/20170427/us-east-1/es/aws4_request, SignedHeaders=host;user-agent;x-amz-date, Signature=0eb414f9a430bb950aeb445cdc9ab4daebb39ba5e2e70755787bef09a8667d35",
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
          ["Host"] = "es.aws.amazon.com",
        },
        body = json_body,
      })

      local response_body = assert.res_status(200, res)

      local amz_date_header_value = assert.request(res).has.header("X-Amz-Date")
      assert.equal("20170427T195449Z", amz_date_header_value)

      local authorization_header_value = assert.request(res).has.header("Authorization")
      assert.equal(
        "AWS4-HMAC-SHA256 Credential=AKIAIDPNYYGMJOXN26SQ/20170427/us-east-1/es/aws4_request, SignedHeaders=content-length;host;user-agent;x-amz-date, Signature=629614313d1746fa36493f7f8381f2a8232ba269f4d93767214b9720c889eeef",
        authorization_header_value
      )

      -- Has signed headers
      assert.request(res).has.header("Content-Length")
      assert.request(res).has.header("Host")
      assert.request(res).has.header("User-Agent")

      local req_body = assert.request(res).has.jsonbody()
      assert.equal(json_body, cjson.encode(req_body))
    end)
  end)
end)
