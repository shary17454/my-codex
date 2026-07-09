let catalog = { parts: [], sources: [] };
let catalogSearchIndex = { entries: [], stats: [] };
let patrolCatalogDatabase = { summary: null, files: [] };
let patrolFullCatalogIndex = { files: [], summary: null };
let partFitmentIndex = { parts: {}, sources: {}, shared_fitment_candidates: [], pdfs_bundled: false };
let storeDirectory = { verified_stores: [], categories: [] };
let savedPartRequests = [];
let parts = [];
let activeFilter = "engine";
let activeModel = "Y60";
let selectedPartId = null;
let selectedDiagramNumber = null;
let currentLang = localStorage.getItem("batalLang") || "ar";
let currentCurrency = localStorage.getItem("batalCurrency") || "SAR";
let visibleLimit = 60;
let searchDebounceTimer = null;
const wishlist = new Set();
const paidPartUnlocks = new Set();
let pendingPaidAction = null;
const catalogUnlockProductId = "batal.catalog.unlock";
const partRequestPlans = [
  {
    id: "basic",
    productId: "batal.parts.request.basic",
    priceSar: 0,
    titleKey: "requestBasicTitle",
    textKey: "requestBasicText"
  },
  {
    id: "urgent",
    productId: "batal.parts.request.urgent",
    priceSar: 0,
    titleKey: "requestUrgentTitle",
    textKey: "requestUrgentText"
  },
  {
    id: "rare",
    productId: "batal.parts.request.rare",
    priceSar: 0,
    titleKey: "requestRareTitle",
    textKey: "requestRareText"
  }
];
const storeCategoryLabels = {
  local_saudi: { ar: "محلي سعودي", en: "Saudi local" },
  gulf: { ar: "خليجي", en: "Gulf" },
  global: { ar: "عالمي", en: "Global" },
  salvage: { ar: "تشليح", en: "Salvage yard" },
  used_original: { ar: "مستعمل أصلي", en: "Used original" },
  nos: { ar: "NOS / وكالة قديمة جديدة", en: "NOS / new old stock" }
};
const pricingStores = [
  {
    id: "partsouq",
    name: "PartSouq",
    category: "global",
    homeUrl: "https://partsouq.com/",
    searchUrl: (partNumber) => `https://partsouq.com/en/search/all?q=${encodeURIComponent(partNumber)}`,
    dataAr: "السعر، العملة، التوفر، ومدة التجهيز",
    dataEn: "price, currency, availability, and dispatch time"
  },
  {
    id: "amayama",
    name: "Amayama",
    category: "global",
    homeUrl: "https://www.amayama.com/en",
    searchUrl: (partNumber) => `https://www.amayama.com/en/part/nissan/${encodeURIComponent(partNumber)}`,
    dataAr: "سعر OEM، التوفر، وخيارات الشحن",
    dataEn: "OEM price, availability, and shipping options"
  },
  {
    id: "megazip",
    name: "MegaZip",
    category: "global",
    homeUrl: "https://www.megazip.net/",
    searchUrl: (partNumber) => `https://www.megazip.net/search?q=${encodeURIComponent(partNumber)}`,
    dataAr: "سعر OEM، التوفر، الشحن، ومدة التوصيل",
    dataEn: "OEM price, availability, shipping, and delivery time"
  },
  {
    id: "almoosa",
    name: "الموسى لقطع غيار نيسان",
    category: "local_saudi",
    homeUrl: "https://almoosaparts.com/",
    searchUrl: (partNumber) => `https://almoosaparts.com/search?q=${encodeURIComponent(partNumber)}`,
    dataAr: "متجر محلي مستقل، توفر القطعة، السعر، وخيارات الدفع/الشحن من صفحة المتجر",
    dataEn: "independent local store, availability, price, and checkout/shipping options from the store page"
  }
];

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
const sharedFitmentGrid = document.getElementById("sharedFitmentGrid");
const sharedFitmentCount = document.getElementById("sharedFitmentCount");
const partRequestForm = document.getElementById("partRequestForm");
const partRequestStatus = document.getElementById("partRequestStatus");
const partRequestHistory = document.getElementById("partRequestHistory");
const verifiedStoresGrid = document.getElementById("verifiedStoresGrid");
const vehicleProfileForm = document.getElementById("vehicleProfileForm");
const vehicleProfileSummary = document.getElementById("vehicleProfileSummary");
const maintenanceForm = document.getElementById("maintenanceForm");
const maintenanceList = document.getElementById("maintenanceList");
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
    navVision: "الرؤية العالمية",
    dataStatus: "حالة البيانات",
    dataTitle: "قاعدة Y60 مدمجة",
    dataText: "بيانات مدققة من كتالوجات PDF، محفوظة في قاعدة SQLite وجاهزة للبحث والاستعراض.",
    eyebrow: "بطل الدروب لقطع نيسان باترول",
    headline: "اعرف رقم القطعة، توافقها، مصادرها، وحالة تدقيقها من مكان واحد",
    heroBadgeData: "قاعدة مدققة",
    heroBadgeOffline: "جاهز للمتصفح و iOS",
    heroBadgeLang: "عربي / English",
    independentNotice: "بطل الدروب تطبيق مستقل. لا يتبع نيسان أو الوكيل الرسمي، وروابط المتاجر الخارجية للتسهيل فقط وليست اعتماداً رسمياً.",
    metricPartsLabel: "قطعة موثقة",
    metricRecordsLabel: "سجل مستخرج",
    metricBuildLabel: "إصدار التطبيق",
    wishlist: "قائمة الرغبات",
    currencySar: "ريال",
    currencyUsd: "دولار",
    menuHome: "الرئيسية",
    menuParts: "القطع",
    menuPartRequest: "طلب قطعة",
    menuFaults: "الأعطال الشائعة",
    menuCatalogs: "الكتالوجات",
    menuSharedFitment: "القطع المشتركة",
    menuSourceIntake: "مصادر الفهرسة",
    menuPrices: "الأسعار",
    menuVision: "الرؤية العالمية",
    menuWishlist: "قائمة الرغبات",
    menuContact: "تواصل معنا",
    menuMore: "المزيد",
    generationsTitle: "أجيال الباترول",
    generationsSubtitle: "اختر الجيل المناسب لقاعدة القطع",
    generationY60: "الجيل الكلاسيكي المربع، أساس قاعدة البيانات الحالية.",
    generationY61: "جيل السفاري المعروف بقوة الاعتماد وكثرة الاستخدام في الخليج.",
    generationY62: "جيل فاخر كبير الحجم مع أنظمة حديثة وقاعدة قطع مختلفة.",
    generationY63: "الجيل الجديد بواجهة عمودية وشبك كبير وإضاءة C مميزة.",
    generationActive: "الجيل الحالي النشط",
    generationSoon: "قريباً في التحديث القادم",
    generationSubscription: "اشتراك",
    generationDbFiles: "ملفات",
    generationDbUnique: "فريدة",
    generationDbPages: "صفحات",
    generationDbYears: "سنوات",
    generationDbEngines: "محركات",
    generationDbNoData: "لم تضاف كتالوجات لهذا الجيل بعد",
    sharedFitmentTitle: "القطع المشتركة بين أكثر من موديل",
    sharedFitmentSubtitle: "مرشحات من قاعدة Y60 تظهر عبر سنوات ومحركات متعددة، وتحتاج مطابقة رقم الهيكل قبل التركيب",
    sharedFitmentCountLabel: "قطعة مرشحة للتوافق الواسع",
    sharedFitmentScopeLabel: "نطاق سنوات Y60 المفهرسة",
    sharedFitmentEngineLabel: "محركات تظهر في بيانات التوافق",
    sharedFitmentNote: "مهم: القطعة المشتركة لا تعني التركيب المباشر على كل سيارة. طابق رقم القطعة مع VIN، سنة الصنع، المحرك، القير، والفئة قبل الشراء أو التركيب.",
    sharedPartTag: "مشتركة",
    sharedPartWide: "تغطي سنوات كثيرة",
    sharedPartEngines: "تظهر مع أكثر من محرك",
    sharedPartSources: "مصادر متعددة",
    sharedPartOpen: "عرض القطعة",
    sharedPartVerify: "تحقق قبل التركيب",
    partRequestTitle: "طلب قطعة",
    partRequestSubtitle: "جهز بيانات القطعة لإرسالها للمتاجر السعودية والخليجية والعالمية بدون دفع في نسخة 1.0.",
    requestCustomerFeesTitle: "متاح للمراجعة",
    requestBasicTitle: "طلب عادي",
    requestBasicText: "تجهيز الطلب وإرساله للمتاجر المناسبة.",
    requestUrgentTitle: "طلب مستعجل",
    requestUrgentText: "أولوية أعلى وصياغة طلب جاهز للواتساب والبريد.",
    requestRareTitle: "طلب قطعة نادرة / NOS",
    requestRareText: "بحث مركز للقطع النادرة، المستعملة الأصلية، أو وكالة قديمة جديدة.",
    requestVehicleTitle: "بيانات السيارة",
    requestPartTitle: "بيانات القطعة",
    requestGeneration: "الجيل",
    requestYear: "سنة الصنع",
    requestVin: "رقم الهيكل VIN",
    requestEngine: "المحرك",
    requestTransmission: "القير",
    requestPartNumber: "رقم القطعة إن وجد",
    requestPartName: "اسم القطعة",
    requestPartType: "نوع القطعة المطلوبة",
    requestGoal: "هدف الطلب",
    requestNotes: "ملاحظات إضافية",
    requestSubmit: "تجهيز الطلب",
    requestDraftTitle: "نص الطلب الجاهز للمتاجر",
    requestRequired: "أدخل اسم القطعة أو رقم القطعة على الأقل.",
    requestSubmitted: "تم حفظ طلب القطعة. يمكنك نسخ النص وإرساله للمتاجر.",
    requestPlanLabel: "نوع الطلب",
    requestHistoryTitle: "طلبات القطع المحفوظة",
    requestHistorySubtitle: "تظهر آخر الطلبات المحفوظة محلياً أو عبر API المحلي.",
    requestHistoryEmpty: "لا توجد طلبات محفوظة بعد.",
    requestCopyDraft: "نسخ نص الطلب",
    requestCopied: "تم نسخ نص الطلب.",
    verifiedStoresTitle: "المتاجر الموثقة",
    verifiedStoresSubtitle: "روابط شراء وبحث لا تظهر إلا إذا كانت موثقة من مصدر رسمي.",
    verifiedStoresEmpty: "لا توجد متاجر موثقة مفعلة بعد.",
    storeOpenWebsite: "فتح المتجر",
    storeSearchPart: "البحث بالرقم",
    storeVerification: "التوثيق",
    requestTypeOem: "أصلي وكالة OEM",
    requestTypeManufacturer: "OEM Manufacturer",
    requestTypeAftermarket: "بديل تجاري",
    requestTypeUsed: "مستعمل أصلي",
    requestTypeNos: "NOS وكالة قديمة جديدة",
    requestTypeAny: "أي خيار مناسب",
    requestGoalAvailability: "أبحث عن توفر فقط",
    requestGoalBuy: "أريد شراء مباشر",
    requestGoalCompare: "أريد مقارنة أسعار",
    requestGoalBestQuality: "أريد أفضل جودة",
    requestGoalCheapest: "أريد أرخص خيار",
    smartSearch: "بحث ذكي",
    searchPlaceholder: "رقم القطعة، الاسم، القسم، أو VIN",
    searchHint: "التصفية فورية ومخففة لتقليل التقطيع أثناء الكتابة.",
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
    statSources: "ملفات PDF مفحوصة",
    statReview: "تحتاج مراجعة",
    statRecords: "سجلات مستخرجة",
    statCatalogPages: "صفحات كتالوج",
    sourceIntakeTitle: "مصادر الفهرسة الجديدة",
    sourceIntakeSubtitle: "تم فحص ملفات PDF الجديدة بالبصمة وعدد الصفحات قبل دمجها في التطبيق",
    sourceReady: "جاهز للفهرسة",
    sourceReview: "مراجعة قبل الدمج",
    sourceArchive: "أرشيف تحقق",
    sourceDuplicate: "مكرر",
    sourceHelper: "مصدر مساعد",
    sourceY62Text: "كتالوج جديد من 1,275 صفحة. يضاف كخيار Y62 مستقل مع فهرس بحث خاص به.",
    sourceY60Text: "ملفات سنوات Y60 الجديدة أقصر من ملفات التطبيق الحالية؛ تحفظ للمقارنة ولا تستبدل القاعدة المفهرسة مباشرة.",
    sourceCombinedText: "ملف مجمع من 5,281 صفحة يستخدم للتحقق من الصفحات الناقصة ومراجعة الفهارس.",
    sourceWgyText: "ملف بطاقة السيارة مطابق للموجود داخل التطبيق، لذلك لا ينسخ مرة ثانية.",
    sourcePartsouqText: "ملفات قصيرة تصلح كمرجع تصميم أو فهرسة مساعدة، وليست بديلة عن كتالوجات OEM.",
    visionTitle: "المزايا التي تجعل تطبيق الباترول مرجعًا عالميًا",
    visionSubtitle: "خارطة تطوير معتمدة لقاعدة القطع، الأسعار، الصيانة، المجتمع، والذكاء الاصطناعي",
    visionDatabaseTitle: "قاعدة بيانات احترافية",
    visionDatabaseText: "رسومات أصلية، OEM، أسماء متعددة اللغات، وصف وظيفة القطعة، موقعها، صورها، والأبعاد عند توفرها.",
    visionFitmentTitle: "توافق القطع",
    visionFitmentText: "معرفة السيارات المطابقة والفروقات بين Y60 وY61 وY62 حسب السنة والمحرك والقير والفئة.",
    visionSearchTitle: "البحث الذكي",
    visionSearchText: "بحث برقم القطعة، الاسم، العربية، الإنجليزية، VIN، والقسم الفني.",
    visionPricesTitle: "مقارنة الأسعار",
    visionPricesText: "السعر، العملة، الشحن، مدة التوصيل، الدولة، وحالة القطعة من عدة متاجر.",
    visionTypeTitle: "تصنيف نوع القطعة",
    visionTypeText: "OEM، مصنع أصلي، إعادة تصنيع عالية الجودة، بديل تجاري، مستعملة أصلية، وNOS.",
    visionRarityTitle: "مؤشر الندرة",
    visionRarityText: "متوفرة بكثرة، محدودة، نادرة، أو موقوفة الإنتاج NLA.",
    visionMaintenanceTitle: "الصيانة والشروحات",
    visionMaintenanceText: "أعراض التلف، العمر الافتراضي، القطع المصاحبة، عزم الربط، الأدوات، ودرجة الصعوبة.",
    visionCommunityTitle: "المجتمع والمتاجر",
    visionCommunityText: "تقييمات، تجارب ملاك، مشاريع ترميم، متاجر عالمية وخليجية، تشاليح، وبائعون موثقون.",
    visionAiTitle: "الذكاء الاصطناعي والإحصائيات",
    visionAiText: "معرفة القطعة من صورة، اقتراح البدائل، تشخيص الأعطال، وأكثر القطع طلبًا وندرة.",
    visionGoal: "الهدف النهائي: أن يجد مالك نيسان باترول كل ما يحتاجه عن أي قطعة في مكان واحد دون التنقل بين عشرات المواقع والمتاجر.",
    resultsTitle: "نتائج القطع",
    partsPageAll: "كل قطع",
    partsPageCategory: "قطع",
    modelComingSoon: "قاعدة هذا الجيل ضمن الاشتراك. افتح الاشتراك للوصول إلى كتالوجات الجيل وأرقام القطع.",
    resultSingular: "نتيجة",
    resultPlural: "نتيجة",
    oem: "OEM",
    catalogPage: "صفحة كتالوج",
    openPdf: "فتح PDF الأصلي",
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
    marketPrices: "أسعار موثقة",
    localMarket: "السوق السعودي",
    gulfMarket: "متاجر الخليج",
    globalMarket: "المتاجر العالمية",
    shippingIncluded: "مصدر موثق مع تاريخ التحديث",
    noVerifiedPrices: "لا توجد أسعار حقيقية موثقة لهذه القطعة حالياً.",
    priceSource: "المصدر",
    priceUpdatedAt: "آخر تحديث",
    pricingStoresTitle: "خيارات شراء خارجية مستقلة",
    pricingStoresSubtitle: "افتح المتجر المستقل وتحقق من السعر الحقيقي برقم القطعة. ظهور المتجر لا يعني شراكة رسمية إلا إذا ظهرت شارة اتفاق موثق.",
    storeCategory: "تصنيف المتجر",
    openStore: "فتح الخيار الخارجي",
    storeData: "بيانات قد يوفرها",
    lookupNeedsNumber: "يتطلب رقم قطعة حقيقي",
    copyPartNumber: "رقم القطعة",
    category: "التصنيف المبدئي",
    auditStatus: "حالة التدقيق",
    confidenceScore: "درجة الثقة",
    catalogEvidence: "أدلة من الكتالوجات",
    fullPartNumbers: "أرقام القطع الكاملة",
    fullPartNumbersHint: "تعرض كل أرقام OEM المستخرجة من صفحات الكتالوج المرتبطة بهذه النتيجة.",
    noPartNumbers: "لا توجد أرقام قطعة مستخرجة",
    generatedDiagramTitle: "مخطط مرسوم حسب رقم القطعة",
    generatedDiagramNote: "رسم إرشادي مستخرج من بيانات القطعة ومرجع الكتالوج. ملفات PDF الأصلية تبقى خارج التطبيق وتُفتح عند توفر رابط خارجي.",
    diagramNumber: "رقم الرسم",
    payUnlockNumbers: "عرض أرقام القطع",
    year: "سنة",
    page: "صفحة",
    enrichmentNext: "خطوة الإثراء التالية",
    enrichment1: "تدقيق اسم القطعة عربي وإنجليزي من الرسم الأصلي.",
    enrichment2: "ربط القطعة بالقسم والرسم الانفجاري والصورة الحقيقية.",
    enrichment3: "إضافة الأسعار والتوفر من المتاجر بعد اعتماد رقم القطعة.",
    saveWishlist: "حفظ في قائمة الرغبات",
    saved: "تم الحفظ",
    priceAlert: "تنبيه عند توفر بيانات سعر",
    priceEstimateDisclaimer: "لا يعرض بطل الدروب أي سعر إلا إذا كان مربوطاً بمصدر حقيقي، رابط، عملة، حالة توفر، وتاريخ تحديث.",
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
    auditReviewManual: "يحتاج مراجعة يدوية",
    lockedPartNumber: "رقم القطعة محمي",
    paymentRequired: "متاح في نسخة 1.0",
    paywallTitle: "محتوى الكتالوج متاح",
    paywallText: "أرقام القطع وصفحات PDF المرفقة متاحة في نسخة 1.0 بدون شراء.",
    payUnlockNumber: "عرض رقم القطعة",
    payOpenCatalog: "فتح الكتالوج",
    purchasePending: "جاري فتح المحتوى...",
    purchaseSuccess: "تم فتح المحتوى",
    purchaseUnavailable: "المحتوى متاح في نسخة 1.0 بدون شراء.",
    purchaseCancelled: "تم إلغاء فتح المحتوى.",
    protectedContent: "محتوى الكتالوج",
    captureBlocked: "تم حجب الكتالوج أثناء تسجيل الشاشة أو العرض الخارجي."
  },
  en: {
    brandMark: "BD",
    appName: "بطل الدروب",
    brandSubtitle: "Patrol Y60 Parts Catalog",
    navCatalog: "Catalog",
    navDiagrams: "Diagrams",
    navPrices: "Prices",
    navMaintenance: "Maintenance",
    navCommunity: "Community",
    navVision: "Global Vision",
    dataStatus: "Data Status",
    dataTitle: "Integrated Y60 Database",
    dataText: "Audited PDF catalog data stored in SQLite and ready for search and browsing.",
    eyebrow: "بطل الدروب for Nissan Patrol Parts",
    headline: "Find the part number, fitment, sources, and audit status in one place",
    heroBadgeData: "Audited database",
    heroBadgeOffline: "Browser and iOS ready",
    heroBadgeLang: "Arabic / English",
    independentNotice: "بطل الدروب is an independent app. It is not affiliated with Nissan or an official dealer; external store links are provided for convenience only.",
    metricPartsLabel: "verified parts",
    metricRecordsLabel: "extracted records",
    metricBuildLabel: "app version",
    wishlist: "Wishlist",
    currencySar: "SAR",
    currencyUsd: "USD",
    menuHome: "Home",
    menuParts: "Parts",
    menuPartRequest: "Request Part",
    menuFaults: "Common Faults",
    menuCatalogs: "Catalogs",
    menuSharedFitment: "Shared Parts",
    menuSourceIntake: "Indexing Sources",
    menuPrices: "Prices",
    menuVision: "Global Vision",
    menuWishlist: "Wishlist",
    menuContact: "Contact Us",
    menuMore: "More",
    generationsTitle: "Patrol Generations",
    generationsSubtitle: "Choose the generation that matches the parts database",
    generationY60: "The classic boxy generation and the foundation of the current database.",
    generationY61: "The Safari generation known for durability and heavy Gulf use.",
    generationY62: "A large luxury generation with modern systems and a different parts base.",
    generationY63: "The new generation with an upright front, large grille, and C-shaped lighting.",
    generationActive: "Current active generation",
    generationSoon: "Coming in the next update",
    generationSubscription: "Subscription",
    generationDbFiles: "Files",
    generationDbUnique: "Unique",
    generationDbPages: "Pages",
    generationDbYears: "Years",
    generationDbEngines: "Engines",
    generationDbNoData: "No catalogs added for this generation yet",
    sharedFitmentTitle: "Parts Shared Across More Than One Model",
    sharedFitmentSubtitle: "Candidates from the Y60 database that appear across multiple years and engines. Verify by VIN before installation.",
    sharedFitmentCountLabel: "wide-fitment candidate parts",
    sharedFitmentScopeLabel: "indexed Y60 year range",
    sharedFitmentEngineLabel: "engines found in fitment data",
    sharedFitmentNote: "Important: a shared part does not mean direct fitment on every vehicle. Match the part number with VIN, production year, engine, transmission, and trim before buying or installing.",
    sharedPartTag: "Shared",
    sharedPartWide: "Wide year coverage",
    sharedPartEngines: "Appears with multiple engines",
    sharedPartSources: "Multiple sources",
    sharedPartOpen: "View part",
    sharedPartVerify: "Verify before install",
    partRequestTitle: "Part Request",
    partRequestSubtitle: "Prepare the part request for Saudi, Gulf, and global stores with no payment in version 1.0.",
    requestCustomerFeesTitle: "Included for review",
    requestBasicTitle: "Standard request",
    requestBasicText: "Prepare the request and route it to matching stores.",
    requestUrgentTitle: "Urgent request",
    requestUrgentText: "Higher priority and a ready WhatsApp/email message.",
    requestRareTitle: "Rare / NOS request",
    requestRareText: "Focused search for rare, used original, or new old stock parts.",
    requestVehicleTitle: "Vehicle details",
    requestPartTitle: "Part details",
    requestGeneration: "Generation",
    requestYear: "Production year",
    requestVin: "VIN",
    requestEngine: "Engine",
    requestTransmission: "Transmission",
    requestPartNumber: "Part number if known",
    requestPartName: "Part name",
    requestPartType: "Requested part type",
    requestGoal: "Request goal",
    requestNotes: "Additional notes",
    requestSubmit: "Prepare request",
    requestDraftTitle: "Store-ready request text",
    requestRequired: "Enter either the part name or part number.",
    requestSubmitted: "Part request saved. You can copy the text and send it to stores.",
    requestPlanLabel: "Request type",
    requestHistoryTitle: "Saved part requests",
    requestHistorySubtitle: "Shows the latest requests saved locally or through the local API.",
    requestHistoryEmpty: "No saved requests yet.",
    requestCopyDraft: "Copy request text",
    requestCopied: "Request text copied.",
    verifiedStoresTitle: "Verified stores",
    verifiedStoresSubtitle: "Buying and search links appear only when verified from an official source.",
    verifiedStoresEmpty: "No verified stores enabled yet.",
    storeOpenWebsite: "Open store",
    storeSearchPart: "Search by number",
    storeVerification: "Verification",
    requestTypeOem: "OEM genuine",
    requestTypeManufacturer: "OEM Manufacturer",
    requestTypeAftermarket: "Aftermarket",
    requestTypeUsed: "Used original",
    requestTypeNos: "NOS new old stock",
    requestTypeAny: "Any suitable option",
    requestGoalAvailability: "Check availability only",
    requestGoalBuy: "Ready to buy",
    requestGoalCompare: "Compare prices",
    requestGoalBestQuality: "Best quality",
    requestGoalCheapest: "Cheapest option",
    smartSearch: "Smart Search",
    searchPlaceholder: "Part number, name, category, or VIN",
    searchHint: "Instant filtering is throttled to keep typing smooth.",
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
    statSources: "Checked PDF Files",
    statReview: "Need Review",
    statRecords: "Extracted Records",
    statCatalogPages: "Catalog Pages",
    sourceIntakeTitle: "New Indexing Sources",
    sourceIntakeSubtitle: "New PDF files were checked by fingerprint and page count before app integration",
    sourceReady: "Ready to index",
    sourceReview: "Review before merge",
    sourceArchive: "Verification archive",
    sourceDuplicate: "Duplicate",
    sourceHelper: "Helper source",
    sourceY62Text: "A new 1,275-page catalog. It should be added as a separate Y62 option with its own search index.",
    sourceY60Text: "The new Y60 yearly files are shorter than the app's current files, so they stay as comparison sources instead of replacing the indexed database.",
    sourceCombinedText: "A 5,281-page combined archive for checking missing pages and validating indexes.",
    sourceWgyText: "The vehicle profile file matches the copy already inside the app, so it should not be copied again.",
    sourcePartsouqText: "Short files useful for layout or helper indexing, not replacements for OEM catalogs.",
    visionTitle: "Features that make the Patrol app a global reference",
    visionSubtitle: "Approved roadmap for parts data, prices, maintenance, community, and AI",
    visionDatabaseTitle: "Professional database",
    visionDatabaseText: "Original diagrams, OEM numbers, multilingual names, function descriptions, location, photos, and dimensions when available.",
    visionFitmentTitle: "Part fitment",
    visionFitmentText: "Matching vehicles and differences across Y60, Y61, and future Y62 by year, engine, transmission, and trim.",
    visionSearchTitle: "Smart search",
    visionSearchText: "Search by part number, name, Arabic, English, VIN, and technical section.",
    visionPricesTitle: "Price comparison",
    visionPricesText: "Price, currency, shipping, delivery time, country, and part condition from multiple stores.",
    visionTypeTitle: "Part type classification",
    visionTypeText: "OEM, OEM manufacturer, high quality reproduction, aftermarket, used original, and NOS.",
    visionRarityTitle: "Rarity indicator",
    visionRarityText: "Widely available, limited stock, rare, or no longer available NLA.",
    visionMaintenanceTitle: "Maintenance and guides",
    visionMaintenanceText: "Failure symptoms, service life, related parts, torque specs, tools, and difficulty level.",
    visionCommunityTitle: "Community and stores",
    visionCommunityText: "Ratings, owner experiences, restoration projects, global and Gulf stores, salvage yards, and verified sellers.",
    visionAiTitle: "AI and statistics",
    visionAiText: "Identify parts from images, suggest alternatives, diagnose faults, and show most requested or rare parts.",
    visionGoal: "Final goal: let every Nissan Patrol owner find everything about any part in one place without jumping across dozens of sites and stores.",
    resultsTitle: "Part Results",
    partsPageAll: "All parts for",
    partsPageCategory: "Parts for",
    modelComingSoon: "This generation database is part of the subscription. Unlock access to view catalogs and part numbers.",
    resultSingular: "result",
    resultPlural: "results",
    oem: "OEM",
    catalogPage: "Catalog Page",
    openPdf: "Open Original PDF",
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
    marketPrices: "Verified Prices",
    localMarket: "Saudi Market",
    gulfMarket: "Gulf Stores",
    globalMarket: "Global Stores",
    shippingIncluded: "Verified source with update date",
    noVerifiedPrices: "No real verified prices are available for this part yet.",
    priceSource: "Source",
    priceUpdatedAt: "Updated",
    pricingStoresTitle: "Independent External Buying Options",
    pricingStoresSubtitle: "Open the independent store and verify the real price by part number. A listed store is not an official partnership unless a verified agreement badge is shown.",
    storeCategory: "Store category",
    openStore: "Open External Option",
    storeData: "May provide",
    lookupNeedsNumber: "Requires a real part number",
    copyPartNumber: "Part number",
    category: "Initial Category",
    auditStatus: "Audit Status",
    confidenceScore: "Confidence Score",
    catalogEvidence: "Catalog Evidence",
    fullPartNumbers: "Full Part Numbers",
    fullPartNumbersHint: "Shows all OEM numbers extracted from the catalog pages linked to this result.",
    noPartNumbers: "No extracted part numbers",
    generatedDiagramTitle: "Diagram Drawn From Part Number",
    generatedDiagramNote: "Reference drawing derived from part data and catalog references. Original PDFs stay outside the app and open only when an external link is available.",
    diagramNumber: "Diagram number",
    payUnlockNumbers: "Show part numbers",
    year: "Year",
    page: "Page",
    enrichmentNext: "Next Enrichment Step",
    enrichment1: "Verify Arabic and English names from the original diagram.",
    enrichment2: "Link the part to its section, exploded diagram, and real image.",
    enrichment3: "Add prices and availability after the part number is approved.",
    saveWishlist: "Save to Wishlist",
    saved: "Saved",
    priceAlert: "Alert when price data is available",
    priceEstimateDisclaimer: "بطل الدروب only shows prices when they are tied to a real source, URL, currency, availability status, and update date.",
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
    auditReviewManual: "Needs manual review",
    lockedPartNumber: "Protected part number",
    paymentRequired: "Included in version 1.0",
    paywallTitle: "Catalog content included",
    paywallText: "Part numbers and bundled PDF pages are available in version 1.0 without purchase.",
    payUnlockNumber: "Show part number",
    payOpenCatalog: "Open catalog",
    purchasePending: "Opening content...",
    purchaseSuccess: "Content unlocked.",
    purchaseUnavailable: "Content is available in version 1.0 without purchase.",
    purchaseCancelled: "Content opening was cancelled.",
    protectedContent: "Catalog content",
    captureBlocked: "Catalog content is hidden while screen recording or mirroring is active."
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

function verifiedPrices(part) {
  if (!Array.isArray(part?.prices)) return [];
  return part.prices.filter((price) => (
    price
    && price.verified === true
    && Number.isFinite(Number(price.amount))
    && typeof price.currency === "string"
    && price.currency.length === 3
    && typeof price.source === "string"
    && typeof price.url === "string"
    && /^https?:\/\//i.test(price.url)
    && typeof price.updated_at === "string"
  ));
}

function formatVerifiedMoney(price) {
  const locale = currentLang === "ar" ? "ar-SA" : "en-US";
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency: price.currency,
    maximumFractionDigits: price.currency === "JPY" ? 0 : 2
  }).format(Number(price.amount));
}

