'use strict';
// Lambda@Edge viewer-response: inyecta cabeceras de seguridad
// Se aplica tanto a cache HIT como MISS (por eso viewer-response y no origin-response)
exports.handler = async (event) => {
  const response = event.Records[0].cf.response;
  const headers = response.headers;

  headers['strict-transport-security'] = [{ key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' }];
  headers['x-content-type-options'] = [{ key: 'X-Content-Type-Options', value: 'nosniff' }];
  headers['x-frame-options'] = [{ key: 'X-Frame-Options', value: 'DENY' }];
  headers['referrer-policy'] = [{ key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' }];
  headers['content-security-policy'] = [{ key: 'Content-Security-Policy', value: "default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'" }];

  return response;
};
