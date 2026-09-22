gsap.registerPlugin(ScrollTrigger);

const panels = gsap.utils.toArray(".panel");
const dots = gsap.utils.toArray(".dots button");
const progress = document.querySelector(".progress span");
const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function sectionIndex() {
  return Math.min(
    panels.length - 1,
    Math.max(0, Math.round(window.scrollY / window.innerHeight))
  );
}

function goTo(index) {
  const i = Math.max(0, Math.min(panels.length - 1, index));
  window.scrollTo({ top: i * window.innerHeight, behavior: reduce ? "auto" : "smooth" });
}

dots.forEach((btn, i) => btn.addEventListener("click", () => goTo(i)));

document.addEventListener("keydown", (e) => {
  if (e.key === "ArrowDown" || e.key === "PageDown" || e.key === " ") {
    e.preventDefault();
    goTo(sectionIndex() + 1);
  }
  if (e.key === "ArrowUp" || e.key === "PageUp") {
    e.preventDefault();
    goTo(sectionIndex() - 1);
  }
});

ScrollTrigger.create({
  start: 0,
  end: "max",
  onUpdate: () => {
    const i = sectionIndex();
    const p = panels.length === 1 ? 0 : i / (panels.length - 1);
    gsap.set(progress, { scaleX: p });
    dots.forEach((d, n) => d.classList.toggle("is-on", n === i));
  },
});

const mm = gsap.matchMedia();

mm.add("(prefers-reduced-motion: reduce)", () => {
  gsap.set(".panel *", { clearProps: "transform,opacity,visibility" });
});

mm.add("(prefers-reduced-motion: no-preference)", () => {
  const intro = gsap.timeline({ defaults: { ease: "power3.out" } });
  intro.fromTo("#s0 .kicker", { y: 16, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 0.5 });
  intro.fromTo(
    ".word",
    { yPercent: 24, autoAlpha: 0 },
    { yPercent: 0, autoAlpha: 1, duration: 0.85 },
    0.06
  );
  intro.fromTo("#s0 .lead", { y: 18, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 0.65 }, 0.18);

  function reveal(trigger, targets, vars = {}) {
    const els = gsap.utils.toArray(targets);
    const play = () =>
      gsap.to(els, {
        y: 0,
        autoAlpha: 1,
        duration: 0.7,
        stagger: vars.stagger ?? 0.08,
        ease: "power3.out",
        overwrite: true,
      });
    const hide = () =>
      gsap.to(els, {
        y: vars.y ?? 32,
        autoAlpha: 0,
        duration: 0.35,
        overwrite: true,
      });
    gsap.set(els, { y: vars.y ?? 32, autoAlpha: 0 });
    ScrollTrigger.create({
      trigger,
      start: "top 80%",
      end: "bottom 15%",
      onEnter: play,
      onEnterBack: play,
      onLeave: hide,
      onLeaveBack: hide,
    });
  }

  reveal("#s1", "#s1 .kicker, #s1 h2, #s1 .body, #s1 .kv-row", { stagger: 0.1 });
  reveal("#s2", "#s2 .kicker, #s2 h2, #s2 .card", { stagger: 0.12 });
  reveal("#s3", "#s3 .kicker, #s3 h2, #s3 .uses li", { stagger: 0.08 });
  reveal("#s4", "#s4 .kicker, #s4 h2, #s4 .bar-wrap, #s4 .body", { stagger: 0.1 });
  reveal("#s5", "#s5 .kicker, #s5 h2, #s5 .node, #s5 .arrow, #s5 .lab-cap", { stagger: 0.07 });
  reveal("#s6", "#s6 .kicker, #s6 h2, #s6 .body, #s6 .end-hint", { stagger: 0.1 });

  gsap.set("#s4 .bar span", { scaleX: 0 });
  ScrollTrigger.create({
    trigger: "#s4",
    start: "top 65%",
    onEnter: () =>
      gsap.to("#s4 .bar span", {
        scaleX: 1,
        duration: 1,
        stagger: 0.18,
        ease: "power2.out",
        overwrite: true,
      }),
    onLeaveBack: () => gsap.to("#s4 .bar span", { scaleX: 0, duration: 0.3, overwrite: true }),
  });
});
