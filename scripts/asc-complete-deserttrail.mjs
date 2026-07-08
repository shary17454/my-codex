import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';

const keyId = process.env.ASC_KEY_ID;
const issuerId = process.env.ASC_ISSUER_ID;
const appId = process.env.ASC_APP_ID;
const privateKeyPath = process.env.ASC_PRIVATE_KEY_PATH || (keyId ? `${process.env.HOME}/.appstoreconnect/private_keys/AuthKey_${keyId}.p8` : '');

if (!keyId || !issuerId || !appId || !privateKeyPath) {
  throw new Error('Missing ASC_KEY_ID, ASC_ISSUER_ID, ASC_APP_ID, or ASC_PRIVATE_KEY_PATH.');
}

const privateKey = fs.readFileSync(privateKeyPath, 'utf8');
const root = path.resolve(import.meta.dirname, '..');

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

async function api(pathname, options = {}) {
  const response = await fetch(`https://api.appstoreconnect.apple.com/v1${pathname}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token()}`,
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(options.headers || {})
    }
  });
  const text = await response.text();
  const body = text ? JSON.parse(text) : null;
  if (!response.ok) {
    const error = new Error(`HTTP ${response.status} ${pathname}`);
    error.status = response.status;
    error.body = body;
    throw error;
  }
  return body;
}

async function getVersionContext() {
  const versions = await api(`/apps/${appId}/appStoreVersions?filter[platform]=IOS&include=appStoreVersionLocalizations,build&limit=10`);
  const version = versions.data.find(item => item.attributes.versionString === '1.0') || versions.data[0];
  if (!version) throw new Error('No iOS App Store version found.');
  const localization = (versions.included || []).find(item => item.type === 'appStoreVersionLocalizations');
  if (!localization) throw new Error('No App Store version localization found.');
  const build = (versions.included || []).find(item => item.type === 'builds');
  return { version, localization, build };
}

async function getContentRights(versionId) {
  try {
    return await api(`/appStoreVersions/${versionId}/appStoreVersionContentRightsDeclaration`);
  } catch (error) {
    if (error.status === 404) return null;
    throw error;
  }
}

async function ensureContentRights(versionId) {
  const existing = await getContentRights(versionId);
  if (existing?.data?.id) return { status: 'already_exists', id: existing.data.id };
  const created = await api('/appStoreVersionContentRightsDeclarations', {
    method: 'POST',
    body: JSON.stringify({
      data: {
        type: 'appStoreVersionContentRightsDeclarations',
        attributes: {
          usesThirdPartyContent: false
        },
        relationships: {
          appStoreVersion: {
            data: { type: 'appStoreVersions', id: versionId }
          }
        }
      }
    })
  });
  return { status: 'created', id: created.data.id };
}

async function getScreenshotSets(localizationId) {
  return api(`/appStoreVersionLocalizations/${localizationId}/appScreenshotSets?include=appScreenshots&limit=200`);
}

async function createScreenshotSet(localizationId, screenshotDisplayType) {
  return api('/appScreenshotSets', {
    method: 'POST',
    body: JSON.stringify({
      data: {
        type: 'appScreenshotSets',
        attributes: { screenshotDisplayType },
        relationships: {
          appStoreVersionLocalization: {
            data: { type: 'appStoreVersionLocalizations', id: localizationId }
          }
        }
      }
    })
  });
}

async function ensureScreenshotSet(localizationId, screenshotDisplayType) {
  const sets = await getScreenshotSets(localizationId);
  const existing = sets.data.find(set => set.attributes.screenshotDisplayType === screenshotDisplayType);
  if (existing) return existing;
  return (await createScreenshotSet(localizationId, screenshotDisplayType)).data;
}

async function uploadOneScreenshot(setId, filePath) {
  const file = fs.readFileSync(filePath);
  const checksum = crypto.createHash('md5').update(file).digest('hex');
  const created = await api('/appScreenshots', {
    method: 'POST',
    body: JSON.stringify({
      data: {
        type: 'appScreenshots',
        attributes: {
          fileName: path.basename(filePath),
          fileSize: file.length
        },
        relationships: {
          appScreenshotSet: {
            data: { type: 'appScreenshotSets', id: setId }
          }
        }
      }
    })
  });

  for (const operation of created.data.attributes.uploadOperations || []) {
    const headers = {};
    for (const header of operation.requestHeaders || []) headers[header.name] = header.value;
    const uploadResponse = await fetch(operation.url, {
      method: operation.method,
      headers,
      body: file.subarray(operation.offset, operation.offset + operation.length)
    });
    if (!uploadResponse.ok) {
      throw new Error(`Screenshot upload failed ${uploadResponse.status} for ${filePath}`);
    }
  }

  const committed = await api(`/appScreenshots/${created.data.id}`, {
    method: 'PATCH',
    body: JSON.stringify({
      data: {
        type: 'appScreenshots',
        id: created.data.id,
        attributes: {
          uploaded: true,
          sourceFileChecksum: checksum
        }
      }
    })
  });
  return committed.data;
}

