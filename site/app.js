document.addEventListener('DOMContentLoaded', () => {
  // 1. Tab Switching Logic
  const tabBtns = document.querySelectorAll('.tab-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');

  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const target = btn.dataset.tab;
      
      tabBtns.forEach(b => b.classList.remove('active'));
      tabPanes.forEach(p => p.classList.remove('active'));

      btn.classList.add('active');
      const activePane = document.getElementById(target);
      if (activePane) activePane.classList.add('active');
    });
  });

  // 2. Copy Code Snippets
  const copyBtns = document.querySelectorAll('.copy-btn');
  const toast = document.getElementById('toast');

  function showToast(message) {
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
    }, 2500);
  }

  copyBtns.forEach(btn => {
    btn.addEventListener('click', async () => {
      const textToCopy = btn.dataset.copy || btn.closest('.quick-install-box, .code-snippet-box')?.querySelector('.code-snippet')?.textContent?.trim();
      if (textToCopy) {
        try {
          await navigator.clipboard.writeText(textToCopy);
          showToast('Copied to clipboard!');
        } catch (err) {
          showToast('Failed to copy');
        }
      }
    });
  });

  // 3. Search Keybindings
  const searchInput = document.getElementById('keybind-search');
  const keybindCards = document.querySelectorAll('.keybind-card');

  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase().trim();
      keybindCards.forEach(card => {
        const action = card.querySelector('.keybind-action')?.textContent?.toLowerCase() || '';
        const keys = card.querySelector('.kbd-group')?.textContent?.toLowerCase() || '';
        if (action.includes(query) || keys.includes(query)) {
          card.style.display = 'flex';
        } else {
          card.style.display = 'none';
        }
      });
    });
  }

  // 4. Interactive Mac vs Linux Switcher Mode Demo
  const modeBtns = document.querySelectorAll('.switch-mode-btn');
  const keymapRows = {
    copy: document.getElementById('keymap-copy'),
    paste: document.getElementById('keymap-paste'),
    spotlight: document.getElementById('keymap-spotlight'),
    quit: document.getElementById('keymap-quit'),
    wordjump: document.getElementById('keymap-wordjump'),
    wordkill: document.getElementById('keymap-wordkill')
  };

  const keymaps = {
    mac: {
      copy: '<kbd>Cmd</kbd> + <kbd>C</kbd>',
      paste: '<kbd>Cmd</kbd> + <kbd>V</kbd>',
      spotlight: '<kbd>Cmd</kbd> + <kbd>Space</kbd>',
      quit: '<kbd>Cmd</kbd> + <kbd>Q</kbd>',
      wordjump: '<kbd>Option</kbd> + <kbd>←</kbd> / <kbd>→</kbd>',
      wordkill: '<kbd>Cmd</kbd> + <kbd>Backspace</kbd>'
    },
    linux: {
      copy: '<kbd>Ctrl</kbd> + <kbd>C</kbd>',
      paste: '<kbd>Ctrl</kbd> + <kbd>V</kbd>',
      spotlight: '<kbd>Super</kbd> + <kbd>Space</kbd>',
      quit: '<kbd>Super</kbd> + <kbd>Q</kbd>',
      wordjump: '<kbd>Ctrl</kbd> + <kbd>←</kbd> / <kbd>→</kbd>',
      wordkill: '<kbd>Ctrl</kbd> + <kbd>Backspace</kbd>'
    }
  };

  modeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const mode = btn.dataset.mode;
      modeBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      if (keymaps[mode]) {
        for (const [key, element] of Object.entries(keymapRows)) {
          if (element) {
            element.innerHTML = keymaps[mode][key];
          }
        }
      }
    });
  });

  // 5. Hero Video Player Interaction
  const heroMediaWrapper = document.getElementById('hero-media-wrapper');
  const heroPlayBtn = document.getElementById('hero-play-btn');
  const heroVideo = document.getElementById('hero-video');
  const heroFullscreenBtn = document.getElementById('hero-fullscreen-btn');

  if (heroPlayBtn && heroVideo && heroMediaWrapper) {
    heroPlayBtn.addEventListener('click', () => {
      heroMediaWrapper.classList.add('playing');
      heroVideo.play().catch(() => {});
    });
  }

  if (heroFullscreenBtn && heroVideo) {
    heroFullscreenBtn.addEventListener('click', () => {
      if (heroMediaWrapper) heroMediaWrapper.classList.add('playing');
      heroVideo.play().catch(() => {});
      if (heroVideo.requestFullscreen) {
        heroVideo.requestFullscreen();
      } else if (heroVideo.webkitRequestFullscreen) {
        heroVideo.webkitRequestFullscreen();
      }
    });
  }

  // 6. Live Checksum Verification from R2
  const checksumElement = document.getElementById('live-checksum');
  if (checksumElement) {
    fetch('https://iso.luminal-linux.org/luminal-linux-latest-x86_64.iso.sha256')
      .then(res => res.text())
      .then(data => {
        const hash = data.replace('SHA256:', '').trim();
        if (hash) {
          checksumElement.textContent = hash;
        }
      })
      .catch(() => {
        // Fallback already in HTML
      });
  }
});
