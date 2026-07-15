const basePath = "../study-saip-saher2030/";

const documents = [
  {
    title: "ملف التقديم النهائي لشبكة ساهر 2030",
    file: "saher2030_national_smart_network_saip_submission.pdf",
    path: "final-documents/saher2030_national_smart_network_saip_submission.pdf",
    type: "pdf",
    group: "final",
    size: "633 KB",
    priority: 1,
    description: "نسخة PDF النهائية لتقديم دراسة شبكة ساهر الوطنية الذكية.",
  },
  {
    title: "نسخة Word قابلة للتحرير لتقديم ساهر 2030",
    file: "saher2030_national_smart_network_saip_submission_editable.doc",
    path: "final-documents/saher2030_national_smart_network_saip_submission_editable.doc",
    type: "word",
    group: "final",
    size: "279 KB",
    priority: 2,
    description: "نسخة قابلة للتحرير من ملف تقديم SAIP.",
  },
  {
    title: "الملف العلمي Aman 2030",
    file: "aman2030_saip_scientific_dossier.pdf",
    path: "final-documents/aman2030_saip_scientific_dossier.pdf",
    type: "pdf",
    group: "final",
    size: "959 KB",
    priority: 3,
    description: "ملف PDF علمي موسع للدراسة.",
  },
  {
    title: "الملف العلمي Aman 2030 بصيغة Word",
    file: "aman2030_saip_scientific_dossier.docx",
    path: "final-documents/aman2030_saip_scientific_dossier.docx",
    type: "word",
    group: "final",
    size: "734 KB",
    priority: 4,
    description: "نسخة DOCX قابلة للتحرير من الملف العلمي.",
  },
  {
    title: "عرض HTML لتقديم ساهر 2030",
    file: "saher2030_national_smart_network_saip_submission.html",
    path: "final-documents/saher2030_national_smart_network_saip_submission.html",
    type: "data",
    group: "final",
    size: "279 KB",
    priority: 5,
    description: "نسخة HTML قابلة للعرض في المتصفح من ملف التقديم.",
  },
  {
    title: "عرض HTML للملف العلمي Aman 2030",
    file: "aman2030_saip_scientific_dossier.html",
    path: "final-documents/aman2030_saip_scientific_dossier.html",
    type: "data",
    group: "final",
    size: "354 KB",
    priority: 6,
    description: "نسخة HTML من الملف العلمي.",
  },
  {
    title: "Manifest شبكة ساهر الوطنية",
    file: "saher2030_national_smart_network_manifest.json",
    path: "final-documents/saher2030_national_smart_network_manifest.json",
    type: "data",
    group: "data",
    size: "3 KB",
    priority: 7,
    description: "بيانات وصفية لملف التقديم ومخرجاته.",
  },
  {
    title: "Manifest جودة Aman 2030",
    file: "aman2030_saip_quality_manifest.json",
    path: "final-documents/aman2030_saip_quality_manifest.json",
    type: "data",
    group: "data",
    size: "2.5 KB",
    priority: 8,
    description: "بيانات جودة ومراجعة للملف العلمي.",
  },
  {
    title: "تسليم Codex لدراسة Saher 2030",
    file: "saher2030-codex-handoff-2026-06-29.md",
    path: "supporting-docs/saher2030-codex-handoff-2026-06-29.md",
    type: "data",
    group: "support",
    size: "Markdown",
    priority: 9,
    description: "ملف تسليم يشرح سياق العمل ومخرجات الدراسة.",
  },
  {
    title: "سجل المحادثة",
    file: "chat-transcript-2026-06-29.md",
    path: "supporting-docs/chat-transcript-2026-06-29.md",
    type: "data",
    group: "support",
    size: "Markdown",
    priority: 10,
    description: "سجل نصي داعم لمسار إنتاج الدراسة.",
  },
  {
    title: "Manifest ملفات المحادثة",
    file: "conversation_files_manifest.json",
    path: "supporting-docs/conversation_files_manifest.json",
    type: "data",
    group: "support",
    size: "JSON",
    priority: 11,
    description: "قائمة JSON للملفات المرتبطة بالمحادثة.",
  },
  {
    title: "فهرس ملفات المحادثة",
    file: "conversation_files_manifest.md",
    path: "supporting-docs/conversation_files_manifest.md",
    type: "data",
    group: "support",
    size: "Markdown",
    priority: 12,
    description: "نسخة Markdown من فهرس ملفات المحادثة.",
  },
  {
    title: "سكربت بناء الدراسة",
    file: "build_aman2030_saip_study.mjs",
    path: "scripts/build_aman2030_saip_study.mjs",
    type: "data",
    group: "script",
    size: "JavaScript",
    priority: 13,
    description: "سكربت إعادة توليد ملفات الدراسة.",
  },
  {
    title: "Aman 2030 الصفحة 1",
    file: "aman2030_page1_fixed-01.png",
    path: "pdf-review-renders/aman2030_page1_fixed-01.png",
    type: "review",
    group: "review",
    size: "PNG",
    priority: 20,
    description: "لقطة مراجعة بصرية للصفحة الأولى.",
  },
  {
    title: "Aman 2030 الصفحة 12",
    file: "aman2030_page12_fixed-12.png",
    path: "pdf-review-renders/aman2030_page12_fixed-12.png",
    type: "review",
    group: "review",
    size: "PNG",
    priority: 21,
    description: "لقطة مراجعة بصرية للصفحة 12.",
  },
  {
    title: "Aman 2030 الصفحة 64",
    file: "aman2030_page64_fixed-64.png",
    path: "pdf-review-renders/aman2030_page64_fixed-64.png",
    type: "review",
    group: "review",
    size: "PNG",
    priority: 22,
    description: "لقطة مراجعة بصرية للصفحة 64.",
  },
  {
    title: "Saher 2030 الصفحة 1",
    file: "saher2030_fmt_page1-01.png",
    path: "pdf-review-renders/saher2030_fmt_page1-01.png",
    type: "review",
    group: "review",
    size: "PNG",
    priority: 23,
    description: "لقطة مراجعة بصرية من ملف ساهر 2030.",
  },
  {
    title: "Saher 2030 الصفحة 20",
    file: "saher2030_fmt_page20-20.png",
    path: "pdf-review-renders/saher2030_fmt_page20-20.png",
    type: "review",
    group: "review",
    size: "PNG",
    priority: 24,
    description: "لقطة مراجعة بصرية من ملف ساهر 2030.",
  },
  {
    title: "Saher 2030 الصفحة 45",
    file: "saher2030_fmt_page45-45.png",
    path: "pdf-review-renders/saher2030_fmt_page45-45.png",
    type: "review",
    group: "review",
    size: "PNG",
    priority: 25,
    description: "لقطة مراجعة بصرية من ملف ساهر 2030.",
  },
];