function isRealPartNumber(part) {
  const value = part?.part_number || "";
  return Boolean(value && !value.startsWith("CAT-") && !value.startsWith("••"));
}

function renderPricingStoreOptions(part) {
  const partNumber = isRealPartNumber(part) ? part.part_number : "";
  return `
    <div class="store-options">
      <div class="store-options-head">
        <h4>${t("pricingStoresTitle")}</h4>
        <p>${t("pricingStoresSubtitle")}</p>
        <p class="store-legal">${t("independentNotice")}</p>
      </div>
      <div class="store-grid">
        ${pricingStores.map((store) => {
          const url = partNumber ? store.searchUrl(partNumber) : store.homeUrl;
          const dataLabel = currentLang === "ar" ? store.dataAr : store.dataEn;
          const storeType = storeCategoryLabels[store.category]?.[currentLang] || store.category;
          return `
            <article class="store-card">
              <div>
                <em class="store-type">${t("storeCategory")}: ${storeType}</em>
                <strong>${store.name}</strong>
                <span>${t("storeData")}: ${dataLabel}</span>
                <small>${partNumber ? `${t("copyPartNumber")}: ${partNumber}` : t("lookupNeedsNumber")}</small>
              </div>
              <a href="${url}" target="_blank" rel="noopener">${t("openStore")}</a>
            </article>
          `;
        }).join("")}
      </div>
    </div>
  `;
}

