let catalog = { parts: [], sources: [] };
let parts = [];
let activeFilter = "all";
let activeModel = "Y60";
let selectedPartId = null;
let currentLang = localStorage.getItem("batalLang") || "ar";
let currentCurrency = localStorage.getItem("batalCurrency") || "SAR";
let visibleLimit = 60;
const wishlist = new Set();

const fallbackParts = [
  {
    part_number: "21082-4W000",
    name_ar: "كلتش المروحة",
    name_en: "Fan Clutch",
    model: "Y60",
    years: ["1992", "1993", "1994", "1995", "1996", "1997"],
    category: "cooling",
    category_ar: "تبريد",
    occurrence_count: 1,
    source_count: 1,
    rarity: "بيان احتياطي",
    evidence: [{ source_id: "sample", year: "1992", page: 1, context: "Fan clutch cooling system sample record." }]
  }
];

const partsList = document.getElementById("partsList");
const detailPanel = document.getElementById("detailPanel");
const searchInput = document.getElementById("searchInput");
const resultCount = document.getElementById("resultCount");
const partsPageTitle = document.getElementById("partsPageTitle");
const wishlistCount = document.getElementById("wishlistCount");
const languageToggle = document.getElementById("languageToggle");
const menuToggle = document.getElementById("menuToggle");
const menuPanel = document.getElementById("menuPanel");
const currencyOptions = document.querySelectorAll("[data-currency]");