async function deleteScreenshots(set) {
  const screenshots = set.relationships?.appScreenshots?.data || [];
  for (const screenshot of screenshots) {
    await api(`/appScreenshots/${screenshot.id}`, { method: 'DELETE' });
  }
  return screenshots.length;
}

async function uploadScreenshots(localizationId) {
  const jobs = [
    {
      displayType: 'APP_IPHONE_65',
      dir: path.join(root, 'DesertTrail/AppStore/Screenshots-1242x2688')
    },
    {
      displayType: 'APP_IPAD_PRO_3GEN_129',
      dir: path.join(root, 'DesertTrail/AppStore/Screenshots-2064x2752')
    }
  ];
  const results = [];
  for (const job of jobs) {
    const set = await ensureScreenshotSet(localizationId, job.displayType);
    const deleted = await deleteScreenshots(set);
    const files = fs.readdirSync(job.dir).filter(name => name.endsWith('.png')).sort().slice(0, 10);
    for (const name of files) {
      const uploaded = await uploadOneScreenshot(set.id, path.join(job.dir, name));
      results.push({ displayType: job.displayType, deletedBeforeUpload: deleted, file: name, id: uploaded.id, uploaded: uploaded.attributes.uploaded });
    }
  }
  return results;
}

async function main() {
  const mode = process.argv[2] || 'status';
  if (mode === 'builds') {
    const builds = await api(`/builds?filter[app]=${appId}&sort=-uploadedDate&limit=10`);
    const versions = await api(`/apps/${appId}/appStoreVersions?filter[platform]=IOS&include=build&limit=10`);
    console.log(JSON.stringify({
      appId,
      builds: builds.data.map(build => ({
        id: build.id,
        version: build.attributes.version,
        uploadedDate: build.attributes.uploadedDate,
        processingState: build.attributes.processingState,
        expired: build.attributes.expired,
        minOsVersion: build.attributes.minOsVersion
      })),
      appStoreVersions: versions.data.map(version => ({
        id: version.id,
        versionString: version.attributes.versionString,
        state: version.attributes.appStoreState,
        buildRelationship: version.relationships?.build?.data || null
      }))
    }, null, 2));
    return;
  }
  if (mode === 'select-build') {
    const targetBuildNumber = process.argv[3];
    if (!targetBuildNumber) throw new Error('Usage: select-build <build-number>');
    const builds = await api(`/builds?filter[app]=${appId}&filter[version]=${encodeURIComponent(targetBuildNumber)}&limit=1`);
    const targetBuild = builds.data[0];
    if (!targetBuild) throw new Error(`Build not found: ${targetBuildNumber}`);
    const versions = await api(`/apps/${appId}/appStoreVersions?filter[platform]=IOS&limit=10`);
    const version = versions.data.find(item => item.attributes.versionString === '1.0') || versions.data[0];
    if (!version) throw new Error('No iOS App Store version found.');
    await api(`/appStoreVersions/${version.id}/relationships/build`, {
      method: 'PATCH',
      body: JSON.stringify({
        data: {
          type: 'builds',
          id: targetBuild.id
        }
      })
    });
    console.log(JSON.stringify({
      appId,
      appStoreVersionId: version.id,
      appStoreVersionState: version.attributes.appStoreState,
      selectedBuild: {
        id: targetBuild.id,
        version: targetBuild.attributes.version,
        processingState: targetBuild.attributes.processingState
      }
    }, null, 2));
    return;
  }
  const { version, localization, build } = await getVersionContext();
  if (mode === 'status') {
    const rights = await getContentRights(version.id);
    const sets = await getScreenshotSets(localization.id);
    console.log(JSON.stringify({
      appId,
      version: { id: version.id, versionString: version.attributes.versionString, state: version.attributes.appStoreState },
      localization: { id: localization.id, locale: localization.attributes.locale },
      build: build && { id: build.id, version: build.attributes.version, processingState: build.attributes.processingState },
      contentRights: rights?.data ? { id: rights.data.id, usesThirdPartyContent: rights.data.attributes.usesThirdPartyContent } : null,
      screenshotSets: sets.data.map(set => ({
        id: set.id,
        displayType: set.attributes.screenshotDisplayType,
        screenshots: set.relationships?.appScreenshots?.data?.length || 0
      }))
    }, null, 2));
    return;
  }
  if (mode === 'content-rights') {
    console.log(JSON.stringify(await ensureContentRights(version.id), null, 2));
    return;
  }
  if (mode === 'screenshots') {
    console.log(JSON.stringify(await uploadScreenshots(localization.id), null, 2));
    return;
  }
  throw new Error(`Unknown mode: ${mode}`);
}

main().catch(error => {
  console.error(JSON.stringify({
    message: error.message,
    status: error.status,
    body: error.body
  }, null, 2));
  process.exit(1);
});