const labels = {
  pdf: "PDF",
  word: "Word",
  data: "بيانات",
  review: "مراجعة",
};

const state = {
  filter: "all",
  query: "",
  sort: "priority",
  selectedPath: documents[0].path,
};

const fileList = document.querySelector("#fileList");
const searchInput = document.querySelector("#searchInput");
const sortSelect = document.querySelector("#sortSelect");

function docUrl(doc) {
  return `${basePath}${doc.path}`;
}

function matchesFilter(doc) {
  if (state.filter === "all") return true;
  if (state.filter === "final") return doc.group === "final";
  return doc.type === state.filter || doc.group === state.filter;
}

function matchesSearch(doc) {
  if (!state.query) return true;
  const haystack = [doc.title, doc.file, doc.type, doc.group, doc.description].join(" ").toLowerCase();
  return haystack.includes(state.query.toLowerCase());
}

function visibleDocuments() {
  return [...documents]
    .filter(matchesFilter)
    .filter(matchesSearch)
    .sort((a, b) => {
      if (state.sort === "name") return a.title.localeCompare(b.title, "ar");
      if (state.sort === "type") return a.type.localeCompare(b.type) || a.priority - b.priority;
      return a.priority - b.priority;
    });
}

function renderMetrics() {
  document.querySelector("#totalFiles").textContent = documents.length;
  document.querySelector("#wordCount").textContent = documents.filter((doc) => doc.type === "word").length;
  document.querySelector("#pdfCount").textContent = documents.filter((doc) => doc.type === "pdf").length;
  document.querySelector("#dataCount").textContent = documents.filter((doc) => doc.type === "data").length;
  document.querySelector("#reviewCount").textContent = documents.filter((doc) => doc.type === "review").length;
}