const translations = {
  ar: {
    brandMark: "بد",
    appName: "بطل الدروب",
    brandSubtitle: "كتالوج قطع الباترول Y60",
    navCatalog: "الكتالوج",
    navDiagrams: "الرسومات",
    navPrices: "الأسعار",
    navMaintenance: "الصيانة",
    navCommunity: "المجتمع",
    dataStatus: "حالة البيانات",
    dataTitle: "قاعدة Y60 مدمجة",
    dataText: "بيانات مدققة من كتالوجات PDF، محفوظة في قاعدة SQLite وجاهزة للبحث والاستعراض.",
    eyebrow: "بطل الدروب لقطع نيسان باترول",
    headline: "اعرف رقم القطعة، توافقها، مصادرها، وحالة تدقيقها من مكان واحد",
    heroBadgeData: "قاعدة مدققة",
    heroBadgeOffline: "جاهز للمتصفح و iOS",
    heroBadgeLang: "عربي / English",
    wishlist: "قائمة الرغبات",
    currencySar: "ريال",
    currencyUsd: "دولار",
    menuHome: "الرئيسية",
    menuParts: "القطع",
    menuFaults: "الأعطال الشائعة",
    menuCatalogs: "الكتالوجات",
    menuPrices: "الأسعار",
    menuWishlist: "قائمة الرغبات",
    menuContact: "تواصل معنا",
    menuMore: "المزيد",
    generationsTitle: "أجيال الباترول",
    generationsSubtitle: "اختر الجيل المناسب لقاعدة القطع",
    generationY60: "الجيل الكلاسيكي المربع، أساس قاعدة البيانات الحالية.",
    generationY61: "جيل السفاري المعروف بقوة الاعتماد وكثرة الاستخدام في الخليج.",
    generationY62: "جيل فاخر كبير الحجم مع أنظمة حديثة وقاعدة قطع مختلفة.",
    generationY63: "الجيل الجديد بواجهة عمودية وشبك كبير وإضاءة C مميزة.",
    smartSearch: "بحث ذكي",
    searchPlaceholder: "رقم القطعة، الاسم، القسم، أو VIN",
    generationFilterTitle: "اختر جيل الباترول",
    generationFilterHint: "الجيل يحدد قاعدة البيانات المناسبة",
    categoryFilterTitle: "أقسام القطع",
    categoryFilterHint: "اختر القسم للدخول إلى صفحة قطعه",
    filterAll: "الكل",
    catEngine: "محرك",
    catCooling: "تبريد",
    catElectrical: "كهرباء",
    catBody: "هيكل",
    catBrake: "فرامل",
    catSuspension: "تعليق",
    catInterior: "داخلية",
    catFuel: "وقود",
    catGeneral: "عام",
    statParts: "قطع مفهرسة",
    statSources: "مصادر PDF",
    statReview: "تحتاج مراجعة",
    statRecords: "سجلات مستخرجة",
    resultsTitle: "نتائج القطع",
    partsPageAll: "كل قطع",
    partsPageCategory: "قطع",
    modelComingSoon: "قاعدة هذا الجيل قيد التجهيز. اختر Y60 لعرض القطع المفهرسة الآن.",
    resultSingular: "نتيجة",
    resultPlural: "نتيجة",
    oem: "OEM",
    records: "سجل",
    confidence: "ثقة",
    sources: "مصادر",
    noResults: "لا توجد نتائج مطابقة للبحث الحالي.",
    notSpecified: "غير محدد",
    notSpecifiedFromText: "غير محدد من النص",
    shownFirst: "تم عرض أول",
    refineSearch: "نتيجة. استخدم البحث لتضييق النتائج.",
    showMore: "عرض المزيد",
    visibleCount: "المعروض الآن",
    originalName: "الاسم الأصلي",
    epcSource: "مصدر EPC",
    dbInfo: "معلومات قاعدة البيانات",
    appearanceYears: "سنوات الظهور",
    engines: "المحركات",
    applicationDates: "تواريخ التطبيق",
    sourceCount: "عدد المصادر",
    occurrenceCount: "عدد مرات الظهور",
    marketPrices: "الأسعار التقريبية",
    localMarket: "السوق السعودي",
    gulfMarket: "متاجر الخليج",
    globalMarket: "المتاجر العالمية",
    shippingIncluded: "يشمل تقدير الشحن والضريبة",
    category: "التصنيف المبدئي",
    auditStatus: "حالة التدقيق",
    confidenceScore: "درجة الثقة",
    catalogEvidence: "أدلة من الكتالوجات",
    year: "سنة",
    page: "صفحة",
    enrichmentNext: "خطوة الإثراء التالية",
    enrichment1: "تدقيق اسم القطعة عربي وإنجليزي من الرسم الأصلي.",
    enrichment2: "ربط القطعة بالقسم والرسم الانفجاري والصورة الحقيقية.",
    enrichment3: "إضافة الأسعار والتوفر من المتاجر بعد اعتماد رقم القطعة.",
    saveWishlist: "حفظ في قائمة الرغبات",
    saved: "تم الحفظ",
    priceAlert: "تنبيه عند توفر بيانات سعر",
    faultsTitle: "الأعطال الشائعة",
    faultWear: "ضعف أو اهتزاز مرتبط بالاستهلاك الطبيعي للقطعة.",
    faultHeat: "ارتفاع حرارة أو ضغط زائد عند إهمال الصيانة الدورية.",
    faultNoise: "صوت غير طبيعي أو تهريب يظهر قبل التعطل الكامل.",
    catalogsTitle: "الكتالوجات",
    catalogsText: "قاعدة Y60 مدمجة من مصادر السنوات 1988 إلى 1997 مع إزالة المكرر.",
    contactTitle: "تواصل معنا",
    contactText: "لإضافة متجر، تصحيح رقم قطعة، أو إرسال صورة قطعة: support@batalaldroob.app",
    fallbackPart: "قطعة Y60 موثقة",
    fallbackRarity: "بيان احتياطي",
    toggleLabel: "English",
    verifiedStrong: "موثق بقوة",
    verified: "موثق",
    needsAudit: "يحتاج تدقيق",
    auditHigh: "مدقق آليًا بدرجة عالية",
    auditOk: "مدقق آليًا",
    auditReviewName: "يحتاج مراجعة اسم/تطبيق",
    auditReviewManual: "يحتاج مراجعة يدوية"
  },
  en: {
    brandMark: "BD",
    appName: "Batal Al-Droob",
    brandSubtitle: "Patrol Y60 Parts Catalog",
    navCatalog: "Catalog",
    navDiagrams: "Diagrams",
    navPrices: "Prices",
    navMaintenance: "Maintenance",
    navCommunity: "Community",
    dataStatus: "Data Status",
    dataTitle: "Integrated Y60 Database",
    dataText: "Audited PDF catalog data stored in SQLite and ready for search and browsing.",
    eyebrow: "Batal Al-Droob for Nissan Patrol Parts",
    headline: "Find the part number, fitment, sources, and audit status in one place",
    heroBadgeData: "Audited database",
    heroBadgeOffline: "Browser and iOS ready",
    heroBadgeLang: "Arabic / English",
    wishlist: "Wishlist",
    currencySar: "SAR",
    currencyUsd: "USD",
    menuHome: "Home",
    menuParts: "Parts",
    menuFaults: "Common Faults",
    menuCatalogs: "Catalogs",
    menuPrices: "Prices",
    menuWishlist: "Wishlist",
    menuContact: "Contact Us",
    menuMore: "More",
    generationsTitle: "Patrol Generations",
    generationsSubtitle: "Choose the generation that matches the parts database",
    generationY60: "The classic boxy generation and the foundation of the current database.",
    generationY61: "The Safari generation known for durability and heavy Gulf use.",
    generationY62: "A large luxury generation with modern systems and a different parts base.",
    generationY63: "The new generation with an upright front, large grille, and C-shaped lighting.",
    smartSearch: "Smart Search",
    searchPlaceholder: "Part number, name, category, or VIN",
    generationFilterTitle: "Choose Patrol Generation",
    generationFilterHint: "The generation selects the matching database",
    categoryFilterTitle: "Part Sections",
    categoryFilterHint: "Choose a section to open its parts page",
    filterAll: "All",
    catEngine: "Engine",
    catCooling: "Cooling",
    catElectrical: "Electrical",
    catBody: "Body",
    catBrake: "Brake",
    catSuspension: "Suspension",
    catInterior: "Interior",
    catFuel: "Fuel",
    catGeneral: "General",
    statParts: "Indexed Parts",
    statSources: "PDF Sources",
    statReview: "Need Review",
    statRecords: "Extracted Records",
    resultsTitle: "Part Results",
    partsPageAll: "All parts for",
    partsPageCategory: "Parts for",
    modelComingSoon: "This generation database is being prepared. Choose Y60 to view indexed parts now.",
    resultSingular: "result",
    resultPlural: "results",
    oem: "OEM",
    records: "records",
    confidence: "confidence",
    sources: "sources",
    noResults: "No results match the current search.",
    notSpecified: "Not specified",
    notSpecifiedFromText: "Not specified in text",
    shownFirst: "Showing first",
    refineSearch: "results. Use search to narrow the list.",
    showMore: "Show More",
    visibleCount: "Visible now",
    originalName: "Original Name",
    epcSource: "EPC Source",
    dbInfo: "Database Information",
    appearanceYears: "Appearance Years",
    engines: "Engines",
    applicationDates: "Application Dates",
    sourceCount: "Source Count",
    occurrenceCount: "Occurrences",
    marketPrices: "Estimated Prices",
    localMarket: "Saudi Market",
    gulfMarket: "Gulf Stores",
    globalMarket: "Global Stores",
    shippingIncluded: "Includes estimated shipping and VAT",
    category: "Initial Category",
    auditStatus: "Audit Status",
    confidenceScore: "Confidence Score",
    catalogEvidence: "Catalog Evidence",
    year: "Year",
    page: "Page",
    enrichmentNext: "Next Enrichment Step",
    enrichment1: "Verify Arabic and English names from the original diagram.",
    enrichment2: "Link the part to its section, exploded diagram, and real image.",
    enrichment3: "Add prices and availability after the part number is approved.",
    saveWishlist: "Save to Wishlist",
    saved: "Saved",
    priceAlert: "Alert when price data is available",
    faultsTitle: "Common Faults",
    faultWear: "Weakness or vibration caused by natural part wear.",
    faultHeat: "Overheating or excess pressure when routine maintenance is ignored.",
    faultNoise: "Unusual noise or leakage before full failure.",
    catalogsTitle: "Catalogs",
    catalogsText: "Integrated Y60 database from 1988 to 1997 sources with duplicates removed.",
    contactTitle: "Contact Us",
    contactText: "To add a seller, correct a part number, or send a part image: support@batalaldroob.app",
    fallbackPart: "Verified Y60 Part",
    fallbackRarity: "Fallback data",
    toggleLabel: "العربية",
    verifiedStrong: "Strongly verified",
    verified: "Verified",
    needsAudit: "Needs audit",
    auditHigh: "High-confidence automated audit",
    auditOk: "Automated audit",
    auditReviewName: "Needs name/fitment review",
    auditReviewManual: "Needs manual review"
  }
};

