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

  // 4. Live Checksum Verification from R2
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
