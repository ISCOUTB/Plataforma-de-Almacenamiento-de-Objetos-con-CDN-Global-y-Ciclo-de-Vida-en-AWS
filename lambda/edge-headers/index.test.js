'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const { handler } = require('./index');

test('agrega las cinco cabeceras de seguridad con los valores configurados', async () => {
  const response = { status: '200', headers: {} };
  const result = await handler({ Records: [{ cf: { response } }] });

  assert.deepEqual(result.headers, {
    'strict-transport-security': [
      { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
    ],
    'x-content-type-options': [{ key: 'X-Content-Type-Options', value: 'nosniff' }],
    'x-frame-options': [{ key: 'X-Frame-Options', value: 'DENY' }],
    'referrer-policy': [{ key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' }],
    'content-security-policy': [
      {
        key: 'Content-Security-Policy',
        value: "default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
      },
    ],
  });
});

test('reemplaza una cabecera previa y conserva el resto de la respuesta', async () => {
  const contentType = [{ key: 'Content-Type', value: 'text/html; charset=utf-8' }];
  const response = {
    status: '200',
    statusDescription: 'OK',
    headers: {
      'content-type': contentType,
      'x-frame-options': [{ key: 'X-Frame-Options', value: 'SAMEORIGIN' }],
    },
  };

  const result = await handler({ Records: [{ cf: { response } }] });

  assert.equal(result.status, '200');
  assert.equal(result.statusDescription, 'OK');
  assert.deepEqual(result.headers['content-type'], contentType);
  assert.deepEqual(result.headers['x-frame-options'], [{ key: 'X-Frame-Options', value: 'DENY' }]);
});
