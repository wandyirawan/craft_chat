/* ============================================================
   CraftChat — UI event handling
   ------------------------------------------------------------
   Drives the chat UI on top of HTMX:
     - Enter key / send button -> sendMessage()
     - optimistic local echo of the user's message
     - HTMX POST to /message (response is swapped into #messages)
     - auto-scroll, typing indicator, and connection status
   ============================================================ */
(function () {
  'use strict';

  /* ---------- Element references ---------- */
  var messagesEl = null;
  var inputEl = null;
  var sendBtnEl = null;
  var statusEl = null;
  var typingEl = null;

  /* ---------- Helpers ---------- */

  function scrollToBottom() {
    if (messagesEl) messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  function setStatus(online) {
    if (!statusEl) return;
    statusEl.classList.toggle('online', online);
    statusEl.classList.toggle('offline', !online);
    statusEl.textContent = online ? '● Online' : '● Offline';
  }

  function appendMessage(text, role) {
    if (!messagesEl) return;
    var el = document.createElement('div');
    el.className = 'message ' + (role === 'user' ? 'user-message' : 'bot-message');
    el.textContent = text;
    messagesEl.appendChild(el);
    scrollToBottom();
  }

  function showTyping(active) {
    if (typingEl) typingEl.classList.toggle('active', active);
  }

  /* ---------- Core: send a message ---------- */

  // Render the user's message immediately, then trigger an HTMX POST.
  function sendMessage() {
    var value = (inputEl.value || '').trim();
    if (!value) return;

    // Optimistic UI: show the user's message right away.
    appendMessage(value, 'user');

    // Delegate the network request to HTMX (swaps reply into #messages).
    if (window.htmx) {
      htmx.ajax('POST', '/message', {
        target: '#messages',
        swap: 'beforeend',
        values: { msg: value }
      });
    }

    // Reset the composer.
    inputEl.value = '';
    inputEl.focus();
    showTyping(true);
  }

  /* ---------- Boot ---------- */

  document.addEventListener('DOMContentLoaded', function () {
    messagesEl = document.getElementById('messages');
    inputEl = document.getElementById('msgInput');
    sendBtnEl = document.getElementById('sendBtn');
    statusEl = document.getElementById('connectionStatus');
    typingEl = document.getElementById('typingIndicator');

    // Enter sends; Shift+Enter is reserved for future multiline input.
    if (inputEl) {
      inputEl.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          sendMessage();
        }
      });
    }

    // Send button.
    if (sendBtnEl) {
      sendBtnEl.addEventListener('click', sendMessage);
    }

    // Connection status follows HTMX activity.
    document.body.addEventListener('htmx:beforeRequest', function () { setStatus(true); });
    document.body.addEventListener('htmx:afterOnLoad', function () {
      showTyping(false);
      scrollToBottom();
    });
    document.body.addEventListener('htmx:responseError', function () {
      setStatus(false);
      showTyping(false);
      appendMessage('⚠ Something went wrong. Please try again.', 'bot');
    });

    // Initial state.
    setStatus(false);
    scrollToBottom();
    if (inputEl) inputEl.focus();
  });
})();