function categoryLabel(part) {
  return t(categoryKeys[part.category] || "catGeneral");
}

function sectionToCategory(sectionId) {
  const map = {
    vehicle: "general",
    engine: "engine",
    transmission: "suspension",
    drivetrain: "suspension",
    brakes: "brake",
    body: "body",
    interior: "interior",
    electrical: "electrical",
    hvac: "cooling",
    general: "general"
  };
  return map[sectionId] || "general";
}

function formatOemNumber(value) {
  const raw = String(value || "").toUpperCase().replace(/[^0-9A-Z]/g, "");
  if (raw.length !== 10) return "";
  const digitCount = raw.replace(/[^0-9]/g, "").length;
  if (digitCount < 5) return "";
  return `${raw.slice(0, 5)}-${raw.slice(5)}`;
}

function extractOemNumbersFromText(...values) {
  const found = [];
  values.forEach((value) => {
    if (!value) return;
    const text = typeof value === "string" ? value : JSON.stringify(value);
    const matches = text.toUpperCase().match(/\b[0-9A-Z]{5}-?[0-9A-Z]{5}\b/g) || [];
    matches.forEach((match) => {
      const formatted = formatOemNumber(match);
      if (formatted && !found.includes(formatted)) found.push(formatted);
    });
  });
  return found.slice(0, 24);
}