const categoryKeys = {
  engine: "catEngine",
  cooling: "catCooling",
  electrical: "catElectrical",
  body: "catBody",
  brake: "catBrake",
  suspension: "catSuspension",
  interior: "catInterior",
  fuel: "catFuel",
  general: "catGeneral"
};

const statusMap = {
  "مدقق آليًا بدرجة عالية": "auditHigh",
  "مدقق آليًا": "auditOk",
  "يحتاج مراجعة اسم/تطبيق": "auditReviewName",
  "يحتاج مراجعة يدوية": "auditReviewManual",
  "موثق بقوة": "verifiedStrong",
  "موثق": "verified",
  "يحتاج تدقيق": "needsAudit",
  "بيان احتياطي": "fallbackRarity"
};

const exactArabicPartNames = {
  "block assy-cylinder": "مجموعة بلوك السلندر",
  "block assy cylinder": "مجموعة بلوك السلندر",
  "plug-blind": "سدادة عمياء",
  "plug blind": "سدادة عمياء",
  "collar": "جلبة",
  "bolt": "مسمار",
  "nut": "صامولة",
  "screw": "برغي",
  "grommet-screw": "جلدة تثبيت البرغي",
  "bolt-rocker cover": "مسمار غطاء البلوف",
  "bolt-condenser fix": "مسمار تثبيت المكثف",
  "fan clutch": "كلتش المروحة"
};

