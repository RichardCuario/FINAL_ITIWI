const menuButton = document.querySelector('.menu-button');
const navigation = document.querySelector('.site-header nav');

menuButton?.addEventListener('click', () => {
  const isOpen = menuButton.getAttribute('aria-expanded') === 'true';
  menuButton.setAttribute('aria-expanded', String(!isOpen));
  navigation?.classList.toggle('is-open', !isOpen);
});

navigation?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => {
    menuButton?.setAttribute('aria-expanded', 'false');
    navigation.classList.remove('is-open');
  });
});

const mockupCarousel = document.querySelector('[data-mockup-carousel]');

if (mockupCarousel) {
  const slides = [...mockupCarousel.querySelectorAll('.mockup-slide')];
  const dotsContainer = mockupCarousel.querySelector('.mockup-dots');
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let activeIndex = 0;
  let rotationTimer;

  const dots = slides.map((slide, index) => {
    const dot = document.createElement('button');
    dot.className = 'mockup-dot';
    dot.type = 'button';
    dot.setAttribute('aria-label', `Show ${slide.querySelector('img').alt}`);
    dot.addEventListener('click', () => {
      showSlide(index);
      startRotation();
    });
    dotsContainer.append(dot);
    return dot;
  });

  slides.forEach((slide, index) => {
    slide.addEventListener('click', () => {
      if (index === activeIndex) return;
      showSlide(index);
      startRotation();
    });
  });

  function showSlide(index) {
    activeIndex = (index + slides.length) % slides.length;
    slides.forEach((slide, slideIndex) => {
      let offset = (slideIndex - activeIndex + slides.length) % slides.length;
      if (offset > Math.floor(slides.length / 2)) offset -= slides.length;
      const distance = Math.abs(offset);
      const previousOffset = slide.dataset.offset;
      const isWrapping = previousOffset !== undefined && Math.abs(offset - Number(previousOffset)) > 3;
      slide.classList.toggle('is-wrapping', isWrapping);
      slide.style.setProperty('--offset', String(offset));
      slide.style.setProperty('--scale', String([1, .8, .62, .48][distance]));
      slide.style.setProperty('--slide-opacity', String([1, .95, .78, .6][distance]));
      slide.style.setProperty('--layer', String(4 - distance));
      slide.dataset.offset = String(offset);
      if (isWrapping) window.requestAnimationFrame(() => slide.classList.remove('is-wrapping'));
      const isActive = slideIndex === activeIndex;
      slide.classList.toggle('is-active', isActive);
      slide.setAttribute('aria-hidden', String(!isActive));
      dots[slideIndex].classList.toggle('is-active', isActive);
      if (isActive) dots[slideIndex].setAttribute('aria-current', 'true');
      else dots[slideIndex].removeAttribute('aria-current');
    });
  }

  function stopRotation() {
    window.clearInterval(rotationTimer);
    rotationTimer = undefined;
  }

  function startRotation() {
    stopRotation();
    if (reducedMotion.matches || document.hidden || mockupCarousel.matches(':hover') || mockupCarousel.contains(document.activeElement)) return;
    rotationTimer = window.setInterval(() => showSlide(activeIndex + 1), 4000);
  }

  mockupCarousel.querySelector('[data-carousel-prev]').addEventListener('click', () => {
    showSlide(activeIndex - 1);
    startRotation();
  });
  mockupCarousel.querySelector('[data-carousel-next]').addEventListener('click', () => {
    showSlide(activeIndex + 1);
    startRotation();
  });
  mockupCarousel.addEventListener('mouseenter', stopRotation);
  mockupCarousel.addEventListener('mouseleave', startRotation);
  mockupCarousel.addEventListener('focusin', stopRotation);
  mockupCarousel.addEventListener('focusout', startRotation);
  document.addEventListener('visibilitychange', startRotation);
  reducedMotion.addEventListener('change', startRotation);

  showSlide(0);
  mockupCarousel.classList.add('is-ready');
  startRotation();
}
