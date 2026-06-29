const storageKey = "ask-people-questions-v2";
const maxExtraOptions = 4;

const makeOption = (label, votes = 0) => ({
  id: crypto.randomUUID(),
  label,
  votes,
});

const seedQuestions = [
  {
    id: crypto.randomUUID(),
    title: "أشتري كامري هايبرد أم سوناتا سمارت؟",
    details: "الاستخدام يومي داخل الرياض، وأهم شيء الاعتمادية وتكلفة البنزين بعد ثلاث سنوات.",
    category: "سيارات",
    duration: "3 أيام",
    createdAt: Date.now() - 1000 * 60 * 26,
    closesAt: Date.now() + 1000 * 60 * 60 * 55,
    options: [makeOption("كامري هايبرد", 64), makeOption("سوناتا سمارت", 39), makeOption("أزيرا مستعملة", 12)],
    comments: ["الكامري أوفر على المدى الطويل.", "إذا تهمك المواصفات الداخلية السوناتا أفضل."],
    selectedOptionId: null,
    saved: false,
    closed: false,
  },
  {
    id: crypto.randomUUID(),
    title: "أي جوال أفضل للتصوير والسفر؟",
    details: "أحتاج بطارية قوية، تصوير ليلي، وفيديو ثابت أثناء التنقل.",
    category: "تقنية",
    duration: "24 ساعة",
    createdAt: Date.now() - 1000 * 60 * 54,
    closesAt: Date.now() + 1000 * 60 * 60 * 18,
    options: [makeOption("iPhone 16 Pro", 88), makeOption("Galaxy S25 Ultra", 73)],
    comments: ["الفيديو في الآيفون ثابت جدًا.", "الزوم في الجالكسي يخدم السفر أكثر."],
    selectedOptionId: null,
    saved: true,
    closed: false,
  },
  {
    id: crypto.randomUUID(),
    title: "مطعم مناسب لعشاء عائلي في الرياض؟",
    details: "نحتاج مكان هادئ وفيه خيارات مناسبة للأطفال وحجز سهل.",
    category: "مطاعم",
    duration: "24 ساعة",
    createdAt: Date.now() - 1000 * 60 * 110,
    closesAt: Date.now() - 1000 * 60 * 10,
    options: [makeOption("سولتيرا", 21), makeOption("لوسين", 34), makeOption("ميراكي", 9)],
    comments: ["لوسين أهدأ للعائلة.", "سولتيرا ممتاز إذا تبغون أطباق متنوعة."],
    selectedOptionId: null,
    saved: false,
    closed: true,
  },
];

const state = {
  filter: "الكل",
  sort: "hot",
  search: "",
  questions: loadQuestions(),
};

const questionList = document.querySelector("#questionList");
const template = document.querySelector("#questionTemplate");
const questionForm = document.querySelector("#questionForm");
const extraOptions = document.querySelector("#extraOptions");
const addOptionButton = document.querySelector("#addOption");
const searchInput = document.querySelector("#searchInput");

function loadQuestions() {
  const saved = localStorage.getItem(storageKey);
  if (!saved) return seedQuestions;

  try {
    return JSON.parse(saved).map(normalizeQuestion);
  } catch {
    return seedQuestions;
  }
}

function normalizeQuestion(question) {
  return {
    details: "",
    duration: "24 ساعة",
    closesAt: question.createdAt + 1000 * 60 * 60 * 24,
    saved: false,
    closed: false,
    ...question,
  };
}

function saveQuestions() {
  localStorage.setItem(storageKey, JSON.stringify(state.questions));
}

function totalVotes(question) {
  return question.options.reduce((sum, option) => sum + option.votes, 0);
}

function totalComments() {
  return state.questions.reduce((sum, question) => sum + question.comments.length, 0);
}

function formatTime(createdAt) {
  const minutes = Math.max(1, Math.round((Date.now() - createdAt) / 60000));
  if (minutes < 60) return `قبل ${minutes} د`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `قبل ${hours} س`;
  return `قبل ${Math.round(hours / 24)} يوم`;
}

function remainingTime(question) {
  if (question.closed || question.closesAt <= Date.now()) return "مغلق";
  const hours = Math.max(1, Math.round((question.closesAt - Date.now()) / 3600000));
  if (hours < 24) return `ينتهي خلال ${hours} س`;
  return `ينتهي خلال ${Math.round(hours / 24)} يوم`;
}

function getWinner(question) {
  return [...question.options].sort((a, b) => b.votes - a.votes)[0];
}

function cleanComparisonItems(formData) {
  return [formData.get("optionA"), formData.get("optionB"), ...formData.getAll("extraOption")]
    .map((label) => label.trim())
    .filter(Boolean);
}

