import http from 'node:http';
import { randomUUID } from 'node:crypto';
import { URL } from 'node:url';

const port = Number(process.env.PORT || 8787);
const host = process.env.HOST || '0.0.0.0';
const weatherBaseUrl = process.env.OPEN_METEO_BASE_URL || 'https://api.open-meteo.com/v1/forecast';
const apiToken = process.env.RAFIQ_API_TOKEN || '';

const store = {
  places: [
    {
      id: 'riyadh-dunes-001',
      name: 'كثبان قريبة من الرياض',
      region: 'الرياض',
      coordinate: { latitude: 24.5906, longitude: 46.5681 },
      difficulty: 'متوسط',
      terrain: ['رمال', 'كثبان'],
      familyFriendly: true,
      requires4x4: true,
      rating: 4.6,
      tags: ['تطعيس', 'تصوير', 'غروب'],
      status: 'approved'
    },
    {
      id: 'hidden-valley-001',
      name: 'وادي هادئ',
      region: 'القصيم',
      coordinate: { latitude: 26.0201, longitude: 43.7713 },
      difficulty: 'سهل',
      terrain: ['وادي', 'حصى'],
      familyFriendly: true,
      requires4x4: false,
      rating: 4.3,
      tags: ['عائلات', 'كشتة', 'ربيع'],
      status: 'approved'
    }
  ],
  trips: [],
  sosQueue: [],
  roadReports: []
};

const wildlife = [
  {
    id: 'arabian-scorpion',
    arabicName: 'العقرب',
    scientificName: 'Scorpiones',
    dangerLevel: 'مرتفع',
    venomous: true,
    habitat: 'المناطق الرملية والصخرية وحول المخيمات ليلاً',
    activeSeason: 'الربيع والصيف',
    activityTime: 'ليلي',
    advice: 'استخدم كشافاً ليلاً، لا ترفع الصخور بيدك، وافحص الحذاء قبل ارتدائه.',
    firstAid: ['ثبّت الطرف المصاب', 'لا تفتح موضع اللدغة', 'اتصل بالإسعاف 997 عند ظهور أعراض قوية']
  },
  {
    id: 'desert-snake',
    arabicName: 'الثعابين الصحراوية',
    scientificName: 'Serpentes',
    dangerLevel: 'مرتفع',
    venomous: true,
    habitat: 'الكثبان، الأودية، الشقوق الصخرية، والمزارع الطرفية',
    activeSeason: 'الصيف وبعد الغروب',
    activityTime: 'ليلي غالباً',
    advice: 'ابتعد بهدوء ولا تحاول الإمساك بها أو قتلها. ارتد أحذية مناسبة عند المشي.',
    firstAid: ['قلل الحركة', 'انزع الخواتم أو الأشياء الضاغطة', 'اطلب الإسعاف فوراً']
  },
  {
    id: 'arabian-wolf',
    arabicName: 'الذئب العربي',
    scientificName: 'Canis lupus arabs',
    dangerLevel: 'متوسط',
    venomous: false,
    habitat: 'الجبال والحرات والأودية البعيدة',
    activeSeason: 'طوال العام',
    activityTime: 'ليلي',
    advice: 'لا تطعمه ولا تترك بقايا الطعام مكشوفة، وحافظ على مسافة آمنة.',
    firstAid: ['في حال العض اغسل الجرح جيداً', 'غطه بضماد نظيف', 'راجع مركزاً طبياً']
  }
];

const offlineRegions = [
  { id: 'riyadh', name: 'الرياض', sizeMb: 420, layers: ['satellite', 'terrain', 'roads', 'services'] },
  { id: 'qassim', name: 'القصيم', sizeMb: 310, layers: ['satellite', 'terrain', 'roads'] },
  { id: 'hail', name: 'حائل', sizeMb: 360, layers: ['satellite', 'terrain', 'wadis'] },
  { id: 'empty-quarter', name: 'الربع الخالي', sizeMb: 780, layers: ['satellite', 'terrain', 'dunes'] }
];

