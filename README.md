# kong-plugin-aws

_A work in progress. Use at your own risk._

A [Kong][kong] plugin for signing incoming requests with Amazon Web Services (AWS) [authentication headers v4][aws-signature].

This plugin is based on Kong's [`aws-lambda`][kong-plugin-aws-lambda] plugin, and the [`kong-plugin`][kong-plugin] boilerplate. It was developed using [`docker-kong-dev`][docker-kong-dev], an unofficial [Docker][docker] image (tooling) for Kong testing, and development.

It can be used for proxying requests to an upstream AWS API / service (e.g. ElasticSearch). In doing so, you can send HTTP requests without using [bespoke proxies][proxies], AWS SDKs or [external libraries][extlib] to sign your requests. You can instead rely on widely supported authentication methods (e.g. basic auth, token auth, etc) via [Kong plugins][kong-plugins].


## Getting Started

It is not currently published in luarocks, so it will have to be built / packaged manually. Otherwise, use the pre-installed / loaded version of Kong.

### Pre-installed / loaded Docker

Instead of `docker pull kong`, use:

```
docker pull mrsaints/kong-aws
```

### Configuration

Field | Type | Description
--- | --- | ---
`aws_region` | `string` | The region the service resides in, e.g. `us-east-1`.
`aws_service` | `string` | The service namespace that identifies the AWS product (for example, Amazon S3, IAM, or Amazon RDS). For a list of namespaces, see [AWS Service Namespaces][service-namespaces].
`aws_key` | `string` | The AWS key credential to be used when signing a request.
`aws_secret` | `string` | The AWS secret credential to be used when signing a request.
`timestamp` | `timestamp` | (Optional) This is used for signing a request with the current datetime. It is mostly used for testing, so leave this alone unless you know what you are doing.


[kong]: https://getkong.org/
[aws-signature]: http://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html
[kong-plugin-aws-lambda]: https://github.com/Mashape/kong/tree/master/kong/plugins/aws-lambda
[kong-plugin]: https://github.com/Mashape/kong-plugin
[docker-kong-dev]: https://github.com/MrSaints/docker-kong-dev
[docker]: https://www.docker.com/
[proxies]: https://github.com/abutaha/aws-es-proxy
[extlib]: https://github.com/DavidMuller/aws-requests-auth
[kong-plugins]: https://getkong.org/plugins/
[service-namespaces]: http://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#genref-aws-service-namespaces