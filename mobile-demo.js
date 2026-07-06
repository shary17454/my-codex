const screens = Array.from(document.querySelectorAll(".app-screen"));
const navButtons = Array.from(document.querySelectorAll("[data-nav]"));
const historyStack = ["home"];

function setScreen(name, push = true) {
  const target = name === "paywall" ? "detail" : name;
  screens.forEach((screen) => {
    screen.classList.toggle("active", screen.dataset.screen === target);
  });
  navButtons.forEach((button) => {
    button.classList.toggle("active", button.dataset.nav === target);
  });
  if (push && historyStack[historyStack.length - 1] !== target) {
    historyStack.push(target);
  }
  if (name === "paywall") {
    document.getElementById("paywall")?.scrollIntoView({ behavior: "smooth", block: "center" });
  }
}

document.addEventListener("click", (event) => {
  const jump = event.target.closest("[data-jump]");
  if (jump) {
    setScreen(jump.dataset.jump);
    return;
  }

  const nav = event.target.closest("[data-nav]");
  if (nav) {
    setScreen(nav.dataset.nav);
    return;
  }

  const back = event.target.closest("[data-back]");
  if (back) {
    if (back.dataset.back) {
      setScreen(back.dataset.back);
      return;
    }
    historyStack.pop();
    setScreen(historyStack[historyStack.length - 1] || "home", false);
    return;
  }

  const unlock = event.target.closest("[data-unlock]");
  if (unlock) {
    unlock.textContent = "تم الدفع";
    unlock.disabled = true;
    document.querySelector(".unlocked-result")?.removeAttribute("hidden");
    document.querySelector(".unlocked-result")?.scrollIntoView({ behavior: "smooth", block: "center" });
  }
});
