// Shared calendar for admin date inputs. The input remains the source of truth.
(function () {
  const monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];
  const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  let input = null;
  let calendar = null;
  let viewYear = 0;
  let viewMonth = 0;
  let activeDate = '';

  function useNativePicker() {
    return window.matchMedia('(hover: none) and (pointer: coarse)').matches;
  }

  function dateParts(value) {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value || '');
    if (!match) return null;
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const date = new Date(Date.UTC(year, month - 1, day));
    return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 &&
      date.getUTCDate() === day ? { year, month: month - 1, day } : null;
  }

  function dateValue(year, month, day) {
    return `${String(year).padStart(4, '0')}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  }

  function todayValue() {
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone: 'Asia/Manila', year: 'numeric', month: '2-digit', day: '2-digit'
    }).formatToParts(new Date());
    const values = Object.fromEntries(parts.map(part => [part.type, part.value]));
    return `${values.year}-${values.month}-${values.day}`;
  }

  function allowed(value) {
    if (!input) return false;
    return (!input.min || value >= input.min) && (!input.max || value <= input.max);
  }

  function closeCalendar() {
    if (input) {
      input.setAttribute('aria-expanded', 'false');
      input.removeAttribute('aria-controls');
    }
    calendar?.remove();
    input = null;
    calendar = null;
    activeDate = '';
  }

  function choose(value) {
    if (!input || (value && !allowed(value))) return;
    const target = input;
    const changed = target.value !== value;
    target.value = value;
    closeCalendar();
    target.focus({ preventScroll: true });
    if (changed) {
      target.dispatchEvent(new Event('input', { bubbles: true }));
      target.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  function shiftMonth(amount) {
    const month = new Date(Date.UTC(viewYear, viewMonth + amount, 1));
    viewYear = month.getUTCFullYear();
    viewMonth = month.getUTCMonth();
    const current = dateParts(activeDate) || dateParts(todayValue());
    const lastDay = new Date(Date.UTC(viewYear, viewMonth + 1, 0)).getUTCDate();
    activeDate = dateValue(viewYear, viewMonth, Math.min(current.day, lastDay));
    renderCalendar();
    input?.focus({ preventScroll: true });
  }

  function positionCalendar() {
    if (!calendar || !input || !input.isConnected) return closeCalendar();
    const rect = input.getBoundingClientRect();
    const width = Math.min(316, window.innerWidth - 16);
    calendar.style.width = `${width}px`;
    calendar.style.left = `${Math.max(8, Math.min(rect.left, window.innerWidth - width - 8))}px`;
    const above = window.innerHeight - rect.bottom < calendar.offsetHeight + 6 && rect.top > window.innerHeight - rect.bottom;
    calendar.style.top = above
      ? `${Math.max(8, rect.top - calendar.offsetHeight - 6)}px`
      : `${rect.bottom + 6}px`;
  }

  function renderCalendar() {
    if (!calendar || !input) return;
    calendar.replaceChildren();
    const header = document.createElement('div');
    header.className = 'admin-calendar-header';
    const previous = document.createElement('button');
    previous.type = 'button';
    previous.className = 'admin-calendar-nav';
    previous.setAttribute('aria-label', 'Previous month');
    previous.textContent = '‹';
    previous.addEventListener('click', () => shiftMonth(-1));
    const title = document.createElement('strong');
    title.textContent = `${monthNames[viewMonth]} ${viewYear}`;
    const next = document.createElement('button');
    next.type = 'button';
    next.className = 'admin-calendar-nav';
    next.setAttribute('aria-label', 'Next month');
    next.textContent = '›';
    next.addEventListener('click', () => shiftMonth(1));
    header.append(previous, title, next);
    calendar.appendChild(header);

    const grid = document.createElement('div');
    grid.className = 'admin-calendar-grid';
    weekdays.forEach(label => {
      const day = document.createElement('span');
      day.className = 'admin-calendar-weekday';
      day.textContent = label;
      grid.appendChild(day);
    });
    const firstWeekday = new Date(Date.UTC(viewYear, viewMonth, 1)).getUTCDay();
    const daysInMonth = new Date(Date.UTC(viewYear, viewMonth + 1, 0)).getUTCDate();
    const today = todayValue();
    const cellCount = Math.ceil((firstWeekday + daysInMonth) / 7) * 7;
    for (let index = 0; index < cellCount; index++) {
      const dayNumber = index - firstWeekday + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        const blank = document.createElement('span');
        blank.className = 'admin-calendar-blank';
        grid.appendChild(blank);
        continue;
      }
      const value = dateValue(viewYear, viewMonth, dayNumber);
      const day = document.createElement('button');
      day.type = 'button';
      day.className = 'admin-calendar-day';
      day.textContent = dayNumber;
      day.dataset.date = value;
      day.setAttribute('aria-label', `${weekdays[index % 7]}, ${monthNames[viewMonth]} ${dayNumber}, ${viewYear}`);
      day.setAttribute('aria-pressed', String(input.value === value));
      if (input.value === value) day.classList.add('is-selected');
      if (today === value) day.classList.add('is-today');
      if (activeDate === value) day.classList.add('is-active');
      if (!allowed(value)) day.disabled = true;
      day.addEventListener('click', () => choose(value));
      grid.appendChild(day);
    }
    calendar.appendChild(grid);

    const footer = document.createElement('div');
    footer.className = 'admin-calendar-footer';
    const clear = document.createElement('button');
    clear.type = 'button';
    clear.textContent = 'Clear';
    clear.addEventListener('click', () => choose(''));
    const todayButton = document.createElement('button');
    todayButton.type = 'button';
    todayButton.textContent = 'Today';
    todayButton.disabled = !allowed(today);
    todayButton.addEventListener('click', () => choose(today));
    footer.append(clear, todayButton);
    calendar.appendChild(footer);
    positionCalendar();
  }

  function openCalendar(target) {
    if (target.disabled || target.readOnly) return;
    if (input === target) return closeCalendar();
    closeCalendar();
    input = target;
    const selected = dateParts(target.value) || dateParts(todayValue());
    viewYear = selected.year;
    viewMonth = selected.month;
    activeDate = target.value || todayValue();
    calendar = document.createElement('div');
    calendar.className = 'admin-calendar';
    calendar.id = 'admin-calendar-popup';
    calendar.setAttribute('role', 'dialog');
    calendar.setAttribute('aria-label', `Choose ${target.getAttribute('aria-label') || 'date'}`);
    document.body.appendChild(calendar);
    target.setAttribute('aria-expanded', 'true');
    target.setAttribute('aria-controls', calendar.id);
    renderCalendar();
  }

  function moveActive(days) {
    const current = dateParts(activeDate) || dateParts(todayValue());
    const next = new Date(Date.UTC(current.year, current.month, current.day + days));
    activeDate = dateValue(next.getUTCFullYear(), next.getUTCMonth(), next.getUTCDate());
    viewYear = next.getUTCFullYear();
    viewMonth = next.getUTCMonth();
    renderCalendar();
  }

  document.addEventListener('pointerdown', event => {
    if (useNativePicker()) return;
    const target = event.target.closest?.('input[type="date"]');
    if (target && !target.disabled && !target.readOnly) {
      event.preventDefault();
      target.focus({ preventScroll: true });
      openCalendar(target);
      return;
    }
    if (calendar && !calendar.contains(event.target)) closeCalendar();
  }, true);

  document.addEventListener('click', event => {
    if (useNativePicker()) return;
    if (event.target.closest?.('input[type="date"]') && !event.target.disabled) event.preventDefault();
  }, true);

  document.addEventListener('keydown', event => {
    if (useNativePicker()) return;
    if (!(event.target instanceof HTMLInputElement) || event.target.type !== 'date' || event.target.disabled) return;
    if (event.key === 'Escape' && input === event.target) {
      event.preventDefault();
      closeCalendar();
    } else if (event.key === 'Tab' && input === event.target) {
      closeCalendar();
    } else if (event.key === 'Enter' || event.key === ' ' || (event.altKey && event.key === 'ArrowDown')) {
      event.preventDefault();
      if (input === event.target) {
        if (event.key === 'Enter' || event.key === ' ') choose(activeDate);
      } else openCalendar(event.target);
    } else if (input === event.target && ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(event.key)) {
      event.preventDefault();
      moveActive({ ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 }[event.key]);
    } else if (input === event.target && (event.key === 'PageUp' || event.key === 'PageDown')) {
      event.preventDefault();
      shiftMonth(event.key === 'PageUp' ? -1 : 1);
    }
  });

  window.addEventListener('resize', () => {
    if (useNativePicker()) closeCalendar();
    else positionCalendar();
  });
  document.addEventListener('scroll', event => {
    if (calendar && !calendar.contains(event.target)) closeCalendar();
  }, true);
})();
