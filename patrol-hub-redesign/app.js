const origin = "http://172.20.10.2:5005/";

const sections = [
  ["vehicle", "بطاقة السيارة", "بيانات السيارة الخاصة، رقم الهيكل، ومعلومات WGY60348567.", "WGY60348567"],
  ["engine", "المحرك والوقود", "المحرك TB42S، البلوك، الكربريتر، الوقود، والعادم.", "TB42S"],
  ["transmission", "القير والدبل", "ناقل الحركة، الدبل، الكلتش، وعمود الكردان.", "FS5R50A"],
  ["axle", "الدفرنسات والمحاور", "الدفرنسات، المحاور، التعليق، ومكونات الحركة.", "4WD"],
  ["brake", "الفرامل", "نظام الفرامل، الهوبات، المواسير، والقطع المرتبطة.", "Brake"],
  ["body", "البدي والخارجية", "الهيكل، الرفارف، الكبوت، الأبواب، الصدامات، والزجاج.", "Body"],
  ["interior", "الداخلية والفرش", "الطبلون، المقاعد، الأبواب، السقف، الأرضية، والديكورات.", "Interior"],
  ["electrical", "الكهرباء والظفيرة", "الأفياش، التوصيلات، اللمبات، العدادات، والمفاتيح.", "Electrical"],
  ["cooling_ac", "التكييف والثلاجات", "المكيف الأمامي والخلفي، الثلاجات، الهوايات، والوايرات.", "A/C"]
];

const catalogs = [
  ["WGY", "ملف WGY60348567", "ملف السيارة الخاص General Asia LHD Wagon TB42S SGL", "assets/catalog/pdfs/wgy60348567_vehicle_catalog.pdf", "6.5 MB"],
  ["1988", "Y60 1988", "بداية جيل Y60", "assets/catalog/pdfs/y60_1988.pdf", "12.0 MB"],
  ["1989", "Y60 1989", "كتالوج سنة 1989", "assets/catalog/pdfs/y60_1989.pdf", "12.0 MB"],
  ["1990", "Y60 1990", "كتالوج سنة 1990", "assets/catalog/pdfs/y60_1990.pdf", "12.0 MB"],
  ["1991", "Y60 1991", "مناسب لبيانات WGY60 10/1991", "assets/catalog/pdfs/y60_1991.pdf", "13.7 MB"],
  ["1992", "Y60 1992", "كتالوج موديل الاستمارة 1992", "assets/catalog/pdfs/y60_1992.pdf", "13.4 MB"],
  ["1993", "Y60 1993", "كتالوج سنة 1993", "assets/catalog/pdfs/y60_1993.pdf", "13.4 MB"],
  ["1994", "Y60 1994", "كتالوج سنة 1994", "assets/catalog/pdfs/y60_1994.pdf", "12.0 MB"],
  ["1995", "Y60 1995", "كتالوج سنة 1995", "assets/catalog/pdfs/y60_1995.pdf", "11.8 MB"],
  ["1996", "Y60 1996", "كتالوج سنة 1996", "assets/catalog/pdfs/y60_1996.pdf", "11.7 MB"],
  ["1997", "Y60 1997", "آخر سنوات جيل Y60", "assets/catalog/pdfs/y60_1997.pdf", "11.7 MB"]
];

