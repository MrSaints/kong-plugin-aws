# kong-plugin-aws

_A work in progress. Use at your own risk._

A [Kong][kong] plugin for signing incoming requests with Amazon Web Services (AWS) [authentication headers v4][aws-signature].

This plugin is based on Kong's [`aws-lambda`][kong-plugin-aws-lambda] plugin, and the [`kong-plugin`][kong-plugin] boilerplate. It was developed using [`docker-kong-dev`][docker-kong-dev], an unofficial [Docker][docker] image (tooling) for Kong testing, and development.

It can be used for proxying requests to an upstream AWS API / service (e.g. ElasticSearch). In doing so, you can send HTTP requests without using [bespoke proxies][proxies], AWS SDKs or [external libraries][extlib] to sign your requests. You can instead rely on widely supported authentication methods (e.g. basic auth, token auth, etc) via [Kong plugins][kong-plugins].


[kong]: https://getkong.org/
[aws-signature]: http://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html
[kong-plugin-aws-lambda]: https://github.com/Mashape/kong/tree/master/kong/plugins/aws-lambda
[kong-plugin]: https://github.com/Mashape/kong-plugin
[docker-kong-dev]: https://github.com/MrSaints/docker-kong-dev
[docker]: https://www.docker.com/
[proxies]: https://github.com/abutaha/aws-es-proxy
[extlib]: https://github.com/DavidMuller/aws-requests-auth
[kong-plugins]: https://getkong.org/plugins/