function buildDiagramKey(numbers = [], fallback = "") {
  const source = (numbers.join("") || String(fallback || "")).toUpperCase();
  const total = Array.from(source).reduce((sum, char, index) => sum + ((index + 1) * char.charCodeAt(0)), 0);
  return `DGM-${String(total % 100000).padStart(5, "0")}`;
}

function catalogEntryToPart(entry) {
  const keywords = Array.isArray(entry.keywords) ? entry.keywords : [];
  const partNumbers = extractOemNumbersFromText(
    entry.titleAr,
    entry.titleEn,
    entry.subtitleAr,
    entry.snippet,
    entry.queryText,
    keywords.join(" ")
  );
  return {
    part_number: `CAT-${entry.id}`,
    name_ar: entry.titleAr || entry.titleEn || entry.id,
    name_en: entry.titleEn || entry.titleAr || entry.id,
    model: "Y60",
    years: entry.year ? [String(entry.year)] : [],
    engines: keywords.filter((word) => /^(TB42S|TB42E|TD42|RD28T|RB30S|FS5R50A)$/i.test(word)).slice(0, 4),
    date_ranges: [],
    category: sectionToCategory(entry.sectionId),
    category_ar: entry.sectionTitleAr || entry.sectionId || "عام",
    occurrence_count: 1,
    source_count: 1,
    weighted_source_score: 1,
    confidence: 82,
    audit_status: "verified",
    rarity: "موثق",
    record_type: "catalog_page",
    catalog_id: entry.id,
    part_numbers: partNumbers,
    primary_oem_number: partNumbers[0] || "",
    diagram_key: buildDiagramKey(partNumbers, entry.id),
    source_pdf_path: entry.sourcePdfPath,
    page_number: entry.pageNumber,
    keywords,
    snippet: entry.snippet || "",
    query_text: entry.queryText || "",
    evidence: [{
      source_id: entry.sourcePdfPath?.split("/").pop() || "catalog",
      year: entry.year || "Y60",
      page: entry.pageNumber ?? 0,
      context: entry.snippet || entry.subtitleAr || entry.titleAr || ""
    }]
  };
}

function pdfHref(sourcePath) {
  if (!sourcePath) return "";
  if (!sourcePath.startsWith("assets/catalog/")) return sourcePath;
  if (window.location.protocol === "file:" || window.location.pathname.includes("/Web/")) {
    return sourcePath.replace(/^assets\/catalog\//, "catalog/");
  }
  return `flutter_y60_catalog/${sourcePath}`;
}

function mergeCatalogEntries(baseParts, index) {
  const entries = Array.isArray(index?.entries) ? index.entries : [];
  const existing = new Set(baseParts.map((part) => part.part_number));
  const catalogPageParts = entries
    .map(catalogEntryToPart)
    .filter((part) => !existing.has(part.part_number));
  return [...baseParts, ...catalogPageParts];
}

function normalizePartLookupKey(value) {
  return String(value || "").toUpperCase().replace(/[^0-9A-Z]/g, "");
}

function externalPdfPathForFitment(fitment, index) {
  if (!fitment) return "";
  if (fitment.remote_url) return fitment.remote_url;
  if (index?.pdfs_bundled && fitment.source_pdf_path) return fitment.source_pdf_path;
  return "";
}

function enrichPartsWithFitment(sourceParts, index) {
  const fitmentParts = index?.parts || {};
  const byNormalized = new Map();
  Object.entries(fitmentParts).forEach(([key, value]) => {
    byNormalized.set(normalizePartLookupKey(key), value);
    byNormalized.set(normalizePartLookupKey(value.primary_oem_number), value);
    (value.part_numbers || []).forEach((number) => byNormalized.set(normalizePartLookupKey(number), value));
  });

  return sourceParts.map((part) => {
    const fitment = fitmentParts[part.part_number] || byNormalized.get(normalizePartLookupKey(part.part_number));
    if (!fitment) return part;
    const partNumbers = Array.from(new Set([
      ...(Array.isArray(part.part_numbers) ? part.part_numbers : []),
      ...(Array.isArray(fitment.part_numbers) ? fitment.part_numbers : [])
    ].filter(Boolean)));
    const evidence = (Array.isArray(fitment.evidence) && fitment.evidence.length)
      ? fitment.evidence
      : (part.evidence || []);
    return {
      ...part,
      part_numbers: partNumbers,
      primary_oem_number: fitment.primary_oem_number || part.primary_oem_number,
      diagram_key: fitment.diagram_key || fitment.diagram_reference || part.diagram_key,
      diagram_reference: fitment.diagram_reference || part.diagram_reference || "",
      years: (fitment.years?.length ? fitment.years : part.years) || [],
      engines: (fitment.engines?.length ? fitment.engines : part.engines) || [],
      date_ranges: (fitment.date_ranges?.length ? fitment.date_ranges : part.date_ranges) || [],
      source_count: fitment.source_count || part.source_count || 0,
      occurrence_count: fitment.occurrence_count || part.occurrence_count || 0,
      source_pdf_path: externalPdfPathForFitment(fitment, index) || part.source_pdf_path || "",
      page_number: fitment.page_number || part.page_number,
      evidence,
      fitment_indexed: true,
      shared_fitment_score: fitment.shared_fitment_score || 0
    };
  });
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
  const shield = document.getElementById("screenShield");
  if (shield) {
    shield.innerHTML = `<div><strong>${t("protectedContent")}</strong><span>${t("captureBlocked")}</span></div>`;
  }
  updateCurrencyButtons();
  updateStats();
  renderGenerationDatabaseStats();
  renderSharedFitment();
  renderVehicleProfile();
  renderMaintenanceLog();
  renderVerifiedStores();
  renderPartRequestHistory();
  renderParts();
}

function updateCurrencyButtons() {
  currencyOptions.forEach((button) => {
    button.classList.toggle("active", button.dataset.currency === currentCurrency);
  });
  updatePartRequestPlans();
}

function updatePartRequestPlans() {
  document.querySelectorAll(".request-plan").forEach((button) => {
    const plan = partRequestPlans.find((item) => item.id === button.dataset.requestPlan);
    if (!plan) return;
    const price = button.querySelector("strong");
    if (price) price.textContent = currentLang === "ar" ? "بدون دفع" : "No payment";
  });
}

function normalize(value) {
  return String(value || "")
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u064B-\u065F\u0670]/g, "")
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/ؤ/g, "و")
    .replace(/ئ/g, "ي")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
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

function sharedFitmentScore(part) {
  const yearCount = Array.isArray(part.years) ? part.years.length : 0;
  const engineCount = Array.isArray(part.engines) ? part.engines.length : 0;
  const sourceCount = Number(part.source_count || 0);
  const occurrenceCount = Number(part.occurrence_count || 0);
  return (yearCount * 8) + (engineCount * 11) + (sourceCount * 7) + Math.min(occurrenceCount, 60);
}

function sharedFitmentReasons(part) {
  const reasons = [];
  if ((part.years?.length || 0) >= 6) reasons.push(t("sharedPartWide"));
  if ((part.engines?.length || 0) >= 2) reasons.push(t("sharedPartEngines"));
  if ((part.source_count || 0) >= 3) reasons.push(t("sharedPartSources"));
  return reasons.length ? reasons : [t("sharedPartVerify")];
}

function isSharedFitmentCandidate(part) {
  return part.model === "Y60"
    && part.record_type !== "catalog_page"
    && ((part.years?.length || 0) >= 4 || (part.engines?.length || 0) >= 2 || (part.source_count || 0) >= 4);
}

function sharedFitmentParts(limit = 8) {
  return parts
    .filter(isSharedFitmentCandidate)
    .sort((a, b) => {
      const scoreDiff = sharedFitmentScore(b) - sharedFitmentScore(a);
      if (scoreDiff) return scoreDiff;
      return String(a.part_number).localeCompare(String(b.part_number));
    })
    .slice(0, limit);
}

function renderSharedFitment() {
  if (!sharedFitmentGrid) return;
  const candidates = sharedFitmentParts(8);
  if (sharedFitmentCount) {
    sharedFitmentCount.textContent = parts.filter(isSharedFitmentCandidate).length.toLocaleString("en-US");
  }

  sharedFitmentGrid.innerHTML = candidates.map((part) => `
    <article class="shared-part-card">
      <div class="shared-part-head">
        <span>${t("sharedPartTag")}</span>
        <strong>${part.confidence || 0}%</strong>
      </div>
      <h3>${displayName(part)}</h3>
      ${originalNameLine(part)}
      <div class="shared-part-number">${protectedPartNumber(part)}</div>
      <div class="shared-part-meta">
        <span>${yearsLabel(part)}</span>
        <span>${enginesLabel(part)}</span>
        <span>${part.source_count || 0} ${t("sources")}</span>
      </div>
      <div class="shared-reasons">
        ${sharedFitmentReasons(part).map((reason) => `<span>${reason}</span>`).join("")}
      </div>
      <button class="secondary-action" type="button" data-shared-part="${part.part_number}">${t("sharedPartOpen")}</button>
    </article>
  `).join("");
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
  const normalizedQuery = normalize(query);
  if (!normalizedQuery || normalizedQuery.length < 2) return true;
  const haystack = [
    part.part_number,
    part.name_ar,
    part.name_en,
    translatedPartName(part.name_en),
    part.category_ar,
    part.model,
    yearsLabel(part),
    part.keywords?.join(" "),
    part.snippet,
    part.query_text,
    evidenceText(part)
  ].join(" ");
  return normalize(haystack).includes(normalizedQuery);
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

function partAccessId(part) {
  return part?.part_number || part?.catalog_id || "";
}

function fullPartNumbers(part) {
  if (!part) return [];
  const numbers = [];
  const primary = formatOemNumber(part.primary_oem_number || part.part_number);
  if (primary) numbers.push(primary);
  (Array.isArray(part.part_numbers) ? part.part_numbers : []).forEach((number) => {
    const formatted = formatOemNumber(number);
    if (formatted && !numbers.includes(formatted)) numbers.push(formatted);
  });
  (part.evidence || []).forEach((item) => {
    extractOemNumbersFromText(item.reference, item.context).forEach((number) => {
      if (!numbers.includes(number)) numbers.push(number);
    });
  });
  return numbers.slice(0, 24);
}

function isPartUnlocked(part) {
  return Boolean(part);
}

function protectedPartNumber(part) {
  if (!part) return t("lockedPartNumber");
  const numbers = fullPartNumbers(part);
  if (part.record_type === "catalog_page" && !numbers.length) return `#${part.page_number}`;
  return isPartUnlocked(part) ? (numbers[0] || part.part_number) : t("lockedPartNumber");
}

function protectedPartNumbersText(part) {
  const numbers = fullPartNumbers(part);
  if (!numbers.length) return t("noPartNumbers");
  return isPartUnlocked(part) ? numbers.join(" · ") : t("lockedPartNumber");
}

function protectedMeta(part) {
  const label = part.record_type === "catalog_page" ? t("catalogPage") : t("oem");
  const value = part.record_type === "catalog_page" ? `#${part.page_number}` : protectedPartNumber(part);
  return `${label} ${value} · ${part.model}`;
}

function showPaymentStatus(message, mode = "info") {
  const existing = document.querySelector(".payment-toast");
  existing?.remove();
  document.body.insertAdjacentHTML("beforeend", `<div class="payment-toast ${mode}">${message}</div>`);
  window.setTimeout(() => document.querySelector(".payment-toast")?.remove(), 3200);
}

function escapeHtml(value) {
  return String(value || "").replace(/[&<>"']/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#39;"
  }[char]));
}