const arabicNameTerms = [
  ["assy", "مجموعة"],
  ["assembly", "مجموعة"],
  ["cylinder", "سلندر"],
  ["block", "بلوك"],
  ["plug", "سدادة"],
  ["blind", "عمياء"],
  ["collar", "جلبة"],
  ["bolt", "مسمار"],
  ["nut", "صامولة"],
  ["screw", "برغي"],
  ["washer", "وردة"],
  ["grommet", "جلدة"],
  ["cover", "غطاء"],
  ["rocker", "بلوف"],
  ["condenser", "مكثف"],
  ["fix", "تثبيت"],
  ["bracket", "حامل"],
  ["hose", "لي"],
  ["pipe", "ماسورة"],
  ["seal", "صوفة"],
  ["oil", "زيت"],
  ["water", "ماء"],
  ["pump", "طرمبة"],
  ["valve", "بلف"],
  ["engine", "محرك"],
  ["shaft", "عمود"],
  ["gear", "ترس"],
  ["bearing", "رمان"],
  ["bush", "جلدة"],
  ["bushing", "جلدة"],
  ["spring", "ياي"],
  ["plate", "صفيحة"],
  ["rubber", "ربل"],
  ["mounting", "قاعدة"],
  ["mount", "قاعدة"],
  ["filter", "فلتر"],
  ["fuel", "وقود"],
  ["air", "هواء"],
  ["lamp", "لمبة"],
  ["switch", "مفتاح"],
  ["relay", "كتاوت"],
  ["sensor", "حساس"]
];

function t(key) {
  return translations[currentLang][key] || translations.ar[key] || key;
}

function localizedValue(value) {
  return statusMap[value] ? t(statusMap[value]) : value;
}

function formatMoney(amount) {
  const converted = currentCurrency === "USD" ? amount / 3.75 : amount;
  const locale = currentLang === "ar" ? "ar-SA" : "en-US";
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency: currentCurrency,
    maximumFractionDigits: currentCurrency === "USD" ? 2 : 0
  }).format(converted);
}

function priceEstimate(part) {
  const categoryBase = {
    engine: 920,
    cooling: 430,
    electrical: 360,
    body: 610,
    brake: 280,
    suspension: 520,
    interior: 240,
    fuel: 470,
    general: 180
  };
  const base = categoryBase[part.category] || categoryBase.general;
  const rarityLift = part.source_count <= 1 ? 1.55 : part.source_count <= 3 ? 1.25 : 1;
  const confidenceDiscount = (part.confidence || 80) < 70 ? 0.9 : 1;
  const market = Math.round(base * rarityLift * confidenceDiscount);
  return [
    { label: t("localMarket"), amount: market },
    { label: t("gulfMarket"), amount: Math.round(market * 1.12) },
    { label: t("globalMarket"), amount: Math.round(market * 1.28) }
  ];
}

