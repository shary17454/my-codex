import { createSign } from "node:crypto";
import { readFile } from "node:fs/promises";

const issuerId = process.env.ASC_ISSUER_ID;
const keyId = process.env.ASC_KEY_ID;
const keyPath = process.env.ASC_KEY_PATH;
const bundleIdentifier = process.env.ASC_BUNDLE_ID || "com.shary17454.esal";
const targetVersion = process.env.ASC_APP_VERSION || "2.1";
const targetBuildNumber = process.env.ASC_BUILD_NUMBER || "99";
const shouldSubmit = process.env.ASC_SUBMIT === "1";
const shouldCreateVersion = process.env.ASC_CREATE_VERSION === "1";
const shouldListBuilds = process.env.ASC_LIST_BUILDS === "1";
const shouldUpdateMetadata = process.env.ASC_UPDATE_METADATA === "1";
const appStoreName = process.env.ASC_APP_NAME || "وش الراي";
const whatsNew =
  process.env.ASC_WHATS_NEW ||
  [
    "تحسين تجربة المقارنات والتصويت.",
    "إضافة سبب التصويت حتى يوضح المستخدم لماذا اختار هذا الخيار.",
    "تحسين قاعدة المعرفة المحلية ونتائج البحث.",
    "تحسينات في الأداء والاستقرار وإصلاحات عامة.",
  ].join("\n");

if (!issuerId || !keyId || !keyPath) {
  throw new Error("Missing ASC_ISSUER_ID, ASC_KEY_ID, or ASC_KEY_PATH.");
}

const privateKey = await readFile(keyPath, "utf8");

function base64url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function derToJose(signature) {
  let offset = 0;
  if (signature[offset++] !== 0x30) throw new Error("Invalid ECDSA signature.");
  const length = signature[offset++];
  if (length + 2 !== signature.length) throw new Error("Unexpected ECDSA signature length.");
  if (signature[offset++] !== 0x02) throw new Error("Invalid ECDSA R marker.");
  const rLength = signature[offset++];
  const r = signature.subarray(offset, offset + rLength);
  offset += rLength;
  if (signature[offset++] !== 0x02) throw new Error("Invalid ECDSA S marker.");
  const sLength = signature[offset++];
  const s = signature.subarray(offset, offset + sLength);

  const normalize = (part) => {
    let value = part;
    while (value.length > 32 && value[0] === 0) value = value.subarray(1);
    if (value.length > 32) throw new Error("ECDSA integer is too long.");
    return value.length === 32 ? value : Buffer.concat([Buffer.alloc(32 - value.length), value]);
  };

  return Buffer.concat([normalize(r), normalize(s)]);
}

function jwt() {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  const payload = { iss: issuerId, iat: now, exp: now + 20 * 60, aud: "appstoreconnect-v1" };
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;
  const signature = derToJose(createSign("SHA256").update(signingInput).sign(privateKey));
  return `${signingInput}.${base64url(signature)}`;
}