function localRecords(key) {
  try {
    return JSON.parse(localStorage.getItem(key) || "[]");
  } catch {
    return [];
  }
}

function saveLocalRecords(key, records) {
  localStorage.setItem(key, JSON.stringify(records));
}

function localUserId() {
  const key = "batalLocalUserId";
  let id = localStorage.getItem(key);
  if (!id) {
    id = `batal-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
    localStorage.setItem(key, id);
  }
  return id;
}

async function postJsonSafe(path, payload) {
  try {
    const response = await fetch(path, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Batal-User": localUserId()
      },
      body: JSON.stringify(payload)
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    return { ok: false, offline: true, error: error.message };
  }
}

async function syncAppOverview() {
  try {
    const response = await fetch("/api/app-overview", {
      headers: { "X-Batal-User": localUserId() }
    });
    if (!response.ok) return;
    const payload = await response.json();
    if (payload.profile && !localStorage.getItem("batalVehicleProfile")) {
      localStorage.setItem("batalVehicleProfile", JSON.stringify({
        vin: payload.profile.vin,
        generation: payload.profile.generation,
        year: payload.profile.year,
        trim: payload.profile.trim,
        engine: payload.profile.engine,
        transmission: payload.profile.transmission,
        color: payload.profile.color
      }));
    }
  } catch {
    // Offline web/app builds keep using local storage.
  }
}

function profileObjectFromForm(form) {
  return Object.fromEntries(
    Object.entries(Object.fromEntries(new FormData(form).entries()))
      .map(([key, value]) => [key, String(value || "").trim()])
  );
}

function renderVehicleProfile() {
  if (!vehicleProfileSummary) return;
  const profile = JSON.parse(localStorage.getItem("batalVehicleProfile") || "null");
  if (!profile) {
    vehicleProfileSummary.innerHTML = "<h3>لا توجد سيارة محفوظة</h3><p>أضف بيانات سيارتك لربط البحث والتوافق والصيانة بها.</p>";
    return;
  }
  vehicleProfileSummary.innerHTML = `
    <h3>${escapeHtml(profile.generation || "Y60")} · ${escapeHtml(profile.year || "غير محدد")}</h3>
    <div class="profile-facts">
      <span>VIN: <strong>${escapeHtml(profile.vin || "غير محدد")}</strong></span>
      <span>المحرك: <strong>${escapeHtml(profile.engine || "غير محدد")}</strong></span>
      <span>القير: <strong>${escapeHtml(profile.transmission || "غير محدد")}</strong></span>
      <span>الفئة: <strong>${escapeHtml(profile.trim || "غير محدد")}</strong></span>
      <span>اللون: <strong>${escapeHtml(profile.color || "غير محدد")}</strong></span>
    </div>
    <p>سيتم استخدام هذه البيانات لتخصيص نتائج التوافق والتنبيهات وطلبات القطع.</p>
  `;
}

function renderMaintenanceLog() {
  if (!maintenanceList) return;
  const records = localRecords("batalMaintenanceLog");
  if (!records.length) {
    maintenanceList.innerHTML = `<div class="internal-empty">لا توجد عمليات صيانة محفوظة بعد.</div>`;
    return;
  }
  maintenanceList.innerHTML = records.slice(0, 12).map((record) => `
    <article class="maintenance-record">
      <strong>${escapeHtml(record.service || "صيانة")}</strong>
      <span>${escapeHtml(record.date || "بدون تاريخ")} · العداد ${escapeHtml(record.odometer || "غير محدد")}</span>
      <p>${escapeHtml(record.workshop || "ورشة غير محددة")} · ${escapeHtml(record.cost || "0")} ر.س</p>
      <small>التنبيه القادم: ${escapeHtml(record.next || "غير محدد")}</small>
    </article>
  `).join("");
}

function aiCandidateParts(query, limit = 4) {
  const normalizedQuery = normalize(query);
  if (!normalizedQuery) return parts.slice(0, limit);
  return parts
    .filter((part) => matchesSearch(part, normalizedQuery) || normalize(displayName(part)).includes(normalizedQuery))
    .slice(0, limit);
}

function renderAiCandidates(target, query, leadText) {
  if (!target) return;
  const candidates = aiCandidateParts(query, 4);
  target.innerHTML = `
    <strong>${escapeHtml(leadText)}</strong>
    <div class="ai-candidates">
      ${candidates.length ? candidates.map((part) => `
        <button type="button" data-ai-part="${escapeHtml(part.part_number)}">
          <span>${escapeHtml(displayName(part))}</span>
          <small>${escapeHtml(protectedMeta(part))}</small>
        </button>
      `).join("") : "<p>لم تظهر نتائج قريبة. جرّب وصفاً أدق أو رقم قطعة.</p>"}
    </div>
  `;
}

function diagnosticKeywords(text) {
  const value = normalize(text);
  const findings = [];
  if (value.includes("تهريب") || value.includes("زيت")) findings.push("افحص الصوف، الجلود، وجه الغطاء، وجه الكارتير، ومستوى الزيت.");
  if (value.includes("حراره") || value.includes("رديتر") || value.includes("ماء")) findings.push("ابدأ بكلتش المروحة، الرديتر، بلف الحرارة، طرمبة الماء، وغطاء الرديتر.");
  if (value.includes("يرتج") || value.includes("رجفه")) findings.push("افحص كراسي المكينة، البواجي، الأسلاك، الكربريتر/البخاخات، والفاكيوم.");
  if (value.includes("قير") || value.includes("ينفض")) findings.push("افحص زيت القير، قواعد القير، الكلتش/الفحمات، والوصلات قبل تغيير القطع.");
  if (value.includes("ما تشتغل") || value.includes("لا تشتغل")) findings.push("افحص البطارية، السلف، الفيوزات، الطرمبة، الشرارة، والوقود.");
  return findings.length ? findings : ["الوصف عام. أضف صوت العطل، مكانه، متى يظهر، وهل يحدث مع البرودة أو الحرارة."];
}

function tireDiameter(size) {
  const match = String(size || "").toUpperCase().match(/(\d{3})\s*\/\s*(\d{2})\s*R\s*(\d{2})/);
  if (!match) return null;
  const width = Number(match[1]);
  const aspect = Number(match[2]);
  const rim = Number(match[3]);
  return (rim * 25.4) + (2 * width * (aspect / 100));
}

function updateTireCalculation() {
  const oldSize = document.getElementById("tireOld")?.value;
  const newSize = document.getElementById("tireNew")?.value;
  const result = document.getElementById("tireCalcResult");
  if (!result) return;
  const oldDiameter = tireDiameter(oldSize);
  const newDiameter = tireDiameter(newSize);
  if (!oldDiameter || !newDiameter) {
    result.textContent = "اكتب المقاسين بهذا الشكل: 265/70R16 و 285/75R16.";
    return;
  }
  const diff = ((newDiameter - oldDiameter) / oldDiameter) * 100;
  const shownSpeed = 100;
  const realSpeed = shownSpeed * (newDiameter / oldDiameter);
  result.textContent = `الفرق ${diff.toFixed(2)}%. عند قراءة 100 كم/س تكون السرعة الفعلية تقريباً ${realSpeed.toFixed(1)} كم/س.`;
}

function selectedPartRequestPlan() {
  const selected = document.querySelector(".request-plan.active")?.dataset.requestPlan || "basic";
  return partRequestPlans.find((plan) => plan.id === selected) || partRequestPlans[0];
}

function requestPlanLine(plan) {
  return t(plan.titleKey);
}

function collectPartRequest(form) {
  const data = Object.fromEntries(new FormData(form).entries());
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value || "").trim()]));
}

function buildPartRequestDraft(request, plan) {
  const typeLabel = t(`requestType${{
    oem: "Oem",
    manufacturer: "Manufacturer",
    aftermarket: "Aftermarket",
    used: "Used",
    nos: "Nos",
    any: "Any"
  }[request.part_type] || "Any"}`);
  const goalLabel = t(`requestGoal${{
    availability: "Availability",
    buy: "Buy",
    compare: "Compare",
    best_quality: "BestQuality",
    cheapest: "Cheapest"
  }[request.goal] || "Availability"}`);

  return [
    "السلام عليكم، أبحث عن القطعة التالية:",
    `السيارة: Nissan Patrol ${request.generation || "Y60"}`,
    request.year ? `سنة الصنع: ${request.year}` : "",
    request.vin ? `رقم الهيكل: ${request.vin}` : "",
    request.engine ? `المحرك: ${request.engine}` : "",
    request.transmission ? `القير: ${request.transmission}` : "",
    request.part_number ? `رقم القطعة: ${request.part_number}` : "",
    request.part_name ? `اسم القطعة: ${request.part_name}` : "",
    `نوع القطعة المطلوب: ${typeLabel}`,
    `هدف الطلب: ${goalLabel}`,
    `نوع الخدمة: ${requestPlanLine(plan)}`,
    request.notes ? `ملاحظات: ${request.notes}` : "",
    "فضلاً أرسل السعر، حالة القطعة، التوفر، مدة التجهيز، وتكلفة الشحن للسعودية إن وجدت."
  ].filter(Boolean).join("\n");
}

function updatePartRequestStatus(message, mode = "info", draft = "") {
  if (!partRequestStatus) return;
  partRequestStatus.className = `request-status ${mode}`;
  partRequestStatus.innerHTML = `
    <strong>${escapeHtml(message)}</strong>
    ${draft ? `<label><span>${escapeHtml(t("requestDraftTitle"))}</span><textarea readonly rows="8">${escapeHtml(draft)}</textarea></label>` : ""}
  `;
}

function savePartRequest(request, plan) {
  const draft = buildPartRequestDraft(request, plan);
  const record = {
    id: `REQ-${Date.now()}`,
    created_at: new Date().toISOString(),
    plan_id: plan.id,
    product_id: plan.productId,
    fee_sar: 0,
    currency: "SAR",
    status: "saved_locally",
    request,
    draft
  };
  const stored = JSON.parse(localStorage.getItem("batalPartRequests") || "[]");
  stored.unshift(record);
  localStorage.setItem("batalPartRequests", JSON.stringify(stored.slice(0, 50)));
  postJsonSafe("/api/part-requests", record).then((result) => {
    if (result.ok) {
      showPaymentStatus("تم حفظ الطلب محلياً ومزامنته مع قاعدة التطبيق", "success");
      loadPartRequestHistory();
    }
  });
  savedPartRequests = [record, ...savedPartRequests.filter((item) => item.id !== record.id)].slice(0, 50);
  renderPartRequestHistory();
  updatePartRequestStatus(t("requestSubmitted"), "success", draft);
}

function normalizeRemotePartRequest(row) {
  return {
    id: row.local_id || `DB-${row.id}`,
    created_at: row.created_at || new Date().toISOString(),
    plan_id: row.plan_id || "basic",
    product_id: row.product_id || "",
    fee_sar: Number(row.fee_sar || 0),
    currency: row.currency || "SAR",
    status: row.status || "saved",
    request: {
      generation: row.generation || "",
      year: row.year || "",
      vin: row.vin || "",
      engine: row.engine || "",
      transmission: row.transmission || "",
      part_number: row.part_number || "",
      part_name: row.part_name || "",
      part_type: row.part_type || "",
      goal: row.goal || "",
      notes: row.notes || ""
    },
    draft: row.draft || ""
  };
}

function mergeSavedRequests(localRequests, remoteRequests) {
  const merged = [];
  const seen = new Set();
  [...localRequests, ...remoteRequests].forEach((request) => {
    const key = request.id || `${request.created_at}-${request.draft}`;
    if (seen.has(key)) return;
    seen.add(key);
    merged.push(request);
  });
  return merged
    .sort((a, b) => String(b.created_at || "").localeCompare(String(a.created_at || "")))
    .slice(0, 50);
}

async function loadPartRequestHistory() {
  const localRequests = localRecords("batalPartRequests");
  try {
    const remote = await fetchFirstJson(["/api/part-requests"]);
    const remoteRequests = Array.isArray(remote.part_requests)
      ? remote.part_requests.map(normalizeRemotePartRequest)
      : [];
    savedPartRequests = mergeSavedRequests(localRequests, remoteRequests);
  } catch {
    savedPartRequests = localRequests;
  }
  renderPartRequestHistory();
}

async function loadServiceDirectories() {
  try {
    storeDirectory = await fetchFirstJson([
      "/api/stores",
      "data/store_directory.json",
      "ios/BatalAlDroob/BatalAlDroob/Web/data/store_directory.json"
    ]);
  } catch {
    storeDirectory = { verified_stores: [], categories: [] };
  }
  renderVerifiedStores();
}

function renderPartRequestHistory() {
  if (!partRequestHistory) return;
  if (!savedPartRequests.length) {
    partRequestHistory.innerHTML = `<p class="empty-state">${t("requestHistoryEmpty")}</p>`;
    return;
  }
  partRequestHistory.innerHTML = savedPartRequests.slice(0, 6).map((item) => {
    const request = item.request || {};
    const plan = partRequestPlans.find((entry) => entry.id === item.plan_id) || partRequestPlans[0];
    const title = request.part_name || request.part_number || item.id;
    const date = item.created_at ? new Date(item.created_at).toLocaleDateString(currentLang === "ar" ? "ar-SA" : "en-US") : "";
    return `
      <article class="request-history-card">
        <div>
          <em>${escapeHtml(date)} · ${escapeHtml(requestPlanLine(plan))}</em>
          <strong>${escapeHtml(title)}</strong>
          <span>${escapeHtml([request.generation, request.year, request.engine, request.transmission].filter(Boolean).join(" · ") || t("notSpecified"))}</span>
        </div>
        <button type="button" data-copy-request="${escapeHtml(item.id)}">${t("requestCopyDraft")}</button>
      </article>
    `;
  }).join("");
}

function storeDisplayName(store) {
  return currentLang === "ar"
    ? (store.name_ar || store.name_en || store.id)
    : (store.name_en || store.name_ar || store.id);
}

function storeSearchUrl(store) {
  const samplePart = selectedPartId && !String(selectedPartId).startsWith("CAT-") ? selectedPartId : "";
  const template = store.search_url_template || "";
  if (samplePart && template) return template.replace("{part_number}", encodeURIComponent(samplePart));
  return store.website || "#";
}

function renderVerifiedStores() {
  if (!verifiedStoresGrid) return;
  const stores = Array.isArray(storeDirectory.verified_stores) ? storeDirectory.verified_stores : [];
  if (!stores.length) {
    verifiedStoresGrid.innerHTML = `<p class="empty-state">${t("verifiedStoresEmpty")}</p>`;
    return;
  }
  verifiedStoresGrid.innerHTML = stores.map((store) => {
    const category = storeCategoryLabels[store.category]?.[currentLang] || store.category || "";
    const verification = store.verification?.evidence_ar || store.verification?.status || t("verified");
    return `
      <article class="verified-store-card">
        <div>
          <em>${escapeHtml(category)}</em>
          <strong>${escapeHtml(storeDisplayName(store))}</strong>
          <span>${t("storeVerification")}: ${escapeHtml(verification)}</span>
        </div>
        <div class="store-actions">
          ${store.website ? `<a href="${escapeHtml(store.website)}" target="_blank" rel="noopener">${t("storeOpenWebsite")}</a>` : ""}
          <a href="${escapeHtml(storeSearchUrl(store))}" target="_blank" rel="noopener">${t("storeSearchPart")}</a>
        </div>
      </article>
    `;
  }).join("");
}

function copyText(text) {
  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(text).then(() => showPaymentStatus(t("requestCopied"), "success"));
    return;
  }
  const textarea = document.createElement("textarea");
  textarea.value = text;
  document.body.appendChild(textarea);
  textarea.select();
  document.execCommand("copy");
  textarea.remove();
  showPaymentStatus(t("requestCopied"), "success");
}

function requestPaidAccess(action) {
  pendingPaidAction = action;
  showPaymentStatus(t("purchasePending"));
  completePaidAction();
}

function completePaidAction() {
  const action = pendingPaidAction;
  pendingPaidAction = null;
  if (!action) return;
  if (action.type === "unlock-number") {
    paidPartUnlocks.add(action.partId);
    showPaymentStatus(t("purchaseSuccess"), "success");
    renderDetails();
    renderParts();
    return;
  }
  if (action.type === "open-pdf" && action.url) {
    showPaymentStatus(t("purchaseSuccess"), "success");
    window.location.assign(action.url);
    return;
  }
  if (action.type === "submit-part-request" && action.request && action.plan) {
    showPaymentStatus(t("purchaseSuccess"), "success");
    savePartRequest(action.request, action.plan);
  }
}

window.BatalNativeStore = {
  receive(payload) {
    if (payload?.status === "success") {
      completePaidAction();
      return;
    }
    pendingPaidAction = null;
    const key = payload?.status === "cancelled" ? "purchaseCancelled" : "purchaseUnavailable";
    showPaymentStatus(t(key), payload?.status === "cancelled" ? "warning" : "error");
  },
  screenCaptureChanged(isCaptured) {
    const shield = document.getElementById("screenShield");
    if (!shield) return;
    shield.classList.toggle("active", Boolean(isCaptured));
  },
  screenshotTaken() {
    showPaymentStatus(t("captureBlocked"), "warning");
  }
};

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
        <div class="meta-line">${protectedMeta(part)}</div>
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
  const numbers = fullPartNumbers(part);
  const selected = selectedDiagramNumber && numbers.includes(selectedDiagramNumber)
    ? selectedDiagramNumber
    : (numbers[0] || part.part_number || part.catalog_id || "BATAL");
  const publicNumber = isPartUnlocked(part) ? selected : t("lockedPartNumber");
  const seed = Array.from(selected).reduce((sum, char, index) => sum + (char.charCodeAt(0) * (index + 3)), 0);
  const width = 90 + (seed % 78);
  const height = 38 + (seed % 46);
  const radius = 12 + (seed % 28);
  const notch = 18 + (seed % 34);
  const accent = ["#1f7a57", "#d4af37", "#2d6cdf", "#b5531b"][seed % 4];
  const secondary = ["#dfe9e5", "#f1d98a", "#e8edf7", "#f4dfd3"][seed % 4];
  const diagramKey = part.diagram_key || buildDiagramKey(numbers, part.part_number);
  const calloutLabelWidth = Math.max(98, Math.min(186, publicNumber.length * 9 + 34));
  const calloutX = 260 - calloutLabelWidth / 2;
  const calloutPositions = [
    { x: 58, y: 68, tx: 126, ty: 86 },
    { x: 394, y: 62, tx: 331, ty: 88 },
    { x: 76, y: 157, tx: 159, ty: 134 },
    { x: 408, y: 151, tx: 340, ty: 131 },
    { x: 198, y: 58, tx: 221, ty: 84 },
    { x: 316, y: 178, tx: 296, ty: 139 }
  ];
  const visibleCallouts = (numbers.length ? numbers : [selected]).slice(0, calloutPositions.length);
  const inactiveCallouts = visibleCallouts
    .filter((number) => number !== selected)
    .map((number, index) => {
      const point = calloutPositions[index % calloutPositions.length];
      const label = isPartUnlocked(part) ? number : `E${String((seed + index * 37) % 10000).padStart(4, "0")}`;
      const labelWidth = Math.max(54, Math.min(116, label.length * 8 + 20));
      return `
        <path class="callout-reference-line" d="M${point.x} ${point.y + 9} L${point.tx} ${point.ty}" />
        <rect class="callout-reference-pill" x="${point.x - labelWidth / 2}" y="${point.y - 10}" width="${labelWidth}" height="22" rx="11"/>
        <text class="callout-reference-text" x="${point.x}" y="${point.y + 6}" text-anchor="middle">${escapeHtml(label)}</text>
      `;
    }).join("");

  return `
    <svg viewBox="0 0 520 230" role="img" aria-label="${escapeHtml(t("generatedDiagramTitle"))}">
      <defs>
        <pattern id="grid-${diagramKey}" width="18" height="18" patternUnits="userSpaceOnUse">
          <path d="M18 0H0V18" fill="none" stroke="rgba(31,42,41,.14)" stroke-width="1"/>
        </pattern>
        <filter id="callout-glow-${diagramKey}" x="-40%" y="-40%" width="180%" height="180%">
          <feDropShadow dx="0" dy="0" stdDeviation="4" flood-color="#ef4444" flood-opacity="0.65"/>
        </filter>
      </defs>
      <rect x="16" y="16" width="488" height="198" rx="18" fill="rgba(246,246,239,.94)" stroke="rgba(31,42,41,.18)"/>
      <rect x="16" y="16" width="488" height="198" rx="18" fill="url(#grid-${diagramKey})" stroke="rgba(31,42,41,.18)"/>
      <path d="M72 ${122 - notch / 3} C128 ${60 + (seed % 22)} 174 ${152 - (seed % 18)} 226 ${104 + (seed % 12)} S332 ${58 + (seed % 28)} 444 ${118 - (seed % 20)}" fill="none" stroke="#8d948f" stroke-width="5" stroke-linecap="round"/>
      <rect x="${260 - width / 2}" y="${108 - height / 2}" width="${width}" height="${height}" rx="${Math.min(18, radius / 2)}" fill="${secondary}" stroke="#1f2a29" stroke-width="4"/>
      <rect class="callout-target-highlight" x="${260 - width / 2 - 9}" y="${108 - height / 2 - 9}" width="${width + 18}" height="${height + 18}" rx="${Math.min(22, radius / 2 + 7)}" fill="none" stroke="#ef4444" stroke-width="5" filter="url(#callout-glow-${diagramKey})"/>
      <circle cx="${260 - width / 2 + notch}" cy="108" r="${radius}" fill="#fff" stroke="#606b78" stroke-width="5"/>
      <circle cx="${260 + width / 2 - notch}" cy="108" r="${Math.max(10, radius - 8)}" fill="#fff" stroke="#1f2a29" stroke-width="4"/>
      <path d="M260 ${108 - height / 2 - 18}v-30M260 ${108 + height / 2 + 18}v30M${260 - width / 2 - 34} 108h-42M${260 + width / 2 + 34} 108h42" stroke="#1f2a29" stroke-width="3" stroke-dasharray="8 7"/>
      ${inactiveCallouts}
      <path class="callout-leader" d="M260 ${108 + height / 2 + 12} L260 166" stroke="#ef4444" stroke-width="4" stroke-linecap="round"/>
      <rect class="callout-label" x="${calloutX}" y="168" width="${calloutLabelWidth}" height="28" rx="14" fill="#ef4444" stroke="#fff7ed" stroke-width="2" filter="url(#callout-glow-${diagramKey})"/>
      <text x="260" y="43" text-anchor="middle" font-size="14" fill="#1f2a29">${escapeHtml(t("diagramNumber"))}: ${escapeHtml(diagramKey)}</text>
      <text class="callout-label-text" x="260" y="187" text-anchor="middle" font-size="15" fill="#fff" font-weight="900">${escapeHtml(publicNumber)}</text>
      <text x="80" y="196" text-anchor="middle" font-size="12" fill="#1f2a29">${escapeHtml(categoryLabel(part))}</text>
      <text x="438" y="196" text-anchor="middle" font-size="12" fill="#1f2a29">${escapeHtml(t("epcSource"))}</text>
    </svg>
  `;
}

function renderDetails() {
  const part = parts.find((item) => item.part_number === selectedPartId);
  if (!part) {
    detailPanel.innerHTML = `<div class="detail-empty">${t("noResults")}</div>`;
    return;
  }
  const realPrices = verifiedPrices(part);
  const numbers = fullPartNumbers(part);
  if (selectedDiagramNumber && !numbers.includes(selectedDiagramNumber)) {
    selectedDiagramNumber = null;
  }
  const activeDiagramNumber = selectedDiagramNumber || numbers[0] || "";
  const numbersUnlocked = isPartUnlocked(part);

  detailPanel.innerHTML = `
    <div class="detail-title">
      <h2>${displayName(part)}</h2>
      <span class="meta-line">${protectedMeta(part)}</span>
      <div class="badge-row">
        <span class="badge ${typeClass(part)}">${categoryLabel(part)}</span>
        <span class="badge ${rarityClass(part)}">${localizedValue(part.rarity)}</span>
        <span class="badge locked-badge">${t("paymentRequired")}</span>
      </div>
    </div>

    <div class="detail-section part-number-section">
      <h3>${t("fullPartNumbers")}</h3>
      <p class="detail-copy">${t("fullPartNumbersHint")}</p>
      <div class="part-number-list">
        ${numbers.length ? numbers.map((number, index) => `
          <button class="part-number-chip ${number === activeDiagramNumber ? "active" : ""}" type="button" data-diagram-number="${escapeHtml(number)}">
            ${numbersUnlocked ? escapeHtml(number) : `${t("lockedPartNumber")} ${index + 1}`}
          </button>
        `).join("") : `<span class="internal-empty">${t("noPartNumbers")}</span>`}
      </div>
    </div>

    <div class="diagram-tools">
      <h3>${t("generatedDiagramTitle")}</h3>
      <p>${t("generatedDiagramNote")}</p>
    </div>
    <div class="diagram">${diagramSvg(part)}</div>

    <div class="paywall-card">
      <div>
        <h3>${t("paywallTitle")}</h3>
        <p>${t("paywallText")}</p>
      </div>
      <div class="paywall-actions">
        ${numbers.length || part.record_type !== "catalog_page" ? `<button class="primary-action" type="button" data-paid-reveal="${partAccessId(part)}">${numbersUnlocked ? protectedPartNumbersText(part) : t("payUnlockNumbers")}</button>` : ""}
        ${part.source_pdf_path ? `<button class="secondary-action" type="button" data-paid-pdf="${pdfHref(part.source_pdf_path)}">${t("payOpenCatalog")} · ${t("page")} ${part.page_number}</button>` : ""}
      </div>
    </div>

    <div class="detail-section">
      <h3>${t("dbInfo")}</h3>
      <div class="info-grid">
        <div class="info-item"><span>${t("appearanceYears")}</span><strong>${yearsLabel(part)}</strong></div>
        <div class="info-item"><span>${t("engines")}</span><strong>${enginesLabel(part)}</strong></div>
        <div class="info-item"><span>${t("applicationDates")}</span><strong>${dateRangesLabel(part)}</strong></div>
        <div class="info-item"><span>${t("diagramNumber")}</span><strong>${escapeHtml(part.diagram_reference || part.diagram_key || t("notSpecified"))}</strong></div>
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
        ${realPrices.length ? realPrices.map((item) => `
          <div class="price-row">
            <div>
              <strong>${item.source}</strong>
              <span>${t("shippingIncluded")} · ${t("priceUpdatedAt")}: ${item.updated_at}</span>
              <a href="${item.url}" target="_blank" rel="noopener">${t("priceSource")}</a>
            </div>
            <b>${formatVerifiedMoney(item)}</b>
          </div>
        `).join("") : `<div class="internal-empty">${t("noVerifiedPrices")}</div>`}
      </div>
      <p class="price-disclaimer">${t("priceEstimateDisclaimer")}</p>
      ${renderPricingStoreOptions(part)}
    </div>

    <div class="detail-section">
      <h3>${t("catalogEvidence")}</h3>
      <div class="price-list">
        ${(part.evidence || []).map((item) => `
          <div class="price-row">
            <div>
              <strong>${item.source_id}</strong>
              <span>${t("year")} ${item.year} · ${t("page")} ${item.page}</span>
              <span>${isPartUnlocked(part) ? item.context : t("lockedPartNumber")}</span>
            </div>
          </div>
        `).join("")}
      </div>
      ${part.source_pdf_path ? `<button class="pdf-link" type="button" data-paid-pdf="${pdfHref(part.source_pdf_path)}">${t("payOpenCatalog")} · ${t("page")} ${part.page_number}</button>` : ""}
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
      ${renderFullCatalogSummary()}
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
  const manifestSummary = patrolCatalogDatabase?.summary || {};
  cards[0].textContent = catalog.part_count?.toLocaleString("en-US") || parts.length.toLocaleString("en-US");
  cards[1].textContent = (manifestSummary.total_files || catalogSearchIndex.stats?.length || catalog.source_count || 0).toLocaleString("en-US");
  cards[2].textContent = parts.filter((part) => (part.confidence || 0) < 70).length.toLocaleString("en-US");
  cards[3].textContent = (catalogSearchIndex.entries?.length || parts.reduce((sum, part) => sum + part.occurrence_count, 0)).toLocaleString("en-US");
}

function renderFullCatalogSummary() {
  const summary = patrolFullCatalogIndex?.summary || patrolCatalogDatabase?.summary || {};
  const files = Array.isArray(patrolFullCatalogIndex?.files) ? patrolFullCatalogIndex.files : [];
  const groups = files.reduce((acc, file) => {
    const generation = file.generation || "unknown";
    acc[generation] ||= { count: 0, years: new Set() };
    acc[generation].count += 1;
    (file.years || []).forEach((year) => acc[generation].years.add(year));
    return acc;
  }, {});
  const ordered = ["Y60", "Y61", "Y62", "Y63", "unknown"].filter((key) => groups[key]);
  const isArabic = currentLang === "ar";
  const title = isArabic ? "الكتالوجات الشاملة المدمجة" : "Integrated Full Catalogs";
  const uniqueLabel = isArabic ? "ملف فريد داخل التطبيق" : "unique files in app";
  const duplicatesLabel = isArabic ? "ملف مكرر تم استبعاده" : "duplicates excluded";
  const pagesLabel = isArabic ? "صفحة مفهرسة" : "indexed pages";
  const sortedLabel = isArabic ? "الفرز حسب الجيل والسنة" : "sorted by generation and year";
  const unknownLabel = isArabic ? "غير مصنف" : "Unclassified";
  return `
    <div class="catalog-full-summary">
      <h4>${title}</h4>
      <div class="catalog-full-stats">
        <span><strong>${Number(summary.unique_files || files.length || 0).toLocaleString("en-US")}</strong>${uniqueLabel}</span>
        <span><strong>${Number(summary.duplicate_files || 0).toLocaleString("en-US")}</strong>${duplicatesLabel}</span>
        <span><strong>${Number(summary.total_pages || 0).toLocaleString("en-US")}</strong>${pagesLabel}</span>
      </div>
      <div class="catalog-full-groups">
        ${ordered.map((generation) => {
          const group = groups[generation];
          return `
            <div>
              <strong>${generation === "unknown" ? unknownLabel : generation}</strong>
              <span>${group.count.toLocaleString("en-US")} PDF · ${yearRange([...group.years].sort())}</span>
            </div>
          `;
        }).join("")}
      </div>
      <p>${sortedLabel}: <code>catalog/patrol_full_unique</code></p>
    </div>
  `;
}

function yearRange(years = []) {
  if (!years.length) return t("notSpecified");
  if (years.length === 1) return years[0];
  return `${years[0]} - ${years[years.length - 1]}`;
}

function shortList(values = [], limit = 3) {
  if (!values.length) return t("notSpecified");
  const visible = values.slice(0, limit).join(", ");
  return values.length > limit ? `${visible} +${values.length - limit}` : visible;
}

function renderGenerationDatabaseStats() {
  const generations = patrolCatalogDatabase?.summary?.generations || {};
  document.querySelectorAll(".generation-card[data-generation]").forEach((card) => {
    const generation = card.dataset.generation;
    const info = generations[generation];
    card.querySelector(".generation-db-stats")?.remove();

    const stats = document.createElement("div");
    stats.className = "generation-db-stats";

    if (!info) {
      stats.innerHTML = `<span>${t("generationDbNoData")}</span>`;
      card.appendChild(stats);
      return;
    }

    stats.innerHTML = `
      <span>${t("generationDbFiles")}: <strong>${Number(info.file_count || 0).toLocaleString("en-US")}</strong></span>
      <span>${t("generationDbUnique")}: <strong>${Number(info.unique_file_count || 0).toLocaleString("en-US")}</strong></span>
      <span>${t("generationDbPages")}: <strong>${Number(info.total_pages || 0).toLocaleString("en-US")}</strong></span>
      <span>${t("generationDbYears")}: <strong>${yearRange(info.years || [])}</strong></span>
      <span>${t("generationDbEngines")}: <strong>${shortList(info.engines || [])}</strong></span>
    `;
    card.appendChild(stats);
  });
}

async function fetchFirstJson(paths) {
  let lastError = null;
  for (const path of paths) {
    try {
      const response = await fetch(path);
      if (response.ok) return response.json();
      lastError = new Error(`${path}: HTTP ${response.status}`);
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError || new Error("No JSON paths provided");
}

async function loadCatalog() {
  try {
    let response = await fetch("/api/catalog");
    if (!response.ok) {
      response = await fetch("data/y60_app_catalog.json");
    }
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    catalog = await response.json();
    const baseParts = Array.isArray(catalog.parts) ? catalog.parts : [];
    try {
      catalogSearchIndex = await fetchFirstJson([
        "catalog/search/catalog_search_index.json",
        "flutter_y60_catalog/assets/catalog/search/catalog_search_index.json"
      ]);
    } catch (indexError) {
      catalogSearchIndex = { entries: [], stats: [] };
      console.warn("Catalog page index unavailable", indexError);
    }
    try {
      patrolCatalogDatabase = await fetchFirstJson([
        "data/patrol_catalog_manifest.json",
        "ios/BatalAlDroob/BatalAlDroob/Web/data/patrol_catalog_manifest.json"
      ]);
    } catch (patrolDbError) {
      patrolCatalogDatabase = { summary: null, files: [] };
      console.warn("Patrol catalog database unavailable", patrolDbError);
    }
    try {
      patrolFullCatalogIndex = await fetchFirstJson([
        "data/patrol_full_catalog_files.json",
        "ios/BatalAlDroob/BatalAlDroob/Web/data/patrol_full_catalog_files.json"
      ]);
    } catch (fullCatalogError) {
      patrolFullCatalogIndex = { files: [], summary: patrolCatalogDatabase?.summary || null };
      console.warn("Full patrol catalog index unavailable", fullCatalogError);
    }
    try {
      partFitmentIndex = await fetchFirstJson([
        "data/part_fitment_index.json",
        "ios/BatalAlDroob/BatalAlDroob/Web/data/part_fitment_index.json"
      ]);
    } catch (fitmentError) {
      partFitmentIndex = { parts: {}, sources: {}, shared_fitment_candidates: [], pdfs_bundled: false };
      console.warn("Part fitment index unavailable", fitmentError);
    }
    parts = enrichPartsWithFitment(mergeCatalogEntries(baseParts, catalogSearchIndex), partFitmentIndex);
    await Promise.all([loadServiceDirectories(), loadPartRequestHistory()]);
  } catch (error) {
    catalog = { parts: fallbackParts, sources: [] };
    parts = fallbackParts;
    await Promise.all([loadServiceDirectories(), loadPartRequestHistory()]);
    console.warn("Using fallback catalog", error);
  }
  selectedPartId = parts[0]?.part_number || null;
  updateStats();
  renderGenerationDatabaseStats();
  renderSharedFitment();
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
  selectedDiagramNumber = null;
  renderParts();
});

detailPanel.addEventListener("click", (event) => {
  const revealButton = event.target.closest("[data-paid-reveal]");
  if (revealButton) {
    requestPaidAccess({ type: "unlock-number", partId: revealButton.dataset.paidReveal });
    return;
  }

  const pdfButton = event.target.closest("[data-paid-pdf]");
  if (pdfButton) {
    requestPaidAccess({ type: "open-pdf", url: pdfButton.dataset.paidPdf });
    return;
  }

  const diagramButton = event.target.closest("[data-diagram-number]");
  if (diagramButton) {
    selectedDiagramNumber = diagramButton.dataset.diagramNumber;
    renderDetails();
    return;
  }

  const button = event.target.closest("[data-wishlist]");
  if (!button) return;
  wishlist.add(button.dataset.wishlist);
  wishlistCount.textContent = wishlist.size;
  button.textContent = t("saved");
});

sharedFitmentGrid?.addEventListener("click", (event) => {
  const button = event.target.closest("[data-shared-part]");
  if (!button) return;
  selectedPartId = button.dataset.sharedPart;
  selectedDiagramNumber = null;
  activeModel = "Y60";
  activeFilter = "all";
  visibleLimit = 60;
  if (searchInput) searchInput.value = selectedPartId;
  document.querySelectorAll(".model-chip").forEach((item) => item.classList.toggle("active", item.dataset.model === "Y60"));
  document.querySelectorAll(".category-card").forEach((item) => item.classList.toggle("active", item.dataset.filter === "all"));
  renderParts();
  document.querySelector(".parts-panel")?.scrollIntoView({ behavior: "smooth", block: "start" });
});

document.querySelectorAll(".request-plan").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".request-plan").forEach((item) => item.classList.remove("active"));
    button.classList.add("active");
  });
});