function categoryLabel(part) {
  return t(categoryKeys[part.category] || "catGeneral");
}

function applyLanguage() {
  document.documentElement.lang = currentLang;
  document.documentElement.dir = currentLang === "ar" ? "rtl" : "ltr";
  document.title = t("appName");
  document.querySelector('meta[name="apple-mobile-web-app-title"]')?.setAttribute("content", t("appName"));
  document.querySelectorAll("[data-i18n]").forEach((node) => {
    node.textContent = t(node.dataset.i18n);
  });
  document.querySelectorAll("[data-i18n-placeholder]").forEach((node) => {
    node.setAttribute("placeholder", t(node.dataset.i18nPlaceholder));
  });
  if (languageToggle) {
    languageToggle.textContent = t("toggleLabel");
  }
  updateCurrencyButtons();
  updateStats();
  renderParts();
}

function updateCurrencyButtons() {
  currencyOptions.forEach((button) => {
    button.classList.toggle("active", button.dataset.currency === currentCurrency);
  });
}

function normalize(value) {
  return String(value || "").toLowerCase().trim();
}

function translatedPartName(name) {
  const source = normalize(name).replace(/[_/]+/g, "-").replace(/\s+/g, " ");
  if (!source) return "";
  if (exactArabicPartNames[source]) return exactArabicPartNames[source];

  const words = source.split(/[-\s]+/).filter(Boolean);
  const translated = words.map((word) => {
    const match = arabicNameTerms.find(([english]) => english === word);
    return match ? match[1] : word.toUpperCase();
  });
  return translated.join(" ");
}

function displayName(part) {
  if (currentLang === "ar") {
    return part.name_ar || translatedPartName(part.name_en) || t("fallbackPart");
  }
  return part.name_en || part.name_ar || t("fallbackPart");
}

function originalNameLine(part) {
  if (currentLang !== "ar" || !part.name_en) return "";
  if (displayName(part) === part.name_en) return "";
  return `<div class="original-name">${t("originalName")}: ${part.name_en}</div>`;
}

function enginesLabel(part) {
  return part.engines?.length ? part.engines.join(" / ") : t("notSpecifiedFromText");
}

function dateRangesLabel(part) {
  return part.date_ranges?.length ? part.date_ranges.join(" | ") : t("notSpecifiedFromText");
}

function yearsLabel(part) {
  return part.years?.length ? part.years.join(" / ") : t("notSpecified");
}

function evidenceText(part) {
  return part.evidence?.map((item) => item.context).join(" ") || "";
}

function matchesFilter(part) {
  if (part.model !== activeModel) return false;
  if (activeFilter === "all") return true;
  return part.category === activeFilter;
}

function matchesSearch(part, query) {
  if (!query) return true;
  const haystack = [
    part.part_number,
    part.name_ar,
    part.name_en,
    translatedPartName(part.name_en),
    part.category_ar,
    part.model,
    yearsLabel(part),
    evidenceText(part)
  ].join(" ");
  return normalize(haystack).includes(normalize(query));
}

function rarityClass(part) {
  if (part.source_count >= 7) return "available";
  if (part.source_count >= 3) return "limited";
  return "rare";
}

function typeClass(part) {
  const map = {
    engine: "oem",
    cooling: "manufacturer",
    electrical: "nos",
    body: "repro",
    brake: "aftermarket",
    suspension: "manufacturer",
    interior: "used",
    fuel: "oem"
  };
  return map[part.category] || "used";
}

function categorySymbol(category) {
  const symbols = {
    engine: "⚙",
    cooling: "❄",
    electrical: "↯",
    body: "▦",
    brake: "◎",
    suspension: "⌁",
    fuel: "◈",
    interior: "◫"
  };
  return symbols[category] || "⚙";
}

