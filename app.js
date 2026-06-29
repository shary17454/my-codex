const products = [
  {
    id: "roof-box",
    name: "تركيب شنطة سقف للسيارة",
    category: "سيارات",
    difficulty: "متوسط",
    time: "45 دقيقة",
    icon: "🚗",
    description: "طريقة تثبيت شنطة السقف على القواعد بشكل متوازن وآمن قبل السفر.",
    tools: ["مفتاح ربط", "متر قياس", "قفازات"],
    warnings: ["تأكد من قدرة سقف السيارة على تحمل الوزن.", "لا تتجاوز السرعة الموصى بها من الشركة."],
    steps: [
      ["تجهيز القواعد", "ثبت قواعد السقف وتأكد أن المسافة بينها مناسبة لطول الشنطة.", "لا تشد المسامير بالكامل قبل ضبط المحاذاة."],
      ["رفع الشنطة", "ضع الشنطة فوق القواعد بمساعدة شخص آخر وحافظ على توازنها.", "تجنب رفعها وحدك إذا كانت ثقيلة."],
      ["تثبيت المشابك", "أغلق المشابك الداخلية حول القواعد وشدها بالتساوي.", "لا تترك أي مشبك غير مقفل."],
      ["اختبار الثبات", "حرّك الشنطة برفق للتأكد من عدم وجود اهتزاز ثم أعد فحص الشد بعد 10 دقائق قيادة.", ""]
    ]
  },
  {
    id: "led-light",
    name: "تركيب لمبة LED عالية للسيارة",
    category: "سيارات",
    difficulty: "متقدم",
    time: "30 دقيقة",
    icon: "💡",
    description: "استبدال لمبة السيارة بلمبة LED مع الحفاظ على اتجاه الإضاءة الصحيح.",
    tools: ["قفازات", "مفك صغير"],
    warnings: ["افصل السيارة قبل العمل.", "لا تلمس سطح اللمبة مباشرة."],
    steps: [
      ["فتح الغطاء", "افتح غطاء المصباح من الخلف وحدد مكان اللمبة القديمة.", ""],
      ["فصل الفيش", "افصل فيش الكهرباء بهدوء ثم حرر مشبك اللمبة.", "لا تسحب الأسلاك بقوة."],
      ["تركيب LED", "ضع اللمبة الجديدة بنفس الاتجاه وثبتها في مكانها.", "تأكد أن المروحة أو المشتت لا يلامس الغطاء."],
      ["تجربة الإضاءة", "شغّل الأنوار وافحص مستوى الإضاءة قبل إغلاق الغطاء.", ""]
    ]
  },
  {
    id: "phone-holder",
    name: "تركيب حامل جوال",
    category: "اكسسوارات",
    difficulty: "سهل",
    time: "10 دقائق",
    icon: "📱",
    description: "تثبيت حامل جوال داخل السيارة بطريقة لا تحجب الرؤية ولا تعيق القيادة.",
    tools: ["منديل تنظيف"],
    warnings: ["لا تثبته فوق الوسادة الهوائية.", "تأكد أنه لا يحجب الطريق."],
    steps: [
      ["اختيار المكان", "اختر سطحًا ثابتًا قريبًا من السائق ولا يؤثر على الرؤية.", ""],
      ["تنظيف السطح", "نظف مكان التثبيت وجففه جيدًا.", ""],
      ["تثبيت القاعدة", "اضغط القاعدة لمدة 20 ثانية حتى تلتصق أو تقفل آلية الشفط.", ""],
      ["ضبط الزاوية", "ضع الجوال واضبط الزاوية ثم تأكد من ثباته عند الاهتزاز.", ""]
    ]
  },
  {
    id: "air-pump",
    name: "استخدام منفاخ هواء محمول",
    category: "أجهزة",
    difficulty: "سهل",
    time: "8 دقائق",
    icon: "🧰",
    description: "تشغيل منفاخ الهواء المحمول وضبط ضغط الإطارات أو الكرات بأمان.",
    tools: ["وصلة الهواء", "مصدر طاقة"],
    warnings: ["لا تتجاوز الضغط المكتوب على الإطار.", "اترك الجهاز يبرد بعد الاستخدام الطويل."],
    steps: [
      ["توصيل الطاقة", "اشحن الجهاز أو وصله بمنفذ السيارة حسب نوعه.", ""],
      ["تركيب الخرطوم", "ثبت الخرطوم على صمام الإطار بإحكام.", ""],
      ["ضبط الضغط", "حدد قيمة الضغط المطلوبة من شاشة الجهاز.", "راجع الرقم الموصى به على باب السائق."],
      ["التشغيل والإيقاف", "شغل الجهاز وانتظر حتى يتوقف تلقائيًا أو يصل للضغط المطلوب.", ""]
    ]
  },
  {
    id: "camp-tent",
    name: "تركيب خيمة تخييم",
    category: "تخييم",
    difficulty: "متوسط",
    time: "25 دقيقة",
    icon: "⛺",
    description: "خطوات نصب خيمة تخييم صغيرة وتثبيتها ضد الهواء.",
    tools: ["أوتاد", "مطرقة مطاطية", "أعمدة الخيمة"],
    warnings: ["ابتعد عن مجرى السيول.", "ثبت الأوتاد باتجاه معاكس للشد."],
    steps: [
      ["اختيار الأرض", "اختر أرضًا مستوية ونظفها من الأحجار الحادة.", ""],
      ["فرد الخيمة", "افرد أرضية الخيمة وحدد اتجاه الباب بعيدًا عن الرياح.", ""],
      ["تركيب الأعمدة", "مرر الأعمدة في المسارات وارفع الهيكل تدريجيًا.", ""],
      ["تثبيت الأوتاد", "ثبت الزوايا والحبال بالأوتاد مع شد متوازن.", "لا تشد جهة واحدة بقوة كبيرة."],
      ["تركيب الغطاء", "ضع الغطاء الخارجي وثبته مع ترك فراغ للتهوية.", ""]
    ]
  },
  {
    id: "wall-shelf",
    name: "تركيب رف جداري بسيط",
    category: "أثاث",
    difficulty: "متوسط",
    time: "35 دقيقة",
    icon: "🪚",
    description: "تحديد موضع الرف وحفر الجدار ثم تثبيته بشكل مستقيم.",
    tools: ["دريل", "ميزان ماء", "قلم", "براغي وفيشر"],
    warnings: ["تأكد من عدم وجود تمديدات كهرباء أو ماء خلف الجدار.", "استخدم فيشر مناسب لنوع الجدار."],
    steps: [
      ["تحديد المكان", "ضع الرف على الجدار وحدد نقاط الحفر بالقلم.", ""],
      ["فحص الاستقامة", "استخدم ميزان الماء للتأكد أن العلامات مستقيمة.", ""],
      ["الحفر", "احفر بعمق مناسب ثم أدخل الفيشر في الثقوب.", "ارتد نظارة حماية أثناء الحفر."],
      ["تثبيت الرف", "ثبت الحاملات بالبراغي ثم ضع الرف وتأكد من ثباته.", ""]
    ]
  }
];

