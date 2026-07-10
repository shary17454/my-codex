import { createSign } from "node:crypto";
import { readFile } from "node:fs/promises";

const issuerId = process.env.ASC_ISSUER_ID;
const keyId = process.env.ASC_KEY_ID;
const keyPath = process.env.ASC_KEY_PATH;
const bundleIdentifier = process.env.ASC_BUNDLE_ID;

if (!issuerId || !keyId || !keyPath || !bundleIdentifier) {
  throw new Error("Missing ASC_ISSUER_ID, ASC_KEY_ID, ASC_KEY_PATH, or ASC_BUNDLE_ID.");
}

const privateKey = await readFile(keyPath, "utf8");

function base64url(input) {
  return Buffer.from(input).toString("base64").replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
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
  const json = text ? JSON.parse(text) : {};
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${JSON.stringify(json)}`);
  }
  return json;
}

const bundleResult = await request(
  `/v1/bundleIds?filter%5Bidentifier%5D=${encodeURIComponent(bundleIdentifier)}`
);
const bundle = bundleResult.data?.[0];
if (!bundle) throw new Error(`Bundle ID not found: ${bundleIdentifier}`);

const capabilities = await request(`/v1/bundleIds/${bundle.id}/bundleIdCapabilities`);
const existing = capabilities.data?.find(
  (item) => item.attributes?.capabilityType === "APPLE_ID_AUTH"
);

if (!existing) {
  await request("/v1/bundleIdCapabilities", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "bundleIdCapabilities",
        attributes: {
          capabilityType: "APPLE_ID_AUTH",
        },
        relationships: {
          bundleId: {
            data: { type: "bundleIds", id: bundle.id },
          },
        },
      },
    }),
  });
}

const updated = await request(`/v1/bundleIds/${bundle.id}/bundleIdCapabilities`);
console.log(
  JSON.stringify(
    {
      bundleId: bundle.id,
      identifier: bundle.attributes.identifier,
      signInWithApple: updated.data?.some(
        (item) => item.attributes?.capabilityType === "APPLE_ID_AUTH"
      ),
      capabilities: updated.data?.map((item) => item.attributes?.capabilityType),
    },
    null,
    2
  )
);