function renderParts() {
  const query = searchInput.value;
  const visibleParts = parts.filter((part) => matchesFilter(part) && matchesSearch(part, query));
  const renderedParts = visibleParts.slice(0, visibleLimit);
  const resultWord = visibleParts.length === 1 ? t("resultSingular") : t("resultPlural");
  resultCount.textContent = `${visibleParts.length.toLocaleString("en-US")} ${resultWord}`;
  if (partsPageTitle) {
    const titlePrefix = activeFilter === "all" ? t("partsPageAll") : `${t("partsPageCategory")} ${t(categoryKeys[activeFilter] || "filterAll")}`;
    partsPageTitle.textContent = currentLang === "ar" ? `${titlePrefix} ${activeModel}` : `${titlePrefix} ${activeModel}`;
  }

  if (!visibleParts.some((part) => part.part_number === selectedPartId)) {
    selectedPartId = visibleParts[0]?.part_number || null;
  }

  if (!visibleParts.length && activeModel !== "Y60" && !query) {
    partsList.innerHTML = `<div class="internal-empty">${t("modelComingSoon")}</div>`;
    renderDetails();
    return;
  }

  partsList.innerHTML = renderedParts.map((part) => `
    <button class="part-card ${part.part_number === selectedPartId ? "active" : ""}" type="button" data-id="${part.part_number}">
      <div class="part-visual" aria-hidden="true"><span>${categorySymbol(part.category)}</span></div>
      <div class="part-main">
        <h3>${displayName(part)}</h3>
        ${originalNameLine(part)}
        <div class="meta-line">${t("oem")} ${part.part_number} · ${part.model}</div>
        <div class="compatibility">${yearsLabel(part)} · ${enginesLabel(part)} · ${part.occurrence_count.toLocaleString("en-US")} ${t("records")}</div>
        <div class="badge-row">
          <span class="badge ${typeClass(part)}">${categoryLabel(part)}</span>
          <span class="badge ${rarityClass(part)}">${localizedValue(part.rarity)}</span>
          <span class="badge">${part.confidence || 0}% ${t("confidence")}</span>
        </div>
      </div>
    </button>
  `).join("");

  if (visibleParts.length > renderedParts.length) {
    partsList.insertAdjacentHTML("beforeend", `
      <button class="load-more" type="button" data-load-more>
        ${t("showMore")} · ${t("visibleCount")} ${renderedParts.length.toLocaleString("en-US")} / ${visibleParts.length.toLocaleString("en-US")}
      </button>
    `);
  }

  renderDetails();
}

function diagramSvg(part) {
  return `
    <svg viewBox="0 0 520 210" role="img" aria-label="رسم توضيحي للقطعة">
      <rect x="24" y="72" width="144" height="66" rx="10" fill="#dfe9e5" stroke="#1f7a57" stroke-width="3"/>
      <rect x="352" y="66" width="132" height="78" rx="10" fill="#e8edf7" stroke="#2d6cdf" stroke-width="3"/>
      <circle cx="260" cy="105" r="43" fill="#ffffff" stroke="#1f2a29" stroke-width="4"/>
      <circle cx="260" cy="105" r="14" fill="#1f7a57"/>
      <path d="M168 105h48M304 105h48" stroke="#1f2a29" stroke-width="4" stroke-dasharray="8 7"/>
      <path d="M260 62v-34" stroke="#b5531b" stroke-width="4"/>
      <text x="260" y="22" text-anchor="middle" font-size="14" fill="#1f2a29">${part.part_number}</text>
      <text x="96" y="109" text-anchor="middle" font-size="13" fill="#1f2a29">${t("epcSource")}</text>
      <text x="418" y="109" text-anchor="middle" font-size="13" fill="#1f2a29">${categoryLabel(part)}</text>
      <text x="260" y="175" text-anchor="middle" font-size="16" fill="#1f7a57">${displayName(part)}</text>
    </svg>
  `;
}