function hasDuplicateItems(items) {
  const normalized = items.map((item) => item.toLowerCase());
  return new Set(normalized).size !== normalized.length;
}

function matchesSearch(question) {
  if (!state.search) return true;
  const text = [
    question.title,
    question.details,
    question.category,
    ...question.options.map((option) => option.label),
    ...question.comments,
  ]
    .join(" ")
    .toLowerCase();
  return text.includes(state.search.toLowerCase());
}

function visibleQuestions() {
  return [...state.questions]
    .filter((question) => state.filter === "الكل" || question.category === state.filter)
    .filter(matchesSearch)
    .filter((question) => state.sort !== "saved" || question.saved)
    .sort((a, b) => {
      if (state.sort === "new" || state.sort === "saved") return b.createdAt - a.createdAt;
      return totalVotes(b) + b.comments.length * 4 - (totalVotes(a) + a.comments.length * 4);
    });
}

function updateMetrics() {
  document.querySelector("#metricQuestions").textContent = state.questions.length;
  document.querySelector("#metricVotes").textContent = state.questions.reduce((sum, question) => sum + totalVotes(question), 0);
  document.querySelector("#metricComments").textContent = totalComments();
}

function render() {
  updateMetrics();
  questionList.innerHTML = "";
  const questions = visibleQuestions();

  if (!questions.length) {
    const empty = document.createElement("div");
    empty.className = "empty-state";
    empty.textContent = "لا توجد أسئلة مطابقة الآن.";
    questionList.append(empty);
    return;
  }

  questions.forEach((question) => {
    const card = template.content.firstElementChild.cloneNode(true);
    const isClosed = question.closed || question.closesAt <= Date.now();
    const winner = getWinner(question);

    card.dataset.id = question.id;
    card.classList.toggle("closed", isClosed);
    card.querySelector(".category").textContent = question.category;
    card.querySelector(".status-tag").textContent = isClosed ? "مغلق" : "نشط";
    card.querySelector(".time").textContent = formatTime(question.createdAt);
    card.querySelector("h3").textContent = question.title;
    card.querySelector(".question-details").textContent = question.details;
    card.querySelector(".question-details").hidden = !question.details;
    card.querySelector(".vote-count").textContent = `${totalVotes(question)} صوت`;
    card.querySelector(".save-toggle").textContent = question.saved ? "محفوظ" : "حفظ";

    const optionsWrap = card.querySelector(".poll-options");
    const votes = Math.max(totalVotes(question), 1);

    question.options.forEach((option) => {
      const percent = Math.round((option.votes / votes) * 100);
      const optionEl = document.createElement("div");
      optionEl.className = `poll-option${question.selectedOptionId === option.id ? " selected" : ""}`;
      optionEl.style.setProperty("--percent", `${percent}%`);
      optionEl.innerHTML = `
        <span class="poll-fill" aria-hidden="true"></span>
        <button type="button" data-option-id="${option.id}" ${isClosed ? "disabled" : ""}>
          <span>${option.label}</span>
          <strong>${percent}%</strong>
        </button>
      `;
      optionsWrap.append(optionEl);
    });

    const detailPanel = card.querySelector(".detail-panel");
    detailPanel.innerHTML = `
      <div><strong>المدة</strong><span>${question.duration}</span></div>
      <div><strong>الحالة</strong><span>${remainingTime(question)}</span></div>
      <div><strong>العناصر</strong><span>${question.options.length} عناصر</span></div>
      <div><strong>العنصر المتقدم</strong><span>${winner ? winner.label : "لا يوجد"}</span></div>
      <button class="ghost-btn close-question" type="button">${isClosed ? "إعادة فتح" : "إغلاق التصويت"}</button>
    `;

    const comments = card.querySelector(".comments");
    question.comments.forEach((comment) => {
      const item = document.createElement("div");
      item.className = "comment";
      item.textContent = comment;
      comments.append(item);
    });

    questionList.append(card);
  });
}

function setFilter(category) {
  state.filter = category;
  document.querySelectorAll("[data-category]").forEach((button) => {
    button.classList.toggle("active", button.dataset.category === category);
  });
  render();
}

function setSort(sort) {
  state.sort = sort;
  document.querySelectorAll("[data-sort]").forEach((button) => {
    button.classList.toggle("active", button.dataset.sort === sort);
  });
  render();
}