const featuredResults = [
  { type: "ملف السيارة", title: "WGY60348567 Vehicle Catalog", text: "ملف السيارة الخاص، رقم الهيكل، السوق، المحرك، والقير.", tags: ["WGY60", "TB42S", "SGL"], link: "assets/catalog/pdfs/wgy60348567_vehicle_catalog.pdf" },
  { type: "محرك", title: "TB42S Engine & Fuel", text: "البلوك، الكربريتر، مضخة الوقود، والعادم ضمن كتالوجات Y60.", tags: ["Engine", "Fuel", "1991"], link: "assets/catalog/pdfs/y60_1991.pdf" },
  { type: "كهرباء", title: "Electrical & Harness", text: "الأفياش، الظفيرة، اللمبات، العدادات، والمفاتيح.", tags: ["Electrical", "Harness", "Y60"], link: "assets/catalog/pdfs/y60_1991.pdf" },
  { type: "قير ودبل", title: "FS5R50A Transmission", text: "ناقل الحركة اليدوي، الدبل، الكلتش، وأعمدة الحركة.", tags: ["FS5R50A", "4WD", "Clutch"], link: "assets/catalog/pdfs/y60_1991.pdf" },
  { type: "بدن", title: "Body Exterior", text: "الأبواب، الرفارف، الكبوت، الصدامات، والزجاج.", tags: ["Body", "Exterior", "Glass"], link: "assets/catalog/pdfs/y60_1991.pdf" },
  { type: "فرامل", title: "Brake System", text: "الهوبات، المواسير، الأسطوانات، والقطع المرتبطة بنظام الفرامل.", tags: ["Brake", "Axle", "Safety"], link: "assets/catalog/pdfs/y60_1991.pdf" }
];

const filterNames = ["الكل", "محرك", "كهرباء", "قير", "بدن", "فرامل", "WGY"];
let activeFilter = "الكل";

const byId = (id) => document.getElementById(id);
const makeUrl = (path) => new URL(path, origin).toString();

function renderFilters() {
  byId("filterRow").innerHTML = filterNames
    .map((name) => `<button class="chip ${name === activeFilter ? "is-active" : ""}" type="button" data-filter="${name}">${name}</button>`)
    .join("");
}

function resultMatches(item, query) {
  const haystack = [item.type, item.title, item.text, ...item.tags].join(" ").toLowerCase();
  const queryMatch = !query || haystack.includes(query);
  const filterMatch = activeFilter === "الكل" || haystack.includes(activeFilter.toLowerCase());
  return queryMatch && filterMatch;
}

function renderResults() {
  const query = byId("searchInput").value.trim().toLowerCase();
  const results = featuredResults.filter((item) => resultMatches(item, query));
  byId("resultsGrid").innerHTML = results.length
    ? results.map((item) => `
        <article class="result-card">
          <div>
            <span class="card-kicker">${item.type}</span>
            <h3>${item.title}</h3>
            <p>${item.text}</p>
          </div>
          <div>
            <div class="card-meta">${item.tags.map((tag) => `<span>${tag}</span>`).join("")}</div>
            <p><a class="open-link" href="${makeUrl(item.link)}" target="_blank" rel="noreferrer">فتح PDF</a></p>
          </div>
        </article>
      `).join("")
    : `<div class="empty-state">لا توجد نتيجة مطابقة. جرّب رقم القطعة بدون شرطة أو ابحث باسم المجموعة.</div>`;
}

function renderSections() {
  byId("sectionGrid").innerHTML = sections.map(([id, title, text, tag]) => `
    <article class="section-card" data-section="${id}">
      <span class="card-kicker">${tag}</span>
      <h3>${title}</h3>
      <p>${text}</p>
    </article>
  `).join("");
}

function renderCatalogs() {
  byId("catalogList").innerHTML = catalogs.map(([year, title, text, path, size]) => `
    <article class="catalog-card">
      <span class="year-badge">${year}</span>
      <div>
        <h3>${title}</h3>
        <p>${text}</p>
        <div class="card-meta"><span>${size}</span><span>PDF</span></div>
      </div>
      <a class="open-link" href="${makeUrl(path)}" target="_blank" rel="noreferrer">فتح</a>
    </article>
  `).join("");
}

document.addEventListener("click", (event) => {
  const chip = event.target.closest("[data-filter]");
  if (!chip) return;
  activeFilter = chip.dataset.filter;
  renderFilters();
  renderResults();
});

byId("searchInput").addEventListener("input", renderResults);

renderFilters();
renderResults();
renderSections();
renderCatalogs();