function json(res, status, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type,authorization',
    'cache-control': 'no-store'
  });
  res.end(body);
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', chunk => {
      raw += chunk;
      if (raw.length > 1_000_000) {
        reject(new Error('Request body is too large'));
        req.destroy();
      }
    });
    req.on('end', () => {
      if (!raw.trim()) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch {
        reject(new Error('Invalid JSON body'));
      }
    });
  });
}

function numberParam(url, name, fallback = undefined) {
  const value = url.searchParams.get(name);
  if (value == null || value === '') return fallback;
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) throw new Error(`${name} must be a number`);
  return parsed;
}

function requireCoordinate(input) {
  const latitude = Number(input.latitude ?? input.lat);
  const longitude = Number(input.longitude ?? input.lon ?? input.lng);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new Error('latitude and longitude are required');
  }
  return { latitude, longitude };
}

function assertAuthorized(req) {
  if (!apiToken) return;
  const authorization = req.headers.authorization || '';
  const expected = `Bearer ${apiToken}`;
  if (authorization !== expected) {
    const error = new Error('Unauthorized');
    error.statusCode = 401;
    throw error;
  }
}

function openAPIDocument() {
  return {
    openapi: '3.1.0',
    info: {
      title: 'Kharayem API',
      version: '0.1.0',
      description: 'Backend API for desert trip planning, safety, SOS, places, wildlife, and offline map regions.'
    },
    servers: [
      { url: `http://${host}:${port}`, description: 'Local development' }
    ],
    paths: {
      '/health': { get: { summary: 'Service health check' } },
      '/v1/weather': { get: { summary: 'Weather by coordinate' } },
      '/v1/places': {
        get: { summary: 'List approved places' },
        post: { summary: 'Submit a place for review' }
      },
      '/v1/trips/plans': { post: { summary: 'Create a smart trip plan' } },
      '/v1/trips/records': { post: { summary: 'Store a trip recorder summary' } },
      '/v1/safety/alerts': { get: { summary: 'Generate safety alerts' } },
      '/v1/sos': { post: { summary: 'Queue an SOS request' } },
      '/v1/nature/wildlife': { get: { summary: 'Wildlife safety guide' } },
      '/v1/offline-map-regions': { get: { summary: 'Offline map region catalog' } }
    },
    security: apiToken ? [{ bearerAuth: [] }] : [],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer'
        }
      }
    }
  };
}

function buildSafetyAlerts({ temperature, windSpeed, airQualityIndex, hasRainRisk, networkGapKm }) {
  const alerts = [];
  if (temperature >= 42) {
    alerts.push({
      level: 'high',
      type: 'heat',
      title: 'ارتفاع شديد في الحرارة',
      message: 'ينصح بتأجيل المشي الطويل، زيادة كمية المياه، وتجنب التعرض المباشر للشمس.'
    });
  }
  if (windSpeed >= 45) {
    alerts.push({
      level: 'high',
      type: 'wind',
      title: 'رياح قوية',
      message: 'احتمال تدني الرؤية ووجود غبار. ثبّت أدوات المخيم وتجنب مناطق الكثبان المكشوفة.'
    });
  }
  if (airQualityIndex >= 150) {
    alerts.push({
      level: 'medium',
      type: 'air-quality',
      title: 'جودة هواء منخفضة',
      message: 'يفضل تقليل النشاط الخارجي لمن لديهم حساسية أو مشاكل تنفسية.'
    });
  }
  if (hasRainRisk) {
    alerts.push({
      level: 'high',
      type: 'flood',
      title: 'احتمال جريان أودية',
      message: 'تجنب بطون الأودية ومجاري السيول حتى لو لم تكن الأمطار في موقعك مباشرة.'
    });
  }
  if (networkGapKm >= 40) {
    alerts.push({
      level: 'medium',
      type: 'network',
      title: 'منطقة بعيدة عن التغطية',
      message: 'شارك خطتك قبل الانطلاق واحفظ الخرائط والمسار بلا اتصال.'
    });
  }
  return alerts;
}

