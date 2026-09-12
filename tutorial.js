// ============================================================================
// INTERACTIVE TUTORIAL SYSTEM - Portfolio Tracker
// Features: Multi-step walkthrough, progress tracking, modern animations
// ============================================================================

const TutorialSystem = (function() {
  const TUTORIAL_KEY = 'portfolio-tutorial-completed';
  const TUTORIAL_STEP_KEY = 'portfolio-tutorial-step';
  
  const steps = [
    {
      target: '#user-avatar',
      title: 'Welcome to Your Portfolio! 🎓',
      description: 'Click your avatar anytime to access profile settings, view stats, or logout.',
      position: 'bottom',
      highlight: true
    },
    {
      target: '.header-title',
      title: 'Your Dashboard Hub',
      description: 'This is your central command center. All your milestones, scores, and achievements live here.',
      position: 'bottom',
      highlight: true
    },
    {
      target: '.nav-btn:nth-child(1)',
      title: 'Overview Tab 📊',
      description: 'See your holistic score breakdown. This is what colleges and counselors will review.',
      position: 'right',
      highlight: true
    },
    {
      target: '.nav-btn:nth-child(2)',
      title: 'Academic Performance 📚',
      description: 'Track subject-wise scores, identify weak topics, and monitor your CBSE/ICSE grades.',
      position: 'right',
      highlight: true
    },
    {
      target: '.nav-btn:nth-child(3)',
      title: 'Extracurricular Activities 🏆',
      description: 'Log competitions, sports, NCC, NSS, and clubs. Each verified activity adds points to your profile.',
      position: 'right',
      highlight: true
    },
    {
      target: '.nav-btn:nth-child(4)',
      title: 'Community Service 🤝',
      description: 'Record volunteer hours and NGO work. Service hours boost your social impact score.',
      position: 'right',
      highlight: true
    },
    {
      target: '.nav-btn:nth-child(5)',
      title: 'Interview Prep 🎤',
      description: 'Practice sessions, confidence tracking, and mentor feedback all in one place.',
      position: 'right',
      highlight: true
    },
    {
      target: '.nav-btn:nth-child(6)',
      title: 'Timeline & Deadlines 📅',
      description: 'Never miss a CUET, JEE, or college application deadline. Sync to your calendar with one click.',
      position: 'right',
      highlight: true
    },
    {
      target: '#theme-pill',
      title: 'Customize Your Experience ✨',
      description: 'Toggle between dark and light modes. Your preference is saved automatically.',
      position: 'bottom',
      highlight: true
    },
    {
      target: 'body',
      title: 'You\'re All Set! 🚀',
      description: 'Start adding your achievements and watch your holistic score grow. Need help? Click the 🎓 Help button anytime.',
      position: 'center',
      highlight: false
    }
  ];

  let currentStep = 0;
  let overlay = null;
  let tooltip = null;
  let spotlight = null;

  function hasCompletedTutorial() {
    return localStorage.getItem(TUTORIAL_KEY) === 'true';
  }

  function markTutorialComplete() {
    localStorage.setItem(TUTORIAL_KEY, 'true');
    localStorage.removeItem(TUTORIAL_STEP_KEY);
  }

  function saveCurrentStep(step) {
    localStorage.setItem(TUTORIAL_STEP_KEY, step);
  }

  function getSavedStep() {
    return parseInt(localStorage.getItem(TUTORIAL_STEP_KEY) || '0');
  }

  function createOverlay() {
    overlay = document.createElement('div');
    overlay.id = 'tutorial-overlay';
    overlay.style.cssText = `
      position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
      background: rgba(0, 0, 0, 0.75); backdrop-filter: blur(4px);
      z-index: 9998; opacity: 0; transition: opacity 0.3s ease;
    `;
    document.body.appendChild(overlay);
    setTimeout(() => overlay.style.opacity = '1', 10);
  }

  function createSpotlight(element) {
    if (spotlight) spotlight.remove();
    if (!element || element === document.body) return;
    spotlight = document.createElement('div');
    spotlight.id = 'tutorial-spotlight';
    const rect = element.getBoundingClientRect();
    const padding = 8;
    spotlight.style.cssText = `
      position: fixed; top: ${rect.top - padding}px; left: ${rect.left - padding}px;
      width: ${rect.width + padding * 2}px; height: ${rect.height + padding * 2}px;
      border: 3px solid #ffe8db; border-radius: 16px;
      box-shadow: 0 0 0 4px rgba(255, 232, 219, 0.3), 0 0 60px 20px rgba(255, 232, 219, 0.4);
      z-index: 9999; pointer-events: none; animation: pulse-spotlight 2s ease-in-out infinite;
    `;
    document.body.appendChild(spotlight);

  function createTooltip(step) {
    if (tooltip) tooltip.remove();
    tooltip = document.createElement('div');
    tooltip.id = 'tutorial-tooltip';
    const progressBar = `<div style="display: flex; gap: 6px; margin-bottom: 16px;">${steps.map((_, i) => `<div style="flex: 1; height: 3px; background: ${i <= currentStep ? '#ffe8db' : 'rgba(255,255,255,0.2)'}; border-radius: 2px; transition: all 0.3s;"></div>`).join('')}</div>`;
    tooltip.innerHTML = `${progressBar}<div style="display: flex; align-items: center; gap: 10px; margin-bottom: 12px;"><div style="font-size: 32px;">${step.title.match(/[🎓📊📚🏆🤝🎤📅✨🚀]/)?.[0] || '💡'}</div><div style="flex: 1;"><div style="font-size: 16px; font-weight: 700; color: var(--text); margin-bottom: 4px;">${step.title.replace(/[🎓📊📚🏆🤝🎤📅✨🚀💡]/g, '').trim()}</div><div style="font-size: 13px; color: var(--muted); line-height: 1.5;">${step.description}</div></div></div><div style="display: flex; gap: 8px; justify-content: space-between; align-items: center; margin-top: 16px;"><button id="tutorial-skip" style="background: transparent; border: 1px solid var(--border); color: var(--muted); padding: 8px 16px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer;">Skip Tutorial</button><div style="display: flex; gap: 8px;">${currentStep > 0 ? `<button id="tutorial-prev" style="background: var(--card-bg); border: 1px solid var(--border); color: var(--text); padding: 8px 16px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer;">← Back</button>` : ''}<button id="tutorial-next" style="background: #ffe8db; border: none; color: #000000; padding: 8px 20px; border-radius: 8px; font-size: 12px; font-weight: 700; cursor: pointer;">${currentStep === steps.length - 1 ? 'Finish 🎉' : 'Next →'}</button></div></div><div style="text-align: center; margin-top: 12px; font-size: 11px; color: var(--muted);">Step ${currentStep + 1} of ${steps.length}</div>`;
    positionTooltip(step);
    document.body.appendChild(tooltip);
    document.getElementById('tutorial-next')?.addEventListener('click', nextStep);
    document.getElementById('tutorial-prev')?.addEventListener('click', prevStep);
    document.getElementById('tutorial-skip')?.addEventListener('click', skipTutorial);
  }
  function positionTooltip(step) {
    const target = step.target === 'body' ? null : document.querySelector(step.target);
    tooltip.style.cssText = `position: fixed; background: var(--card-bg); border: 1px solid var(--border); border-radius: 16px; padding: 20px; max-width: 380px; box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5); z-index: 10000; animation: slideIn 0.4s cubic-bezier(0.16, 1, 0.3, 1);`;
    if (!target || step.position === 'center') { tooltip.style.top = '50%'; tooltip.style.left = '50%'; tooltip.style.transform = 'translate(-50%, -50%)'; } else { const rect = target.getBoundingClientRect(); if (step.position === 'right') { tooltip.style.left = `${rect.right + 20}px`; tooltip.style.top = `${rect.top + rect.height / 2}px`; tooltip.style.transform = 'translateY(-50%)'; } else if (step.position === 'bottom') { tooltip.style.left = `${rect.left + rect.width / 2}px`; tooltip.style.top = `${rect.bottom + 20}px`; tooltip.style.transform = 'translateX(-50%)'; } }
  }
  function showStep(stepIndex) {
    if (stepIndex < 0 || stepIndex >= steps.length) return;
    currentStep = stepIndex; saveCurrentStep(currentStep);
    const step = steps[currentStep];
    const target = step.target === 'body' ? document.body : document.querySelector(step.target);
    if (step.highlight && target && target !== document.body) { createSpotlight(target); target.scrollIntoView({ behavior: 'smooth', block: 'center' }); } else if (spotlight) { spotlight.remove(); spotlight = null; }
    createTooltip(step);
  }
  function nextStep() { if (currentStep < steps.length - 1) { showStep(currentStep + 1); } else { finishTutorial(); } }
  function prevStep() { if (currentStep > 0) { showStep(currentStep - 1); } }
  function skipTutorial() { if (confirm('Skip tutorial? You can restart it anytime from the Help menu.')) { finishTutorial(); } }
  function finishTutorial() { markTutorialComplete(); cleanup(); if (typeof showPopup === 'function') { showPopup('Tutorial complete! 🎉 Click Help (🎓) anytime to replay.'); } }
  function cleanup() { if (overlay) { overlay.style.opacity = '0'; setTimeout(() => overlay?.remove(), 300); } if (tooltip) { tooltip.style.animation = 'slideOut 0.3s ease'; setTimeout(() => tooltip?.remove(), 300); } if (spotlight) spotlight.remove(); overlay = null; tooltip = null; spotlight = null; }
  return {
    start: function() { if (document.getElementById('tutorial-overlay')) return; currentStep = getSavedStep(); createOverlay(); showStep(currentStep); if (!document.getElementById('tutorial-styles')) { const style = document.createElement('style'); style.id = 'tutorial-styles'; style.textContent = `@keyframes pulse-spotlight { 0%, 100% { box-shadow: 0 0 0 4px rgba(255, 232, 219, 0.3), 0 0 60px 20px rgba(255, 232, 219, 0.4); } 50% { box-shadow: 0 0 0 4px rgba(255, 232, 219, 0.5), 0 0 80px 30px rgba(255, 232, 219, 0.6); } } @keyframes slideIn { from { opacity: 0; transform: translate(-50%, -50%) scale(0.9); } to { opacity: 1; transform: translate(-50%, -50%) scale(1); } } @keyframes slideOut { from { opacity: 1; transform: scale(1); } to { opacity: 0; transform: scale(0.95); } }`; document.head.appendChild(style); } },
    restart: function() { localStorage.removeItem(TUTORIAL_KEY); localStorage.removeItem(TUTORIAL_STEP_KEY); this.start(); },
    hasCompleted: hasCompletedTutorial,
    stop: cleanup
  };
})();
window.addEventListener('DOMContentLoaded', function() { setTimeout(function() { if (!TutorialSystem.hasCompleted()) { TutorialSystem.start(); } }, 1000); });

  }
