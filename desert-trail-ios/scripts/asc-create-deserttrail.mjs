import fs from 'node:fs';
import crypto from 'node:crypto';

const keyId = '8W59ZRTHZ4';
const issuerId = '26cc2279-524d-4d33-ba75-9333cf111ad1';
const identifier = 'com.batalaldroob.deserttrail';
const privateKey = fs.readFileSync(`${process.env.HOME}/.appstoreconnect/private_keys/AuthKey_${keyId}.p8`, 'utf8');

function b64url(input) {
  return Buffer.from(input).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function token() {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'ES256', kid: keyId, typ: 'JWT' }));
  const payload = b64url(JSON.stringify({ iss: issuerId, iat: now, exp: now + 900, aud: 'appstoreconnect-v1' }));
  const data = `${header}.${payload}`;
  const signature = crypto.sign('sha256', Buffer.from(data), { key: privateKey, dsaEncoding: 'ieee-p1363' });
  return `${data}.${b64url(signature)}`;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function api(path, options = {}) {
  let lastError;
  for (let attempt = 0; attempt < 4; attempt += 1) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 30000);
      const response = await fetch(`https://api.appstoreconnect.apple.com/v1${path}`, {
        ...options,
        signal: controller.signal,
        headers: {
          Authorization: `Bearer ${token()}`,
          'Content-Type': 'application/json',
          ...(options.headers || {})
        }
      });
      clearTimeout(timeout);
      const text = await response.text();
      const body = text ? JSON.parse(text) : null;
      if (!response.ok) {
        const error = new Error(`HTTP ${response.status}`);
        error.status = response.status;
        error.path = path;
        error.body = body;
        throw error;
      }
      return body;
    } catch (error) {
      lastError = error;
      await sleep(2000 * (attempt + 1));
    }
  }
  console.log(JSON.stringify({
    ok: false,
    error: String(lastError),
    status: lastError?.status,
    path: lastError?.path,
    body: lastError?.body
  }, null, 2));
  process.exit(2);
}

let bundle = (await api(`/bundleIds?filter[identifier]=${encodeURIComponent(identifier)}&limit=1`)).data[0];
if (!bundle) {
  bundle = (await api('/bundleIds', {
    method: 'POST',
    body: JSON.stringify({
      data: {
        type: 'bundleIds',
        attributes: {
          identifier,
          name: 'DesertTrail',
          platform: 'IOS'
        }
      }
    })
  })).data;
}

let app = (await api(`/apps?filter[bundleId]=${encodeURIComponent(identifier)}&limit=1`)).data[0];
if (!app) {
  app = (await api('/apps', {
    method: 'POST',
    body: JSON.stringify({
      data: {
        type: 'apps',
        attributes: {
          bundleId: identifier,
          name: 'درب الصحراء',
          primaryLocale: 'ar-SA',
          sku: 'DESERT-TRAIL-1'
        }
      }
    })
  })).data;
}

console.log(JSON.stringify({
  bundle: {
    id: bundle.id,
    identifier: bundle.attributes.identifier,
    name: bundle.attributes.name
  },
  app: {
    id: app.id,
    name: app.attributes.name,
    bundleId: app.attributes.bundleId,
    sku: app.attributes.sku
  }
}, null, 2));