function planTrip(input) {
  const start = input.start || {};
  const durationHours = Number(input.durationHours || 8);
  const peopleCount = Number(input.peopleCount || 1);
  const vehicleType = input.vehicleType || 'دفع رباعي';
  const budgetSar = Number(input.budgetSar || 0);
  const target = pickPlace(input.preferences || {}, start);
  const waterLiters = Math.ceil(peopleCount * Math.max(1, durationHours / 8) * 4);
  const reserveWaterLiters = Math.ceil(waterLiters * 0.35);
  const estimatedFuelLiters = Math.ceil(Math.max(60, durationHours * 8));

  return {
    id: randomUUID(),
    title: `رحلة إلى ${target.name}`,
    target,
    summary: `خطة مبدئية تناسب ${peopleCount} أشخاص وسيارة ${vehicleType}.`,
    recommendedDeparture: 'قبل الشروق بساعة أو بعد العصر حسب الطقس',
    route: {
      distanceKm: 127,
      estimatedDurationMinutes: 115,
      stops: [
        { type: 'fuel', name: 'تعبئة وقود قبل الخروج من المدينة' },
        { type: 'rest', name: 'نقطة توقف وفحص الإطارات' },
        { type: 'camp', name: 'نقطة جلوس آمنة بعيدة عن مجرى السيل' }
      ]
    },
    checklist: [
      'ماء كافٍ',
      'عدة إسعافات أولية',
      'كشاف',
      'كمبروسر',
      'حبل سحب',
      'إطار احتياطي',
      'خرائط بلا اتصال'
    ],
    estimates: {
      waterLiters,
      reserveWaterLiters,
      estimatedFuelLiters,
      budgetSar
    },
    warnings: buildSafetyAlerts({
      temperature: Number(input.temperature || 38),
      windSpeed: Number(input.windSpeed || 22),
      airQualityIndex: Number(input.airQualityIndex || 80),
      hasRainRisk: Boolean(input.hasRainRisk),
      networkGapKm: Number(input.networkGapKm || 0)
    })
  };
}

function pickPlace(preferences) {
  const wantedTags = new Set(Object.values(preferences).flat().filter(Boolean).map(String));
  return store.places
    .filter(place => place.status === 'approved')
    .sort((a, b) => {
      const aScore = a.tags.filter(tag => wantedTags.has(tag)).length + a.rating;
      const bScore = b.tags.filter(tag => wantedTags.has(tag)).length + b.rating;
      return bScore - aScore;
    })[0];
}

async function weather(url) {
  const latitude = numberParam(url, 'lat');
  const longitude = numberParam(url, 'lon');
  if (latitude == null || longitude == null) throw new Error('lat and lon are required');
  const proxyUrl = new URL(weatherBaseUrl);
  proxyUrl.searchParams.set('latitude', String(latitude));
  proxyUrl.searchParams.set('longitude', String(longitude));
  proxyUrl.searchParams.set('current', 'temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m');
  proxyUrl.searchParams.set('hourly', 'temperature_2m,precipitation_probability,wind_speed_10m');
  proxyUrl.searchParams.set('forecast_days', '2');
  const response = await fetch(proxyUrl);
  if (!response.ok) throw new Error(`weather provider failed: ${response.status}`);
  const payload = await response.json();
  return {
    provider: 'open-meteo',
    coordinate: { latitude, longitude },
    current: payload.current,
    hourly: payload.hourly
  };
}