async function request(path, options = {}) {
  const response = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${jwt()}`,
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });

  const text = await response.text();
  let json = {};
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = { raw: text };
  }

  if (!response.ok) {
    const message = json.errors?.map((error) => error.detail || error.title).join(" | ");
    throw new Error(`${response.status} ${response.statusText}: ${message || JSON.stringify(json)}`);
  }

  return json;
}

function encode(value) {
  return encodeURIComponent(value);
}

function includesArabic(localization) {
  const locale = localization.attributes?.locale || "";
  return locale.toLowerCase().startsWith("ar");
}

async function patchResource(type, id, attributes) {
  return request(`/v1/${type}/${id}`, {
    method: "PATCH",
    body: JSON.stringify({
      data: {
        type,
        id,
        attributes,
      },
    }),
  });
}

const apps = await request(`/v1/apps?filter%5BbundleId%5D=${encode(bundleIdentifier)}`);
const app = apps.data?.[0];
if (!app) throw new Error(`App not found for bundle ID ${bundleIdentifier}`);

if (shouldListBuilds) {
  const allBuilds = await request(`/v1/builds?filter%5Bapp%5D=${app.id}&limit=20&sort=-uploadedDate`);
  console.log(
    JSON.stringify(
      {
        appId: app.id,
        bundleIdentifier,
        builds: allBuilds.data?.map((item) => ({
          id: item.id,
          version: item.attributes?.version,
          buildNumber: item.attributes?.buildNumber,
          processingState: item.attributes?.processingState,
          uploadedDate: item.attributes?.uploadedDate,
          expired: item.attributes?.expired,
        })),
      },
      null,
      2
    )
  );
  process.exit(0);
}

let versions = await request(
  `/v1/apps/${app.id}/appStoreVersions?filter%5Bplatform%5D=IOS&limit=200`
);
let appStoreVersion = versions.data?.find(
  (item) => item.attributes?.versionString === targetVersion
);
if (!appStoreVersion) {
  if (shouldCreateVersion) {
    const createdVersion = await request("/v1/appStoreVersions", {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "appStoreVersions",
          attributes: {
            platform: "IOS",
            versionString: targetVersion,
          },
          relationships: {
            app: {
              data: {
                type: "apps",
                id: app.id,
              },
            },
          },
        },
      }),
    });
    appStoreVersion = createdVersion.data;
    versions = await request(`/v1/apps/${app.id}/appStoreVersions?filter%5Bplatform%5D=IOS&limit=200`);
  }
}

if (!appStoreVersion) {
  const availableVersions = versions.data?.map((item) => ({
    id: item.id,
    versionString: item.attributes?.versionString,
    platform: item.attributes?.platform,
    appStoreState: item.attributes?.appStoreState,
  }));
  throw new Error(
    `App Store version ${targetVersion} was not found for ${bundleIdentifier}. Available versions: ${JSON.stringify(availableVersions)}`
  );
}

if (shouldUpdateMetadata) {
  const updateResults = [];

  const appInfos = await request(`/v1/apps/${app.id}/appInfos?limit=200`);
  const appInfo = appInfos.data?.[0];
  if (appInfo) {
    const appInfoLocalizations = await request(`/v1/appInfos/${appInfo.id}/appInfoLocalizations?limit=200`);
    const arabicAppInfo = appInfoLocalizations.data?.find(includesArabic);
    if (arabicAppInfo) {
      const currentName = arabicAppInfo.attributes?.name;
      if (currentName !== appStoreName) {
        try {
          await patchResource("appInfoLocalizations", arabicAppInfo.id, { name: appStoreName });
          updateResults.push({ field: "appInfo.name", previous: currentName, current: appStoreName, updated: true });
        } catch (error) {
          updateResults.push({ field: "appInfo.name", previous: currentName, target: appStoreName, updated: false, error: error.message });
        }
      } else {
        updateResults.push({ field: "appInfo.name", current: currentName, updated: false, reason: "already-current" });
      }
    } else {
      updateResults.push({ field: "appInfo.name", updated: false, error: "Arabic app info localization not found." });
    }
  } else {
    updateResults.push({ field: "appInfo.name", updated: false, error: "App info not found." });
  }

  const versionLocalizations = await request(`/v1/appStoreVersions/${appStoreVersion.id}/appStoreVersionLocalizations?limit=200`);
  const arabicVersion = versionLocalizations.data?.find(includesArabic);
  if (arabicVersion) {
    const currentWhatsNew = arabicVersion.attributes?.whatsNew || "";
    if (currentWhatsNew.trim() !== whatsNew.trim()) {
      try {
        await patchResource("appStoreVersionLocalizations", arabicVersion.id, { whatsNew });
        updateResults.push({ field: "version.whatsNew", updated: true });
      } catch (error) {
        updateResults.push({ field: "version.whatsNew", updated: false, error: error.message });
      }
    } else {
      updateResults.push({ field: "version.whatsNew", updated: false, reason: "already-current" });
    }
  } else {
    updateResults.push({ field: "version.whatsNew", updated: false, error: "Arabic version localization not found." });
  }

  const refreshedVersions = await request(
    `/v1/apps/${app.id}/appStoreVersions?filter%5Bplatform%5D=IOS&limit=200`
  );
  const refreshedVersion = refreshedVersions.data?.find(
    (item) => item.attributes?.versionString === targetVersion
  );

  console.log(
    JSON.stringify(
      {
        appId: app.id,
        bundleIdentifier,
        appStoreVersionId: appStoreVersion.id,
        version: targetVersion,
        appStoreState: refreshedVersion?.attributes?.appStoreState || appStoreVersion.attributes?.appStoreState,
        updateResults,
      },
      null,
      2
    )
  );
  process.exit(0);
}

const builds = await request(
  `/v1/builds?filter%5Bapp%5D=${app.id}&limit=200&sort=-uploadedDate`
);
const build = builds.data?.find(
  (item) => item.attributes?.buildNumber === targetBuildNumber || item.attributes?.version === targetBuildNumber
);
if (!build) {
  const availableBuilds = builds.data?.map((item) => ({
    id: item.id,
    version: item.attributes?.version,
    buildNumber: item.attributes?.buildNumber,
    processingState: item.attributes?.processingState,
  }));
  throw new Error(
    `Build ${targetVersion} (${targetBuildNumber}) was not found or is still processing. Available builds: ${JSON.stringify(availableBuilds)}`
  );
}

const buildState = build.attributes?.processingState;
if (buildState && buildState !== "VALID") {
  throw new Error(`Build ${targetBuildNumber} is not ready. Current processingState: ${buildState}`);
}

const buildRelationship = await request(`/v1/appStoreVersions/${appStoreVersion.id}/relationships/build`);
const currentBuildId = buildRelationship.data?.id;

if (currentBuildId !== build.id) {
  await request(`/v1/appStoreVersions/${appStoreVersion.id}/relationships/build`, {
    method: "PATCH",
    body: JSON.stringify({
      data: {
        type: "builds",
        id: build.id,
      },
    }),
  });
}

let submission = null;
if (shouldSubmit) {
  submission = await request("/v1/appStoreVersionSubmissions", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "appStoreVersionSubmissions",
        relationships: {
          appStoreVersion: {
            data: {
              type: "appStoreVersions",
              id: appStoreVersion.id,
            },
          },
        },
      },
    }),
  });
}

console.log(
  JSON.stringify(
    {
      appId: app.id,
      bundleIdentifier,
      appStoreVersionId: appStoreVersion.id,
      version: targetVersion,
      appStoreState: appStoreVersion.attributes?.appStoreState,
      buildId: build.id,
      buildNumber: targetBuildNumber,
      buildProcessingState: buildState,
      buildWasAlreadySelected: currentBuildId === build.id,
      submitted: Boolean(submission),
      submissionId: submission?.data?.id,
    },
    null,
    2
  )
);
