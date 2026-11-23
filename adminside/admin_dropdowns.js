// Styled menus for the admin dashboard's existing single-choice selects.
// The native select remains the source of truth for values, forms, and change handlers.
(function () {
  let openSelect = null;
  let menu = null;
  let activeIndex = -1;
  let nextMenuId = 0;
  let searchText = '';
  let searchTimer = 0;

  function useNativePicker() {
    return window.matchMedia('(hover: none) and (pointer: coarse)').matches;
  }

  function selectableOptions(select) {
    return Array.from(select.options).filter(option => !option.disabled && !option.closest('optgroup[disabled]'));
  }

  function closeMenu() {
    if (openSelect) {
      openSelect.setAttribute('aria-expanded', 'false');
      openSelect.removeAttribute('aria-controls');
      openSelect.removeAttribute('aria-activedescendant');
    }
    menu?.remove();
    menu = null;
    openSelect = null;
    activeIndex = -1;
    searchText = '';
    clearTimeout(searchTimer);
  }

  function setActive(index) {
    if (!menu || !openSelect) return;
    const options = selectableOptions(openSelect);
    if (!options.length) return;
    activeIndex = Math.max(0, Math.min(index, options.length - 1));
    menu.querySelectorAll('[role="option"]').forEach((item, itemIndex) => {
      item.classList.toggle('is-active', itemIndex === activeIndex);
      if (itemIndex === activeIndex) {
        openSelect.setAttribute('aria-activedescendant', item.id);
        item.scrollIntoView({ block: 'nearest' });
      }
    });
  }

  function choose(option) {
    if (!openSelect || option.disabled) return;
    const select = openSelect;
    const changed = select.selectedIndex !== option.index;
    select.selectedIndex = option.index;
    closeMenu();
    select.focus({ preventScroll: true });
    if (changed) {
      select.dispatchEvent(new Event('input', { bubbles: true }));
      select.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  function positionMenu() {
    if (!menu || !openSelect || !openSelect.isConnected) return closeMenu();
    const rect = openSelect.getBoundingClientRect();
    const width = Math.min(Math.max(rect.width, 190), window.innerWidth - 16);
    menu.style.width = `${width}px`;
    menu.style.left = `${Math.max(8, Math.min(rect.left, window.innerWidth - width - 8))}px`;
    const spaceBelow = window.innerHeight - rect.bottom - 8;
    const spaceAbove = rect.top - 8;
    const above = spaceBelow < Math.min(menu.scrollHeight, 240) && spaceAbove > spaceBelow;
    menu.style.maxHeight = `${Math.max(96, Math.min(280, above ? spaceAbove : spaceBelow))}px`;
    menu.style.top = above
      ? `${Math.max(8, rect.top - menu.offsetHeight - 5)}px`
      : `${rect.bottom + 5}px`;
  }

  function openMenu(select) {
    if (select.disabled || select.multiple || select.size > 1) return;
    if (openSelect === select) return closeMenu();
    closeMenu();
    openSelect = select;
    menu = document.createElement('div');
    menu.id = `admin-select-menu-${++nextMenuId}`;
    menu.className = 'admin-select-menu';
    menu.setAttribute('role', 'listbox');
    menu.setAttribute('aria-label', select.getAttribute('aria-label') ||
      document.querySelector(`label[for="${CSS.escape(select.id)}"]`)?.textContent?.trim() || 'Choose an option');

    const options = selectableOptions(select);
    options.forEach((option, index) => {
      const item = document.createElement('button');
      item.type = 'button';
      item.className = 'admin-select-option';
      item.id = `${menu.id}-option-${index}`;
      item.setAttribute('role', 'option');
      item.setAttribute('aria-selected', String(option.selected));
      item.tabIndex = -1;
      item.textContent = option.textContent.trim();
      if (option.selected) item.classList.add('is-selected');
      item.addEventListener('pointerenter', () => setActive(index));
      item.addEventListener('click', () => choose(option));
      menu.appendChild(item);
    });
    if (!options.length) {
      const empty = document.createElement('span');
      empty.className = 'admin-select-empty';
      empty.textContent = 'No options available';
      menu.appendChild(empty);
    }

    document.body.appendChild(menu);
    select.setAttribute('aria-expanded', 'true');
    select.setAttribute('aria-controls', menu.id);
    activeIndex = Math.max(0, options.findIndex(option => option.selected));
    positionMenu();
    if (options.length) setActive(activeIndex);
  }

  document.addEventListener('pointerdown', event => {
    if (useNativePicker()) return;
    const select = event.target.closest?.('select:not([multiple])');
    if (select && select.size <= 1 && !select.disabled) {
      event.preventDefault();
      select.focus({ preventScroll: true });
      openMenu(select);
      return;
    }
    if (menu && !menu.contains(event.target)) closeMenu();
  }, true);

  document.addEventListener('keydown', event => {
    if (useNativePicker()) return;
    const select = event.target;
    if (!(select instanceof HTMLSelectElement) || select.multiple || select.size > 1 || select.disabled) return;
    const options = selectableOptions(select);
    if (event.key === 'Escape' && openSelect === select) {
      event.preventDefault();
      closeMenu();
    } else if (event.key === 'Tab' && openSelect === select) {
      closeMenu();
    } else if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      if (openSelect === select && options[activeIndex]) choose(options[activeIndex]);
      else openMenu(select);
    } else if (event.key === 'ArrowDown' || event.key === 'ArrowUp' ||
      event.key === 'Home' || event.key === 'End') {
      event.preventDefault();
      if (openSelect !== select) openMenu(select);
      if (event.key === 'Home') setActive(0);
      else if (event.key === 'End') setActive(options.length - 1);
      else setActive(activeIndex + (event.key === 'ArrowDown' ? 1 : -1));
    } else if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
      event.preventDefault();
      if (openSelect !== select) openMenu(select);
      searchText += event.key.toLocaleLowerCase();
      clearTimeout(searchTimer);
      searchTimer = setTimeout(() => { searchText = ''; }, 600);
      const match = options.findIndex(option => option.textContent.trim().toLocaleLowerCase().startsWith(searchText));
      if (match >= 0) setActive(match);
    }
  });

  window.addEventListener('resize', () => {
    if (useNativePicker()) closeMenu();
    else positionMenu();
  });
  document.addEventListener('scroll', event => {
    if (menu && !menu.contains(event.target)) closeMenu();
  }, true);
})();