function addExtraOptionField(value = "") {
  if (extraOptions.children.length >= maxExtraOptions) return;
  const label = document.createElement("label");
  label.className = "extra-option";
  label.innerHTML = `
    <span>عنصر إضافي</span>
    <div class="option-line">
      <input name="extraOption" type="text" maxlength="45" placeholder="عنصر آخر للمقارنة" value="${value}" />
      <button class="ghost-btn remove-option" type="button" aria-label="حذف العنصر">حذف</button>
    </div>
  `;
  extraOptions.append(label);
  addOptionButton.disabled = extraOptions.children.length >= maxExtraOptions;
}

document.querySelectorAll("[data-category]").forEach((button) => {
  button.addEventListener("click", () => setFilter(button.dataset.category));
});

document.querySelectorAll("[data-sort]").forEach((button) => {
  button.addEventListener("click", () => setSort(button.dataset.sort));
});

searchInput.addEventListener("input", () => {
  state.search = searchInput.value.trim();
  render();
});

addOptionButton.addEventListener("click", () => addExtraOptionField());

extraOptions.addEventListener("click", (event) => {
  const removeButton = event.target.closest(".remove-option");
  if (!removeButton) return;
  removeButton.closest(".extra-option").remove();
  addOptionButton.disabled = extraOptions.children.length >= maxExtraOptions;
});

questionList.addEventListener("click", (event) => {
  const voteButton = event.target.closest("[data-option-id]");
  const toggleButton = event.target.closest(".comment-toggle");
  const detailsButton = event.target.closest(".details-toggle");
  const saveButton = event.target.closest(".save-toggle");
  const closeButton = event.target.closest(".close-question");
  const card = event.target.closest(".question-card");
  if (!card) return;

  const question = state.questions.find((item) => item.id === card.dataset.id);
  if (!question) return;

  if (toggleButton) {
    card.classList.toggle("show-comments");
    return;
  }

  if (detailsButton) {
    card.classList.toggle("show-details");
    return;
  }

  if (saveButton) {
    question.saved = !question.saved;
    saveQuestions();
    render();
    return;
  }

  if (closeButton) {
    question.closed = !(question.closed || question.closesAt <= Date.now());
    if (!question.closed && question.closesAt <= Date.now()) {
      question.closesAt = Date.now() + 1000 * 60 * 60 * 24;
    }
    saveQuestions();
    render();
    return;
  }

  if (!voteButton || question.closed || question.closesAt <= Date.now()) return;

  const nextOption = question.options.find((item) => item.id === voteButton.dataset.optionId);
  if (!nextOption) return;

  if (question.selectedOptionId) {
    const previousOption = question.options.find((item) => item.id === question.selectedOptionId);
    if (previousOption) previousOption.votes = Math.max(0, previousOption.votes - 1);
  }

  nextOption.votes += 1;
  question.selectedOptionId = nextOption.id;
  saveQuestions();
  render();
});

questionList.addEventListener("submit", (event) => {
  event.preventDefault();
  const form = event.target.closest(".comment-form");
  const card = event.target.closest(".question-card");
  const input = form.querySelector("input");
  const text = input.value.trim();
  if (!text) return;

  const question = state.questions.find((item) => item.id === card.dataset.id);
  question.comments.unshift(text);
  input.value = "";
  saveQuestions();
  render();
});

questionForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const formData = new FormData(questionForm);
  const comparisonItems = cleanComparisonItems(formData);
  const duration = formData.get("questionDuration");
  const hoursByDuration = { "24 ساعة": 24, "3 أيام": 72, "أسبوع": 168 };

  if (comparisonItems.length < 2) {
    questionForm.reportValidity();
    return;
  }

  if (hasDuplicateItems(comparisonItems)) {
    alert("اكتب عناصر مختلفة للمقارنة بدون تكرار.");
    return;
  }

  const newQuestion = {
    id: crypto.randomUUID(),
    title: formData.get("questionText").trim(),
    details: formData.get("questionDetails").trim(),
    category: formData.get("questionCategory"),
    duration,
    createdAt: Date.now(),
    closesAt: Date.now() + 1000 * 60 * 60 * hoursByDuration[duration],
    options: comparisonItems.map((label) => makeOption(label)),
    comments: [],
    selectedOptionId: null,
    saved: false,
    closed: false,
  };

  state.questions.unshift(newQuestion);
  state.filter = "الكل";
  state.sort = "new";
  state.search = "";
  saveQuestions();
  questionForm.reset();
  extraOptions.innerHTML = "";
  addOptionButton.disabled = false;
  searchInput.value = "";
  setFilter("الكل");
  setSort("new");
  document.querySelector(".question-list").scrollIntoView({ behavior: "smooth", block: "start" });
});

document.querySelector("#focusAsk").addEventListener("click", () => {
  document.querySelector("#askPanel").scrollIntoView({ behavior: "smooth", block: "start" });
  document.querySelector("#questionText").focus({ preventScroll: true });
});

render();
