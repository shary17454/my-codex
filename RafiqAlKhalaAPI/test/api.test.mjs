import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from '../src/server.mjs';

function listen(server) {
  return new Promise(resolve => {
    server.listen(0, '127.0.0.1', () => {
      const address = server.address();
      resolve(`http://${address.address}:${address.port}`);
    });
  });
}

test('health endpoint returns service status', async () => {
  const server = createServer();
  const baseUrl = await listen(server);
  try {
    const response = await fetch(`${baseUrl}/health`);
    const body = await response.json();
    assert.equal(response.status, 200);
    assert.equal(body.ok, true);
    assert.equal(body.service, 'Rafiq Al Khala API');
  } finally {
    server.close();
  }
});

test('trip planner creates a rule-based desert trip plan', async () => {
  const server = createServer();
  const baseUrl = await listen(server);
  try {
    const response = await fetch(`${baseUrl}/v1/trips/plans`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        peopleCount: 4,
        durationHours: 10,
        vehicleType: 'دفع رباعي',
        preferences: { tags: ['تطعيس'] },
        temperature: 44,
        windSpeed: 50
      })
    });
    const body = await response.json();
    assert.equal(response.status, 201);
    assert.ok(body.plan.id);
    assert.equal(body.plan.estimates.waterLiters, 20);
    assert.ok(body.plan.warnings.some(alert => alert.type === 'heat'));
    assert.ok(body.plan.warnings.some(alert => alert.type === 'wind'));
  } finally {
    server.close();
  }
});

test('trip planner rejects invalid numeric fields', async () => {
  const server = createServer();
  const baseUrl = await listen(server);
  try {
    const response = await fetch(`${baseUrl}/v1/trips/plans`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        peopleCount: 'four',
        durationHours: 10
      })
    });
    const body = await response.json();
    assert.equal(response.status, 400);
    assert.equal(body.error, 'peopleCount must be a number');
  } finally {
    server.close();
  }
});

test('new places are queued for review', async () => {
  const server = createServer();
  const baseUrl = await listen(server);
  try {
    const response = await fetch(`${baseUrl}/v1/places`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        name: 'مخيم تجريبي',
        region: 'حائل',
        coordinate: { latitude: 27.5, longitude: 41.7 },
        terrain: ['جبال'],
        tags: ['تخييم']
      })
    });
    const body = await response.json();
    assert.equal(response.status, 201);
    assert.equal(body.place.status, 'pending_review');
    assert.equal(body.place.name, 'مخيم تجريبي');
  } finally {
    server.close();
  }
});

test('openapi document is exposed', async () => {
  const server = createServer();
  const baseUrl = await listen(server);
  try {
    const response = await fetch(`${baseUrl}/openapi.json`);
    const body = await response.json();
    assert.equal(response.status, 200);
    assert.equal(body.openapi, '3.1.0');
    assert.equal(body.info.title, 'Rafiq Al Khala API');
  } finally {
    server.close();
  }
});