function renderDetails() {
  const part = parts.find((item) => item.part_number === selectedPartId);
  if (!part) {
    detailPanel.innerHTML = `<div class="detail-empty">${t("noResults")}</div>`;
    return;
  }

  detailPanel.innerHTML = `
    <div class="detail-title">
      <h2>${displayName(part)}</h2>
      <span class="meta-line">${t("oem")} ${part.part_number} · ${part.model}</span>
      <div class="badge-row">
        <span class="badge ${typeClass(part)}">${categoryLabel(part)}</span>
        <span class="badge ${rarityClass(part)}">${localizedValue(part.rarity)}</span>
      </div>
    </div>

    <div class="diagram">${diagramSvg(part)}</div>

    <div class="detail-section">
      <h3>${t("dbInfo")}</h3>
      <div class="info-grid">
        <div class="info-item"><span>${t("appearanceYears")}</span><strong>${yearsLabel(part)}</strong></div>
        <div class="info-item"><span>${t("engines")}</span><strong>${enginesLabel(part)}</strong></div>
        <div class="info-item"><span>${t("applicationDates")}</span><strong>${dateRangesLabel(part)}</strong></div>
        <div class="info-item"><span>${t("sourceCount")}</span><strong>${part.source_count}</strong></div>
        <div class="info-item"><span>${t("occurrenceCount")}</span><strong>${part.occurrence_count.toLocaleString("en-US")}</strong></div>
        <div class="info-item"><span>${t("category")}</span><strong>${categoryLabel(part)}</strong></div>
        <div class="info-item"><span>${t("auditStatus")}</span><strong>${localizedValue(part.audit_status) || t("notSpecified")}</strong></div>
        <div class="info-item"><span>${t("confidenceScore")}</span><strong>${part.confidence || 0}%</strong></div>
      </div>
    </div>

    <div class="detail-section" data-section="prices">
      <h3>${t("marketPrices")}</h3>
      <div class="price-list">
        ${priceEstimate(part).map((item) => `
          <div class="price-row">
            <div>
              <strong>${item.label}</strong>
              <span>${t("shippingIncluded")}</span>
            </div>
            <b>${formatMoney(item.amount)}</b>
          </div>
        `).join("")}
      </div>
    </div>

    <div class="detail-section">
      <h3>${t("catalogEvidence")}</h3>
      <div class="price-list">
        ${(part.evidence || []).map((item) => `
          <div class="price-row">
            <div>
              <strong>${item.source_id}</strong>
              <span>${t("year")} ${item.year} · ${t("page")} ${item.page}</span>
              <span>${item.context}</span>
            </div>
          </div>
        `).join("")}
      </div>
    </div>

    <div class="detail-section">
      <h3>${t("enrichmentNext")}</h3>
      <ul class="bullet-list">
        <li>${t("enrichment1")}</li>
        <li>${t("enrichment2")}</li>
        <li>${t("enrichment3")}</li>
      </ul>
    </div>

    <div class="detail-section" data-section="faults">
      <h3>${t("faultsTitle")}</h3>
      <ul class="bullet-list">
        <li>${t("faultWear")}</li>
        <li>${t("faultHeat")}</li>
        <li>${t("faultNoise")}</li>
      </ul>
    </div>

    <div class="detail-section" data-section="catalogs">
      <h3>${t("catalogsTitle")}</h3>
      <p class="detail-copy">${t("catalogsText")}</p>
    </div>

    <div class="detail-section" data-section="contact">
      <h3>${t("contactTitle")}</h3>
      <p class="detail-copy">${t("contactText")}</p>
    </div>

    <div class="detail-actions">
      <button class="secondary-action" type="button" data-wishlist="${part.part_number}">${t("saveWishlist")}</button>
      <button class="secondary-action" type="button">${t("priceAlert")}</button>
    </div>
  `;
}

function updateStats() {
  const cards = document.querySelectorAll(".stats-grid article strong");
  if (cards.length < 4) return;
  cards[0].textContent = catalog.part_count?.toLocaleString("en-US") || parts.length.toLocaleString("en-US");
  cards[1].textContent = catalog.source_count?.toLocaleString("en-US") || "0";
  cards[2].textContent = parts.filter((part) => (part.confidence || 0) < 70).length.toLocaleString("en-US");
  cards[3].textContent = parts.reduce((sum, part) => sum + part.occurrence_count, 0).toLocaleString("en-US");
}

async function loadCatalog() {
  try {
    let response = await fetch("/api/catalog");
    if (!response.ok) {
      response = await fetch("data/y60_app_catalog.json");
    }
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    catalog = await response.json();
    parts = catalog.parts;
  } catch (error) {
    catalog = { parts: fallbackParts, sources: [] };
    parts = fallbackParts;
    console.warn("Using fallback catalog", error);
  }
  selectedPartId = parts[0]?.part_number || null;
  updateStats();
  renderParts();
}

