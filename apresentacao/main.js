if (typeof gsap === "undefined") {
  document.documentElement.classList.remove("js");
  throw new Error("GSAP não carregou");
}

gsap.registerPlugin(ScrollTrigger, ScrollToPlugin);

const sections = gsap.utils.toArray("main section");
const indexEl = document.querySelector("#section-index");
const labelEl = document.querySelector("#section-label");

let current = 0;
let reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function updateChrome(index) {
  current = index;
  const section = sections[index];
  indexEl.textContent = String(index + 1).padStart(2, "0");
  labelEl.textContent = section.dataset.label;
}

function go(index) {
  const nextIndex = gsap.utils.clamp(0, sections.length - 1, index);
  const offset = document.querySelector(".topbar").offsetHeight + 8;
  gsap.to(window, {
    duration: reduceMotion ? 0 : 0.75,
    ease: "power2.inOut",
    scrollTo: { y: sections[nextIndex], offsetY: offset }
  });
}

sections.forEach((section, index) => {
  ScrollTrigger.create({
    trigger: section,
    start: "top 55%",
    end: "bottom 55%",
    onToggle: (self) => {
      if (self.isActive) updateChrome(index);
    }
  });
});

const scaleTo = gsap.quickTo(".progress-bar", "scaleX", { duration: 0.2, ease: "power1.out" });

ScrollTrigger.create({
  start: 0,
  end: "max",
  onUpdate: (self) => scaleTo(self.progress)
});

window.addEventListener("keydown", (event) => {
  const tag = document.activeElement?.tagName;
  if (tag === "INPUT" || tag === "TEXTAREA") return;
  if (event.key === "ArrowDown" || event.key === "ArrowRight" || event.key === "PageDown") {
    event.preventDefault();
    go(current + 1);
  }
  if (event.key === "ArrowUp" || event.key === "ArrowLeft" || event.key === "PageUp") {
    event.preventDefault();
    go(current - 1);
  }
});

updateChrome(0);

const motion = gsap.matchMedia();

motion.add(
  {
    reduce: "(prefers-reduced-motion: reduce)",
    allow: "(prefers-reduced-motion: no-preference)",
    desktop: "(min-width: 901px)"
  },
  (context) => {
    const { reduce, desktop } = context.conditions;
    reduceMotion = Boolean(reduce);

    if (reduce) {
      gsap.set(".prefade, .rise, .card, .term-line", { autoAlpha: 1, y: 0, x: 0 });
      return;
    }

    const hero = gsap.timeline({ defaults: { ease: "power3.out" } });
    hero
      .fromTo(".hero .kicker", { autoAlpha: 0, y: 16 }, { autoAlpha: 1, y: 0, duration: 0.45 })
      .fromTo(".hero h1", { autoAlpha: 0, y: 28 }, { autoAlpha: 1, y: 0, duration: 0.7 }, "-=0.2")
      .fromTo(".hero .lead", { autoAlpha: 0, y: 18 }, { autoAlpha: 1, y: 0, duration: 0.5 }, "-=0.4")
      .fromTo(".hero .meta", { autoAlpha: 0, y: 14 }, { autoAlpha: 1, y: 0, duration: 0.45 }, "-=0.3")
      .fromTo(".facts", { autoAlpha: 0, y: 20 }, { autoAlpha: 1, y: 0, duration: 0.55 }, "-=0.25");

    gsap.utils.toArray(".rise").forEach((element) => {
      gsap.fromTo(element,
        { autoAlpha: 0, y: 24 },
        {
          autoAlpha: 1,
          y: 0,
          duration: 0.7,
          ease: "power3.out",
          scrollTrigger: {
            trigger: element,
            start: "top 88%",
            toggleActions: "play none none none"
          }
        }
      );
    });

    gsap.set(".card:not(.scenario)", { y: 20 });

    ScrollTrigger.batch(".card:not(.scenario)", {
      start: "top 90%",
      once: true,
      onEnter: (batch) => {
        gsap.to(batch, {
          autoAlpha: 1,
          y: 0,
          duration: 0.65,
          stagger: 0.08,
          ease: "power3.out",
          overwrite: true
        });
      }
    });

    gsap.utils.toArray(".scenario").forEach((scenario) => {
      const lines = scenario.querySelectorAll(".term-line");
      gsap.timeline({
        scrollTrigger: {
          trigger: scenario,
          start: "top 86%",
          toggleActions: "play none none none"
        }
      })
        .fromTo(scenario, { autoAlpha: 0, y: 20 }, { autoAlpha: 1, y: 0, duration: 0.55, ease: "power3.out" })
        .fromTo(lines, { autoAlpha: 0, y: 8 }, { autoAlpha: 1, y: 0, duration: 0.28, stagger: 0.05, ease: "power2.out" }, "-=0.15");
    });

    const track = document.querySelector(".track");
    gsap.to(".packet", {
      x: () => (desktop ? track.offsetWidth - 10 : 0),
      y: () => (desktop ? 0 : track.offsetHeight - 10),
      duration: 1.35,
      ease: "power1.inOut",
      repeat: -1,
      repeatDelay: 0.3,
      repeatRefresh: true,
      scrollTrigger: {
        trigger: ".cluster",
        start: "top 80%",
        toggleActions: "play pause resume pause"
      }
    });
  }
);
