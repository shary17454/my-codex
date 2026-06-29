const incidents = [
  {
    id: "hazmat-01",
    title: "تسرب حمولة خطرة على طريق سريع",
    location: "طريق الرياض - الدمام",
    time: "قبل 6 دقائق",
    severity: "critical",
    severityLabel: "حرجة",
    score: 94,
    type: "خطر مباشر",
    lead: "الدفاع المدني",
    impact: "مرتفع على الأرواح والحركة",
    action: "إغلاق جزئي وتوجيه فرق متخصصة",
    probability: 88,
    impactScore: 96,
    timeSensitivity: 91
  },
  {
    id: "dust-02",
    title: "انخفاض رؤية بسبب موجة غبار مفاجئة",
    location: "طريق القصيم السريع",
    time: "قبل 11 دقيقة",
    severity: "high",
    severityLabel: "عالية",
    score: 82,
    type: "بلاغ متعلق بالطقس",
    lead: "أمن الطرق",
    impact: "مرتفع على السلامة وسلاسة الحركة",
    action: "تنبيه مبكر وتخفيض سرعة الطريق",
    probability: 84,
    impactScore: 79,
    timeSensitivity: 87
  },
  {
    id: "schoolbus-03",
    title: "تعطل حافلة مدرسية على كتف الطريق",
    location: "مخرج شمال جدة",
    time: "قبل 18 دقيقة",
    severity: "high",
    severityLabel: "عالية",
    score: 78,
    type: "بلاغ يحتاج استجابة متعددة",
    lead: "المرور",
    impact: "حساسية عالية بسبب الركاب والموقع",
    action: "تأمين الموقع وإرسال نقل بديل",
    probability: 71,
    impactScore: 86,
    timeSensitivity: 82
  },
  {
    id: "debris-04",
    title: "جسم معدني على طريق فرعي",
    location: "طريق خدمة شرق المدينة",
    time: "قبل 27 دقيقة",
    severity: "medium",
    severityLabel: "متوسطة",
    score: 51,
    type: "عائق على الطريق",
    lead: "البلدية",
    impact: "محدود لكنه قابل للتصاعد",
    action: "تحقق ميداني وإزالة العائق",
    probability: 54,
    impactScore: 48,
    timeSensitivity: 53
  }
];

const incidentList = document.querySelector("#incidentList");
const severityFilter = document.querySelector("#severityFilter");

const caseTitle = document.querySelector("#caseTitle");
const riskScore = document.querySelector("#riskScore");
const caseType = document.querySelector("#caseType");
const caseLead = document.querySelector("#caseLead");
const caseImpact = document.querySelector("#caseImpact");
const caseAction = document.querySelector("#caseAction");
const probabilityMeter = document.querySelector("#probabilityMeter");
const impactMeter = document.querySelector("#impactMeter");
const timeMeter = document.querySelector("#timeMeter");
const probabilityValue = document.querySelector("#probabilityValue");
const impactValue = document.querySelector("#impactValue");
const timeValue = document.querySelector("#timeValue");

let selectedId = incidents[0].id;

function renderIncidents() {
  const filter = severityFilter.value;
  const visibleIncidents = incidents.filter((incident) => {
    return filter === "all" || incident.severity === filter;
  });

  incidentList.innerHTML = "";

  visibleIncidents.forEach((incident) => {
    const button = document.createElement("button");
    button.className = `incident ${selectedId === incident.id ? "selected" : ""}`;
    button.type = "button";
    button.dataset.id = incident.id;
    button.innerHTML = `
      <div class="incident-top">
        <span class="severity ${incident.severity}">${incident.severityLabel}</span>
        <strong>${incident.score}</strong>
      </div>
      <h3>${incident.title}</h3>
      <div class="incident-meta">
        <span>${incident.location}</span>
        <span>${incident.time}</span>
      </div>
    `;
    incidentList.append(button);
  });
}

function setCase(incidentId) {
  const incident = incidents.find((item) => item.id === incidentId) ?? incidents[0];
  selectedId = incident.id;

  caseTitle.textContent = incident.title;
  riskScore.textContent = incident.score;
  caseType.textContent = incident.type;
  caseLead.textContent = incident.lead;
  caseImpact.textContent = incident.impact;
  caseAction.textContent = incident.action;

  probabilityMeter.value = incident.probability;
  impactMeter.value = incident.impactScore;
  timeMeter.value = incident.timeSensitivity;
  probabilityValue.textContent = `${incident.probability}%`;
  impactValue.textContent = `${incident.impactScore}%`;
  timeValue.textContent = `${incident.timeSensitivity}%`;

  riskScore.style.background = incident.severity === "critical" ? "#f9dddd" : "#fde6d8";
  riskScore.style.color = incident.severity === "critical" ? "#8d201f" : "#904013";

  renderIncidents();
}

incidentList.addEventListener("click", (event) => {
  const selectedIncident = event.target.closest(".incident");
  if (!selectedIncident) return;
  setCase(selectedIncident.dataset.id);
});

severityFilter.addEventListener("change", () => {
  const filter = severityFilter.value;
  const nextIncident = incidents.find((incident) => filter === "all" || incident.severity === filter);
  if (nextIncident && !incidents.some((incident) => incident.id === selectedId && (filter === "all" || incident.severity === filter))) {
    setCase(nextIncident.id);
    return;
  }
  renderIncidents();
});

renderIncidents();