partsList.addEventListener("click", (event) => {
  const loadMore = event.target.closest("[data-load-more]");
  if (loadMore) {
    visibleLimit += 60;
    renderParts();
    return;
  }

  const card = event.target.closest(".part-card");
  if (!card) return;
  selectedPartId = card.dataset.id;
  renderParts();
});

detailPanel.addEventListener("click", (event) => {
  const button = event.target.closest("[data-wishlist]");
  if (!button) return;
  wishlist.add(button.dataset.wishlist);
  wishlistCount.textContent = wishlist.size;
  button.textContent = t("saved");
});

document.querySelectorAll(".model-chip").forEach((chip) => {
  chip.addEventListener("click", () => {
    document.querySelectorAll(".model-chip").forEach((item) => item.classList.remove("active"));
    chip.classList.add("active");
    activeModel = chip.dataset.model;
    visibleLimit = 60;
    renderParts();
  });
});

document.querySelectorAll(".category-card").forEach((card) => {
  card.addEventListener("click", () => {
    document.querySelectorAll(".category-card").forEach((item) => item.classList.remove("active"));
    card.classList.add("active");
    activeFilter = card.dataset.filter;
    visibleLimit = 60;
    renderParts();
    document.querySelector(".parts-panel")?.scrollIntoView({ behavior: "smooth", block: "start" });
  });
});

searchInput.addEventListener("input", () => {
  visibleLimit = 60;
  renderParts();
});

languageToggle?.addEventListener("click", () => {
  currentLang = currentLang === "ar" ? "en" : "ar";
  localStorage.setItem("batalLang", currentLang);
  applyLanguage();
});

currencyOptions.forEach((button) => {
  button.addEventListener("click", () => {
    currentCurrency = button.dataset.currency;
    localStorage.setItem("batalCurrency", currentCurrency);
    updateCurrencyButtons();
    renderDetails();
  });
});

menuToggle?.addEventListener("click", (event) => {
  event.stopPropagation();
  const toggle = document.getElementById("menuToggle");
  const panel = document.getElementById("menuPanel");
  if (!toggle || !panel) return;
  const isOpen = toggle.getAttribute("aria-expanded") === "true";
  toggle.setAttribute("aria-expanded", String(!isOpen));
  panel.classList.toggle("open", !isOpen);
});

function setDockActive(target) {
  document.querySelectorAll(".dock-item").forEach((item) => {
    item.classList.toggle("active", item.dataset.menuTarget === target);
  });
}

function openOverflowMenu() {
  const toggle = document.getElementById("menuToggle");
  const panel = document.getElementById("menuPanel");
  if (!toggle || !panel) return;
  toggle.setAttribute("aria-expanded", "true");
  panel.classList.add("open");
}

function navigateMenuTarget(target) {
  if (target === "more") {
    openOverflowMenu();
    setDockActive(target);
    return;
  }

  const targets = {
    home: ".topbar",
    parts: ".parts-panel",
    faults: '[data-section="faults"]',
    catalogs: '[data-section="catalogs"]',
    prices: '[data-section="prices"]',
    wishlist: ".detail-actions",
    contact: '[data-section="contact"]'
  };

  document.querySelector(targets[target] || ".topbar")?.scrollIntoView({ behavior: "smooth", block: "start" });
  setDockActive(target);
  document.getElementById("menuToggle")?.setAttribute("aria-expanded", "false");
  document.getElementById("menuPanel")?.classList.remove("open");
}

document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-menu-target]");
  if (!button) return;
  event.stopPropagation();
  navigateMenuTarget(button.dataset.menuTarget);
});

document.addEventListener("pointerdown", (event) => {
  const panel = document.getElementById("menuPanel");
  if (!panel?.classList.contains("open")) return;
  if (event.target.closest(".overflow-menu")) return;
  document.getElementById("menuToggle")?.setAttribute("aria-expanded", "false");
  panel.classList.remove("open");
});

loadCatalog();
applyLanguage();

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js").catch(() => {});
  });
}