async function router(req, res) {
  if (req.method === 'OPTIONS') return json(res, 204, {});
  const url = new URL(req.url, `http://${req.headers.host || `${host}:${port}`}`);

  try {
    if (req.method === 'GET' && url.pathname === '/health') {
      return json(res, 200, { ok: true, service: 'Kharayem API', version: '0.1.0' });
    }

    if (req.method === 'GET' && url.pathname === '/openapi.json') {
      return json(res, 200, openAPIDocument());
    }

    if (req.method === 'GET' && url.pathname === '/v1/weather') {
      return json(res, 200, await weather(url));
    }

    if (req.method === 'GET' && url.pathname === '/v1/places') {
      const region = url.searchParams.get('region');
      const terrain = url.searchParams.get('terrain');
      const places = store.places.filter(place => {
        if (place.status !== 'approved') return false;
        if (region && place.region !== region) return false;
        if (terrain && !place.terrain.includes(terrain)) return false;
        return true;
      });
      return json(res, 200, { places });
    }

    if (req.method === 'POST' && url.pathname === '/v1/places') {
      assertAuthorized(req);
      const body = await parseBody(req);
      const coordinate = requireCoordinate(body.coordinate || body);
      const place = {
        id: randomUUID(),
        name: String(body.name || 'موقع جديد'),
        region: String(body.region || 'غير محدد'),
        coordinate,
        difficulty: String(body.difficulty || 'غير محدد'),
        terrain: Array.isArray(body.terrain) ? body.terrain : [],
        familyFriendly: Boolean(body.familyFriendly),
        requires4x4: Boolean(body.requires4x4),
        rating: 0,
        tags: Array.isArray(body.tags) ? body.tags : [],
        notes: String(body.notes || ''),
        status: 'pending_review',
        createdAt: new Date().toISOString()
      };
      store.places.push(place);
      return json(res, 201, { place });
    }

    if (req.method === 'POST' && url.pathname === '/v1/trips/plans') {
      assertAuthorized(req);
      const body = await parseBody(req);
      const plan = planTrip(body);
      store.trips.push({ ...plan, status: 'planned', createdAt: new Date().toISOString() });
      return json(res, 201, { plan });
    }

    if (req.method === 'POST' && url.pathname === '/v1/trips/records') {
      assertAuthorized(req);
      const body = await parseBody(req);
      const record = {
        id: randomUUID(),
        title: String(body.title || 'رحلة مسجلة'),
        distanceKm: Number(body.distanceKm || 0),
        durationMinutes: Number(body.durationMinutes || 0),
        maxSpeedKph: Number(body.maxSpeedKph || 0),
        averageSpeedKph: Number(body.averageSpeedKph || 0),
        elevationGainM: Number(body.elevationGainM || 0),
        gpxUrl: body.gpxUrl || null,
        createdAt: new Date().toISOString()
      };
      store.trips.push(record);
      return json(res, 201, { record });
    }

    if (req.method === 'GET' && url.pathname === '/v1/safety/alerts') {
      const alerts = buildSafetyAlerts({
        temperature: numberParam(url, 'temperature', 0),
        windSpeed: numberParam(url, 'windSpeed', 0),
        airQualityIndex: numberParam(url, 'airQualityIndex', 0),
        hasRainRisk: url.searchParams.get('rainRisk') === 'true',
        networkGapKm: numberParam(url, 'networkGapKm', 0)
      });
      return json(res, 200, { alerts });
    }

    if (req.method === 'POST' && url.pathname === '/v1/sos') {
      assertAuthorized(req);
      const body = await parseBody(req);
      const coordinate = requireCoordinate(body.coordinate || body);
      const sos = {
        id: randomUUID(),
        coordinate,
        batteryPercent: Number(body.batteryPercent || 0),
        heading: Number(body.heading || 0),
        message: String(body.message || 'طلب استغاثة من خرايم'),
        contactIds: Array.isArray(body.contactIds) ? body.contactIds : [],
        status: 'queued',
        createdAt: new Date().toISOString()
      };
      store.sosQueue.push(sos);
      return json(res, 202, { sos });
    }

    if (req.method === 'GET' && url.pathname === '/v1/nature/wildlife') {
      return json(res, 200, { species: wildlife });
    }

    if (req.method === 'GET' && url.pathname === '/v1/offline-map-regions') {
      return json(res, 200, { regions: offlineRegions });
    }

    return json(res, 404, { error: 'Not Found', path: url.pathname });
  } catch (error) {
    return json(res, error.statusCode || 400, { error: error.message });
  }
}

export function createServer() {
  return http.createServer(router);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  createServer().listen(port, host, () => {
    console.log(`Kharayem API running on http://${host}:${port}`);
  });
}