function renderList() {
  const docs = visibleDocuments();
  document.querySelector("#visibleCount").textContent = `${docs.length} ملف`;
  fileList.innerHTML = "";

  if (!docs.length) {
    const empty = document.createElement("div");
    empty.className = "empty-state";
    empty.textContent = "لا توجد ملفات مطابقة للبحث أو التصفية الحالية.";
    fileList.append(empty);
    return;
  }

  docs.forEach((doc) => {
    const card = document.createElement("button");
    card.className = `file-card${doc.path === state.selectedPath ? " active" : ""}`;
    card.type = "button";
    card.dataset.path = doc.path;
    card.innerHTML = `
      <div class="file-row">
        <span class="badge ${doc.type}">${labels[doc.type]}</span>
        <span class="file-size">${doc.size}</span>
      </div>
      <strong>${doc.title}</strong>
      <p>${doc.description}</p>
      <span class="file-path">${doc.file}</span>
    `;
    fileList.append(card);
  });
}

function renderPreview() {
  const doc = documents.find((item) => item.path === state.selectedPath) || visibleDocuments()[0] || documents[0];
  state.selectedPath = doc.path;

  document.querySelector("#previewType").textContent = labels[doc.type];
  document.querySelector("#previewType").className = `type-tag ${doc.type}`;
  document.querySelector("#previewTitle").textContent = doc.title;
  document.querySelector("#previewDescription").textContent = doc.description;

  const url = docUrl(doc);
  document.querySelector("#openLink").href = url;
  document.querySelector("#downloadLink").href = url;

  document.querySelector("#previewMeta").innerHTML = `
    <div class="meta-item"><span>النوع</span><strong>${labels[doc.type]}</strong></div>
    <div class="meta-item"><span>الحجم</span><strong>${doc.size}</strong></div>
    <div class="meta-item"><span>المسار</span><strong>${doc.path}</strong></div>
  `;

  const box = document.querySelector("#previewBox");
  if (doc.type === "review") {
    box.innerHTML = `<img src="${url}" alt="${doc.title}" />`;
    return;
  }

  if (doc.type === "pdf" || doc.file.endsWith(".html") || doc.file.endsWith(".json") || doc.file.endsWith(".md")) {
    box.innerHTML = `<iframe title="${doc.title}" src="${url}"></iframe>`;
    return;
  }

  box.innerHTML = `
    <div class="no-preview">
      <div>
        <strong>لا توجد معاينة مباشرة لهذا النوع داخل المتصفح.</strong>
        <p>استخدم زر الفتح أو التحميل لعرض الملف في Word أو التطبيق المناسب.</p>
      </div>
    </div>
  `;
}

function render() {
  renderMetrics();
  renderList();
  renderPreview();
}

document.querySelectorAll("[data-filter]").forEach((button) => {
  button.addEventListener("click", () => {
    state.filter = button.dataset.filter;
    document.querySelectorAll("[data-filter]").forEach((item) => {
      item.classList.toggle("active", item === button);
    });
    const firstVisible = visibleDocuments()[0];
    if (firstVisible) state.selectedPath = firstVisible.path;
    render();
  });
});

fileList.addEventListener("click", (event) => {
  const card = event.target.closest(".file-card");
  if (!card) return;
  state.selectedPath = card.dataset.path;
  render();
});

searchInput.addEventListener("input", () => {
  state.query = searchInput.value.trim();
  const firstVisible = visibleDocuments()[0];
  if (firstVisible && !visibleDocuments().some((doc) => doc.path === state.selectedPath)) {
    state.selectedPath = firstVisible.path;
  }
  render();
});

sortSelect.addEventListener("change", () => {
  state.sort = sortSelect.value;
  render();
});

render();