partRequestForm?.addEventListener("submit", (event) => {
  event.preventDefault();
  const request = collectPartRequest(partRequestForm);
  if (!request.part_number && !request.part_name) {
    updatePartRequestStatus(t("requestRequired"), "error");
    return;
  }

  const plan = selectedPartRequestPlan();
  const draft = buildPartRequestDraft(request, plan);
  requestPaidAccess({
    type: "submit-part-request",
    productId: plan.productId,
    request,
    plan,
    confirmTitle: t("partRequestTitle"),
    confirmText: `${requestPlanLine(plan)}\n\n${draft}`
  });
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
  window.clearTimeout(searchDebounceTimer);
  searchDebounceTimer = window.setTimeout(() => {
    visibleLimit = 60;
    renderParts();
  }, 280);
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
    "part-request": '[data-section="part-request"]',
    "ai-hub": '[data-section="ai-hub"]',
    "my-car": '[data-section="my-car"]',
    "maintenance-log": '[data-section="maintenance-log"]',
    marketplace: '[data-section="marketplace"]',
    community: '[data-section="community"]',
    "pro-tools": '[data-section="pro-tools"]',
    "next-generation": '[data-section="next-generation"]',
    faults: '[data-section="faults"]',
    catalogs: '[data-section="catalogs"]',
    "shared-fitment": '[data-section="shared-fitment"]',
    "source-intake": '[data-section="source-intake"]',
    prices: '[data-section="prices"]',
    vision: '[data-section="vision"]',
    wishlist: ".detail-actions",
    contact: '[data-section="contact"]'
  };

  document.querySelector(targets[target] || ".topbar")?.scrollIntoView({ behavior: "smooth", block: "start" });
  setDockActive(target);
  document.getElementById("menuToggle")?.setAttribute("aria-expanded", "false");
  document.getElementById("menuPanel")?.classList.remove("open");
}

