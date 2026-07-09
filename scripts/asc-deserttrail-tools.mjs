import fs from 'node:fs';
import crypto from 'node:crypto';

const keyId = process.env.ASC_KEY_ID;
const issuerId = process.env.ASC_ISSUER_ID;
const appId = process.env.ASC_APP_ID;
const privateKeyPath = process.env.ASC_PRIVATE_KEY_PATH || (keyId ? `${process.env.HOME}/.appstoreconnect/private_keys/AuthKey_${keyId}.p8` : '');

if (!keyId || !issuerId || !appId || !privateKeyPath) {
  throw new Error('Missing ASC_KEY_ID, ASC_ISSUER_ID, ASC_APP_ID, or ASC_PRIVATE_KEY_PATH.');
}

const privateKey = fs.readFileSync(privateKeyPath, 'utf8');

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

async function api(path, options = {}) {
  const response = await fetch(`https://api.appstoreconnect.apple.com/v1${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token()}`,
      'Content-Type': 'application/json',
      ...(options.headers || {})
    }
  });
  const text = await response.text();
  const body = text ? JSON.parse(text) : null;
  if (!response.ok) {
    const error = new Error(`HTTP ${response.status} ${path}`);
    error.status = response.status;
    error.body = body;
    throw error;
  }
  return body;
}

async function main() {
  const mode = process.argv[2] || 'read';
  const versions = await api(`/apps/${appId}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION&include=appStoreVersionLocalizations,appStoreVersionPhasedRelease&limit=10`);
  const version = versions.data[0];
  const included = versions.included || [];
  const localization = included.find(item => item.type === 'appStoreVersionLocalizations');
  const appInfos = await api(`/apps/${appId}/appInfos?include=appInfoLocalizations,primaryCategory,secondaryCategory&limit=10`);
  const categories = await api('/appCategories?limit=200');
  const appInfo = appInfos.data[0];
  const appInfoLocalization = (appInfos.included || []).find(item => item.type === 'appInfoLocalizations');

  if (mode === 'update-basics') {
    await api(`/appInfoLocalizations/${appInfoLocalization.id}`, {
      method: 'PATCH',
      body: JSON.stringify({
        data: {
          type: 'appInfoLocalizations',
          id: appInfoLocalization.id,
          attributes: {
            privacyPolicyUrl: 'https://github.com/shary17454/my-codex'
          }
        }
      })
    });
    await api(`/appInfos/${appInfo.id}/relationships/primaryCategory`, {
      method: 'PATCH',
      body: JSON.stringify({
        data: {
          type: 'appCategories',
          id: 'NAVIGATION'
        }
      })
    });
    await api(`/appInfos/${appInfo.id}/relationships/secondaryCategory`, {
      method: 'PATCH',
      body: JSON.stringify({
        data: {
          type: 'appCategories',
          id: 'TRAVEL'
        }
      })
    });
  }

  if (mode === 'update-name') {
    await api(`/appInfoLocalizations/${appInfoLocalization.id}`, {
      method: 'PATCH',
      body: JSON.stringify({
        data: {
          type: 'appInfoLocalizations',
          id: appInfoLocalization.id,
          attributes: {
            name: 'رفيق الدروب'
          }
        }
      })
    });
  }

  console.log(JSON.stringify({
    mode,
    version: version && {
      id: version.id,
      versionString: version.attributes.versionString,
      appStoreState: version.attributes.appStoreState,
      platform: version.attributes.platform
    },
    localization: localization && {
      id: localization.id,
      locale: localization.attributes.locale,
      privacyPolicyUrl: localization.attributes.privacyPolicyUrl
    },
    appInfo: appInfos.data.map(info => ({
      id: info.id,
      appStoreState: info.attributes.appStoreState,
      relationships: info.relationships
    })),
    appInfoLocalization: appInfoLocalization && {
      id: appInfoLocalization.id,
      locale: appInfoLocalization.attributes.locale,
      name: appInfoLocalization.attributes.name,
      privacyPolicyUrl: appInfoLocalization.attributes.privacyPolicyUrl
    },
    categories: categories.data.map(category => ({
      id: category.id,
      name: category.attributes.name,
      platforms: category.attributes.platforms
    }))
  }, null, 2));
}

main().catch(error => {
  console.error(JSON.stringify({
    message: error.message,
    status: error.status,
    body: error.body
  }, null, 2));
  process.exit(1);
});