const state = {
  route: "home",
  query: "",
  selectedProductId: products[0].id,
  stepIndex: 0,
  favorites: new Set(JSON.parse(localStorage.getItem("favorites") || "[]")),
  chat: [
    { role: "user", text: "ما عرفت أركب البرغي" },
    { role: "bot", text: "صوّر مكان التركيب وتأكد من اتجاه القطعة قبل الشد." }
  ]
};

const app = document.getElementById("app");

function saveFavorites() {
  localStorage.setItem("favorites", JSON.stringify([...state.favorites]));
}

function productById(id) {
  return products.find((product) => product.id === id) || products[0];
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function setRoute(route) {
  state.route = route;
  document.querySelectorAll(".tab").forEach((tab) => {
    tab.classList.toggle("active", tab.dataset.route === route);
  });
  render();
}

function selectProduct(id) {
  state.selectedProductId = id;
  state.stepIndex = 0;
  setRoute("details");
}

function renderHome() {
  const categories = [
    ["سيارات", "🚗"],
    ["أدوات", "🛠"],
    ["أجهزة", "⚡"],
    ["تخييم", "⛺"],
    ["أثاث", "🪚"]
  ];

  app.innerHTML = `
    <section class="hero">
      <div class="hero-copy">
        <span class="premium-chip">دليل تركيب ذكي</span>
        <h2>ركّبها</h2>
        <p>اعرف طريقة تركيب واستخدام أي منتج خطوة بخطوة، من أول أداة إلى آخر اختبار.</p>
      </div>
      <div class="hero-panel">
        <div class="scan-card">
          <span class="scan-corner top"></span>
          <span class="scan-corner bottom"></span>
          <div class="scan-icon">⌁</div>
          <strong>جاهز للتصوير</strong>
          <small>واجهة Mock بدون كاميرا فعلية حاليًا</small>
        </div>
      </div>
      <div class="actions hero-actions">
        <button class="button primary" id="cameraButton" type="button">صوّر المنتج</button>
        <button class="button secondary on-dark" id="manualSearch" type="button">ابحث يدويًا</button>
      </div>
    </section>

    <section>
      <div class="section-title">
        <h2>أقسام سريعة</h2>
        <span>اختر المسار</span>
      </div>
      <div class="category-grid">
        ${categories.map(([category, icon]) => `
          <button class="category" data-category="${escapeHtml(category)}" type="button">
            <span>${escapeHtml(icon)}</span>
            <strong>${escapeHtml(category)}</strong>
          </button>
        `).join("")}
      </div>
    </section>

    <section class="list">
      <div class="section-title">
        <h2>الأكثر استخدامًا</h2>
        <span>${products.length} أدلة</span>
      </div>
      ${products.slice(0, 3).map(productCard).join("")}
    </section>
  `;

  document.getElementById("cameraButton").addEventListener("click", () => {
    state.query = "";
    setRoute("search");
  });
  document.getElementById("manualSearch").addEventListener("click", () => setRoute("search"));
  document.querySelectorAll("[data-category]").forEach((button) => {
    button.addEventListener("click", () => {
      state.query = button.dataset.category;
      setRoute("search");
    });
  });
  bindProductCards();
}

function productCard(product) {
  const isFavorite = state.favorites.has(product.id);
  return `
    <article class="card product-card" data-product-id="${escapeHtml(product.id)}">
      <div class="product-main">
        <div class="product-icon">${escapeHtml(product.icon)}</div>
        <div>
          <h3>${escapeHtml(product.name)}</h3>
          <div class="meta">
            <span class="pill">${escapeHtml(product.category)}</span>
            <span>${escapeHtml(product.difficulty)}</span>
            <span>${escapeHtml(product.time)}</span>
            <span>${escapeHtml(product.tools.length)} أدوات</span>
          </div>
        </div>
      </div>
      <button class="icon-button favorite-toggle" data-favorite-id="${escapeHtml(product.id)}" type="button" aria-label="تبديل المفضلة">${isFavorite ? "♥" : "♡"}</button>
    </article>
  `;
}

function bindProductCards() {
  document.querySelectorAll(".product-card").forEach((card) => {
    card.addEventListener("click", () => selectProduct(card.dataset.productId));
  });
  document.querySelectorAll(".favorite-toggle").forEach((button) => {
    button.addEventListener("click", (event) => {
      event.stopPropagation();
      toggleFavorite(button.dataset.favoriteId);
    });
  });
}

function toggleFavorite(id) {
  if (state.favorites.has(id)) {
    state.favorites.delete(id);
  } else {
    state.favorites.add(id);
  }
  saveFavorites();
  render();
}

function renderSearch() {
  const normalized = state.query.trim();
  const filtered = products.filter((product) => {
    const haystack = `${product.name} ${product.category} ${product.difficulty}`;
    return haystack.includes(normalized);
  });

  app.innerHTML = `
    <section class="page-heading">
      <h2>البحث</h2>
      <p>ابحث باسم المنتج أو التصنيف أو مستوى الصعوبة.</p>
      <input class="searchbox" id="searchInput" value="${escapeHtml(state.query)}" placeholder="مثال: لمبة، تخييم، متوسط" />
    </section>
    <section class="list">
      ${filtered.length ? filtered.map(productCard).join("") : `<div class="card empty">لا توجد نتائج مطابقة.</div>`}
    </section>
  `;

  document.getElementById("searchInput").addEventListener("input", (event) => {
    state.query = event.target.value;
    renderSearch();
  });
  bindProductCards();
}

function renderDetails() {
  const product = productById(state.selectedProductId);
  const isFavorite = state.favorites.has(product.id);
  app.innerHTML = `
    <section class="detail-hero">
      <div class="placeholder">${escapeHtml(product.icon)}</div>
      <div class="detail-copy">
        <div class="section-title">
          <h2>${escapeHtml(product.name)}</h2>
          <button class="icon-button glass" id="detailFavorite" type="button" aria-label="تبديل المفضلة">${isFavorite ? "♥" : "♡"}</button>
        </div>
        <p>${escapeHtml(product.description)}</p>
        <div class="metric-row">
          <span><strong>${escapeHtml(product.time)}</strong> الوقت</span>
          <span><strong>${escapeHtml(product.difficulty)}</strong> الصعوبة</span>
          <span><strong>${escapeHtml(product.tools.length)}</strong> أدوات</span>
        </div>
      </div>
    </section>

    <section class="detail-grid">
      <div class="card info-block">
        <h3>الأدوات المطلوبة</h3>
        <ul>${product.tools.map((tool) => `<li>${escapeHtml(tool)}</li>`).join("")}</ul>
      </div>
      <div class="card info-block warning">
        <h3>التحذيرات</h3>
        <ul>${product.warnings.map((warning) => `<li>${escapeHtml(warning)}</li>`).join("")}</ul>
      </div>
      <button class="button primary sticky-action" id="startSteps" type="button">ابدأ خطوات التركيب</button>
    </section>
  `;

  document.getElementById("detailFavorite").addEventListener("click", () => toggleFavorite(product.id));
  document.getElementById("startSteps").addEventListener("click", () => setRoute("steps"));
}

function renderSteps() {
  const product = productById(state.selectedProductId);
  const step = product.steps[state.stepIndex];
  const percent = ((state.stepIndex + 1) / product.steps.length) * 100;

  app.innerHTML = `
    <section class="card progress-card">
      <div class="section-title">
        <h2>${escapeHtml(product.name)}</h2>
        <span class="pill">${state.stepIndex + 1} من ${product.steps.length}</span>
      </div>
      <div class="progress-wrap" aria-label="نسبة التقدم"><div class="progress" style="width:${percent}%"></div></div>
    </section>
    <section class="step-card">
      <p class="step-number">الخطوة ${state.stepIndex + 1}</p>
      <h2>${escapeHtml(step[0])}</h2>
      <p>${escapeHtml(step[1])}</p>
      ${step[2] ? `<div class="card warning">${escapeHtml(step[2])}</div>` : ""}
      <div class="actions">
        <button class="button ghost" id="doneStep" type="button">تم</button>
        <button class="button primary" id="nextStep" type="button">${state.stepIndex === product.steps.length - 1 ? "إنهاء" : "الخطوة التالية"}</button>
      </div>
    </section>
    <button class="button secondary help-button" id="needHelp" type="button">أحتاج مساعدة</button>
  `;

  document.getElementById("doneStep").addEventListener("click", nextStep);
  document.getElementById("nextStep").addEventListener("click", nextStep);
  document.getElementById("needHelp").addEventListener("click", () => setRoute("help"));
}

function nextStep() {
  const product = productById(state.selectedProductId);
  if (state.stepIndex < product.steps.length - 1) {
    state.stepIndex += 1;
    renderSteps();
  } else {
    setRoute("details");
  }
}

function renderHelp() {
  app.innerHTML = `
    <section class="page-heading">
      <h2>المساعدة الذكية</h2>
      <p>محادثة تجريبية بدون ربط ذكاء اصطناعي حاليًا.</p>
    </section>
    <section class="chat">
      ${state.chat.map((message) => `<div class="bubble ${message.role === "user" ? "user" : "bot"}">${escapeHtml(message.text)}</div>`).join("")}
    </section>
    <form class="chat-input" id="chatForm">
      <input class="searchbox" id="chatInput" placeholder="اكتب سؤالك هنا" />
      <button class="button primary" type="submit">إرسال</button>
    </form>
  `;

  document.getElementById("chatForm").addEventListener("submit", (event) => {
    event.preventDefault();
    const input = document.getElementById("chatInput");
    const text = input.value.trim();
    if (!text) return;
    state.chat.push({ role: "user", text });
    state.chat.push({ role: "bot", text: "جرّب تصوير مكان التركيب وتأكد من اتجاه القطعة، ثم شدها تدريجيًا بدون قوة زائدة." });
    renderHelp();
  });
}

function renderFavorites() {
  const saved = products.filter((product) => state.favorites.has(product.id));
  app.innerHTML = `
    <section class="page-heading">
      <h2>المفضلة</h2>
      <p>الأدلة التي حفظتها للتجربة لاحقًا.</p>
    </section>
    <section class="list">
      ${saved.length ? saved.map(productCard).join("") : `<div class="card empty">لا توجد منتجات محفوظة حاليًا.</div>`}
    </section>
  `;
  bindProductCards();
}

function renderAccount() {
  app.innerHTML = `
    <section class="account-card">
      <p class="eyebrow">حالة المستخدم</p>
      <h2>مجاني</h2>
      <p>لا يوجد تسجيل دخول أو دفع حقيقي في هذا النموذج.</p>
    </section>
    <section class="premium-card">
      <p class="eyebrow">Premium مستقبلًا</p>
      <h2>نسخة أقوى عند الإطلاق</h2>
      <ul>
        <li>بدون إعلانات.</li>
        <li>خطوات أكثر تفصيلاً.</li>
        <li>حفظ غير محدود.</li>
        <li>دعم ذكي بالصور.</li>
      </ul>
      <button class="button primary" type="button" disabled>الترقية لاحقًا</button>
    </section>
  `;
}

function render() {
  if (state.route === "home") renderHome();
  if (state.route === "search") renderSearch();
  if (state.route === "details") renderDetails();
  if (state.route === "steps") renderSteps();
  if (state.route === "help") renderHelp();
  if (state.route === "favorites") renderFavorites();
  if (state.route === "account") renderAccount();
}

document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => setRoute(tab.dataset.route));
});

document.getElementById("favoritesShortcut").addEventListener("click", () => setRoute("favorites"));

render();