document.addEventListener("click", (event) => {
  const copyButton = event.target.closest("[data-copy-request]");
  if (copyButton) {
    const item = savedPartRequests.find((request) => request.id === copyButton.dataset.copyRequest);
    if (item?.draft) copyText(item.draft);
    return;
  }

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

vehicleProfileForm?.addEventListener("submit", (event) => {
  event.preventDefault();
  const profile = profileObjectFromForm(vehicleProfileForm);
  localStorage.setItem("batalVehicleProfile", JSON.stringify(profile));
  renderVehicleProfile();
  postJsonSafe("/api/vehicle-profile", profile).then((result) => {
    if (result.ok) showPaymentStatus("تم حفظ ملف السيارة ومزامنته مع قاعدة التطبيق", "success");
  });
  showPaymentStatus("تم حفظ ملف السيارة محلياً", "success");
});

maintenanceForm?.addEventListener("submit", (event) => {
  event.preventDefault();
  const profile = JSON.parse(localStorage.getItem("batalVehicleProfile") || "null");
  const record = {
    ...profileObjectFromForm(maintenanceForm),
    vin: profile?.vin || ""
  };
  const records = localRecords("batalMaintenanceLog");
  const savedRecord = { ...record, id: `MNT-${Date.now()}` };
  records.unshift(savedRecord);
  saveLocalRecords("batalMaintenanceLog", records.slice(0, 80));
  postJsonSafe("/api/maintenance", savedRecord).then((result) => {
    if (result.ok) showPaymentStatus("تمت مزامنة عملية الصيانة مع قاعدة التطبيق", "success");
  });
  maintenanceForm.reset();
  renderMaintenanceLog();
  showPaymentStatus("تمت إضافة عملية الصيانة", "success");
});

document.getElementById("aiImageInput")?.addEventListener("change", (event) => {
  const file = event.target.files?.[0];
  const target = document.getElementById("aiImageResult");
  if (!file) return;
  const keywords = file.name.replace(/\.[a-z0-9]+$/i, " ").replace(/[-_]+/g, " ");
  renderAiCandidates(target, keywords || "engine cooling electrical", `تم تجهيز الصورة: ${file.name}. النتائج التالية مرشحة من قاعدة الكتالوج إلى حين ربط نموذج التعرف من الصور.`);
});

document.getElementById("descriptionSearchButton")?.addEventListener("click", () => {
  const input = document.getElementById("descriptionSearchInput");
  const result = document.getElementById("descriptionSearchResult");
  const query = input?.value || "";
  const diagnostics = diagnosticKeywords(query);
  renderAiCandidates(result, query, `تحليل الوصف: ${diagnostics.join(" ")}`);
  if (query.trim().length > 1 && searchInput) {
    searchInput.value = query;
    visibleLimit = 60;
    renderParts();
  }
});

document.getElementById("soundDiagnosticButton")?.addEventListener("click", () => {
  const result = document.getElementById("soundDiagnosticResult");
  if (!result) return;
  result.innerHTML = `
    <strong>تقرير صوتي تجريبي</strong>
    <p>قبل تفعيل التحليل الحقيقي نحتاج نموذج صوتي أو API. الواجهة جاهزة لتسجيل الصوت وتصنيف احتمالات: بلف، كرسي ماكينة، جنزير، دفرنس، رولمان، سير، أو طرمبة ماء.</p>
  `;
});

document.getElementById("tireCalcButton")?.addEventListener("click", updateTireCalculation);

document.addEventListener("click", (event) => {
  const aiPart = event.target.closest("[data-ai-part]");
  if (!aiPart) return;
  selectedPartId = aiPart.dataset.aiPart;
  activeModel = "Y60";
  activeFilter = "all";
  if (searchInput) searchInput.value = selectedPartId;
  renderParts();
  document.querySelector(".parts-panel")?.scrollIntoView({ behavior: "smooth", block: "start" });
});

loadCatalog();
applyLanguage();
syncAppOverview().then(() => {
  renderVehicleProfile();
  renderMaintenanceLog();
});

document.body.insertAdjacentHTML("beforeend", `
  <div class="screen-shield" id="screenShield" aria-live="assertive">
    <div>
      <strong>${t("protectedContent")}</strong>
      <span>${t("captureBlocked")}</span>
    </div>
  </div>
`);

if ("serviceWorker" in navigator && ["http:", "https:"].includes(window.location.protocol)) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js").catch(() => {});
  });
}
