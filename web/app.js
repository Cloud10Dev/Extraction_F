// GAMEMODEX · app.js v4

function nuiCallback(name, data) {
  fetch('https://extraction_shooter/' + name, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {})
  }).catch(function() {});
}

// ─── DOM refs ────────────────────────────────────────
var D = {
  mainScreen:    document.getElementById('main-screen'),
  mapPins:       document.getElementById('map-pins'),
  miName:        document.getElementById('mi-name'),
  miMode:        document.getElementById('mi-mode'),
  miDesc:        document.getElementById('mi-desc'),
  miPlayers:     document.getElementById('mi-players'),
  miDiff:        document.getElementById('mi-diff'),
  memberList:    document.getElementById('member-list'),
  memberCount:   document.getElementById('member-count'),
  modeBtns:      document.querySelectorAll('.mode-btn'),
  inviteInput:   document.getElementById('invite-input'),
  btnInvite:     document.getElementById('btn-invite'),
  queueStatus:   document.getElementById('queue-status'),
  queueTime:     document.getElementById('queue-time-display'),
  btnQueue:      document.getElementById('btn-queue'),
  btnCancelQ:    document.getElementById('btn-cancel-queue'),
  btnLeave:      document.getElementById('btn-leave-party'),
  btnClose:      document.getElementById('btn-close-menu'),
  btnStorage:    document.getElementById('btn-storage'),
  pillHud:       document.getElementById('pill-hud'),
  pillDot:       document.getElementById('pill-dot'),
  pillLabel:     document.getElementById('pill-label'),
  pillTimer:     document.getElementById('pill-timer'),
  pillExpand:    document.getElementById('pill-expand'),
  matchFound:    document.getElementById('match-found'),
  matchFoundTxt: document.getElementById('match-found-text'),
  deployBar:     document.getElementById('deploy-bar'),
  cntNum:        document.getElementById('countdown-num'),
  cntRing:       document.getElementById('countdown-ring'),
  overlayMap:    document.getElementById('overlay-map-name'),
  matchHud:      document.getElementById('match-hud'),
  extractPts:    document.getElementById('extract-pt-list'),
  exfilProg:     document.getElementById('extraction-progress'),
  exfilBar:      document.getElementById('exfil-bar'),
  deathScreen:   document.getElementById('death-screen'),
  successScreen: document.getElementById('extraction-success'),
  inviteToast:   document.getElementById('invite-toast'),
  inviteMsg:     document.getElementById('invite-toast-msg'),
  btnAccept:     document.getElementById('btn-accept-invite'),
  btnDecline:    document.getElementById('btn-decline-invite'),
  notifs:        document.getElementById('notif-container'),
};

var RING_C = 2 * Math.PI * 42;
if (D.cntRing) D.cntRing.style.strokeDasharray = RING_C;

// ─── State ───────────────────────────────────────────
var S = {
  mode:          'Solo',
  selectedMap:   null,
  maps:          [],
  party:         null,
  inviteKey:     null,
  queueTick:     null,
  cntTick:       null,
  pillTick:      null,
  pillMode:      null,
};

// ─── Helpers ─────────────────────────────────────────
function show(el) { el && el.classList.remove('hidden'); }
function hide(el) { el && el.classList.add('hidden'); }

function fmt(s) {
  return String(Math.floor(s/60)).padStart(2,'0') + ':' + String(s%60).padStart(2,'0');
}

function notif(msg, type) {
  var n = document.createElement('div');
  n.className = 'notif' + (type ? ' '+type : '');
  n.textContent = msg;
  D.notifs.appendChild(n);
  setTimeout(function() {
    n.style.animation = 'notifOut 220ms forwards';
    setTimeout(function() { n.remove(); }, 230);
  }, 3200);
}

// ─── Pill HUD ────────────────────────────────────────
function pillStart(mode) {
  S.pillMode = mode;
  D.pillDot.classList.toggle('in-match', mode === 'match');
  D.pillLabel.textContent = mode === 'match' ? 'IN OPERATION' : 'SEARCHING';
  D.pillTimer.textContent = '00:00';
  show(D.pillHud);
  if (S.pillTick) clearInterval(S.pillTick);
  var t0 = Date.now();
  S.pillTick = setInterval(function() {
    D.pillTimer.textContent = fmt(Math.floor((Date.now()-t0)/1000));
  }, 1000);
}
function pillStop() {
  if (S.pillTick) { clearInterval(S.pillTick); S.pillTick = null; }
  hide(D.pillHud); S.pillMode = null;
}

// ─── Queue timer ─────────────────────────────────────
function queueStart() {
  if (S.queueTick) clearInterval(S.queueTick);
  var t0 = Date.now();
  S.queueTick = setInterval(function() {
    if (D.queueTime) D.queueTime.textContent = fmt(Math.floor((Date.now()-t0)/1000));
  }, 1000);
}
function queueStop() {
  if (S.queueTick) { clearInterval(S.queueTick); S.queueTick = null; }
  if (D.queueTime) D.queueTime.textContent = '00:00';
}

// ─── Match countdown ─────────────────────────────────
function cntStart(total) {
  if (S.cntTick) clearInterval(S.cntTick);
  var rem = total;
  function tick() {
    D.cntNum.textContent = rem;
    D.matchFoundTxt.textContent = 'DEPLOYING IN ' + rem + 's';
    D.cntRing.style.strokeDashoffset = RING_C * (1 - rem/total);
    D.deployBar.style.width = ((total-rem)/total*100) + '%';
  }
  tick();
  S.cntTick = setInterval(function() {
    rem--; tick();
    if (rem <= 0) { clearInterval(S.cntTick); S.cntTick = null; }
  }, 1000);
}

// ─── Map pins ────────────────────────────────────────
// Approximate GTA V world coords → % position on map background
// Map bg covers roughly: X -4000..4500, Y -4500..8000 (north up)
// These positions are tuned visually for the dark map background.
var MAP_PIN_POSITIONS = {
  'city_outskirts':  { x: 51, y: 54 },
  'industrial_port': { x: 62, y: 72 },
  'downtown_ruins':  { x: 47, y: 49 },
};

function buildPins(maps) {
  D.mapPins.innerHTML = '';
  maps.forEach(function(m) {
    var pos = MAP_PIN_POSITIONS[m.id] || { x: 50, y: 50 };
    var pin = document.createElement('div');
    pin.className = 'map-pin';
    pin.style.left = pos.x + '%';
    pin.style.top  = pos.y + '%';
    pin.dataset.mapId = m.id;
    pin.innerHTML =
      '<div class="pin-label">' + m.name.toUpperCase() +
        '<svg class="pin-exfil" viewBox="0 0 12 12" fill="none">' +
          '<circle cx="6" cy="6" r="4.5" stroke="currentColor" stroke-width="1"/>' +
          '<path d="M4 6h4M6 4l2 2-2 2" stroke="currentColor" stroke-width="1" stroke-linecap="round"/>' +
        '</svg>' +
      '</div>' +
      '<div class="pin-connector"></div>' +
      '<div class="pin-dot"></div>';
    pin.addEventListener('click', function() { selectMap(m.id); });
    D.mapPins.appendChild(pin);
  });
}

function selectMap(mapId) {
  S.selectedMap = mapId;
  nuiCallback('setMap', { mapId: mapId });

  // Highlight pin
  D.mapPins.querySelectorAll('.map-pin').forEach(function(p) {
    p.classList.toggle('active', p.dataset.mapId === mapId);
  });

  // Update left panel info
  var m = S.maps.find(function(x) { return x.id === mapId; });
  if (!m) return;
  D.miName.textContent    = m.name.toUpperCase();
  D.miMode.textContent    = 'TACTICAL OPS · ' + (m.label || 'NORMAL');
  D.miDesc.textContent    = m.description || 'Select your insertion point and deploy into the operation zone.';
  D.miPlayers.textContent = m.players || '2–20';
  D.miDiff.textContent    = m.label   || 'NORMAL';

  // Enable deploy button
  D.btnQueue.textContent = 'DEPLOY';
  D.btnQueue.disabled    = false;
}

// ─── Party render ─────────────────────────────────────
function renderParty() {
  var p = S.party;
  D.memberList.innerHTML = '';

  if (!p || !p.members || !p.members.length) {
    D.memberList.innerHTML = '<li class="member-empty">No fireteam</li>';
    if (D.memberCount) D.memberCount.textContent = '0/1';
  } else {
    p.members.forEach(function(m) {
      var li = document.createElement('li');
      li.className = 'member-item';
      li.innerHTML = '<span>' + m.name + '</span>' +
        (m.leader
          ? '<span class="member-leader-badge">LEAD</span>'
          : '<button style="font-size:10px;padding:2px 8px;border:1px solid rgba(217,79,79,.4);border-radius:2px;color:#d94f4f;background:rgba(217,79,79,.08);letter-spacing:.08em" data-src="' + m.src + '">KICK</button>'
        );
      D.memberList.appendChild(li);
    });
    D.memberList.querySelectorAll('[data-src]').forEach(function(b) {
      b.addEventListener('click', function() { nuiCallback('kickMember', { targetSrc: parseInt(b.dataset.src) }); });
    });
    if (D.memberCount) D.memberCount.textContent = p.members.length + '/' + p.members.length;
  }

  D.modeBtns.forEach(function(b) {
    b.classList.toggle('active', b.dataset.mode === ((p && p.mode) || S.mode));
  });

  if (p && p.inQueue) {
    show(D.queueStatus); hide(D.btnQueue); show(D.btnCancelQ);
    if (!S.queueTick) queueStart();
  } else {
    hide(D.queueStatus); show(D.btnQueue); hide(D.btnCancelQ);
    queueStop();
  }
}

// ─── Message handler ──────────────────────────────────
window.addEventListener('message', function(e) {
  var action  = e.data.action;
  var payload = e.data.payload || {};

  switch (action) {

    case 'open':
      show(D.mainScreen);
      pillStop();
      if (payload.party) S.party = payload.party;
      if (payload.maps && payload.maps.length) {
        S.maps = payload.maps;
        buildPins(payload.maps);
        // Auto-select first map
        if (!S.selectedMap) selectMap(payload.maps[0].id);
      }
      renderParty();
      break;

    case 'close':
      hide(D.mainScreen);
      if (S.party && S.party.inQueue) pillStart('queue');
      break;

    case 'partyUpdate':
      S.party = payload.party || null;
      renderParty();
      if (S.party && S.party.inQueue && D.mainScreen.classList.contains('hidden')) {
        if (S.pillMode !== 'queue') pillStart('queue');
      } else if (S.party && !S.party.inQueue && S.pillMode === 'queue') {
        pillStop();
      }
      break;

    case 'incomingInvite':
      S.inviteKey = payload.inviteKey;
      D.inviteMsg.textContent = payload.fromName + ' invited you to their fireteam';
      show(D.inviteToast);
      break;

    case 'notification':
      notif(payload.msg, payload.type);
      break;

    case 'matchFound':
      pillStop(); queueStop();
      show(D.matchFound);
      if (payload.mapName) D.overlayMap.textContent = payload.mapName.toUpperCase();
      cntStart(payload.countdown || 5);
      break;

    case 'matchStart':
      hide(D.matchFound);
      if (S.cntTick) { clearInterval(S.cntTick); S.cntTick = null; }
      D.extractPts.innerHTML = '';
      (payload.extractPts || []).forEach(function(pt) {
        var li = document.createElement('li');
        li.className = 'extract-pt-item';
        li.innerHTML = '<div class="extract-pt-dot"></div><span>' + pt.label + '</span>';
        D.extractPts.appendChild(li);
      });
      show(D.matchHud);
      hide(D.mainScreen);
      pillStart('match');
      break;

    case 'extractionStart':
      show(D.exfilProg);
      if (payload.duration) {
        D.exfilBar.style.transition = 'width ' + payload.duration + 's linear';
        requestAnimationFrame(function() {
          requestAnimationFrame(function() { D.exfilBar.style.width = '100%'; });
        });
      }
      break;

    case 'extractionCancel':
    case 'extractionFail':
      hide(D.exfilProg);
      D.exfilBar.style.transition = 'none';
      D.exfilBar.style.width = '0%';
      break;

    case 'extractionSuccess':
      hide(D.exfilProg); hide(D.matchHud);
      show(D.successScreen);
      pillStop();
      // DO NOT call requestOpenStash here — server handles stash after bucket restore
      setTimeout(function() { hide(D.successScreen); }, 3500);
      break;

    case 'returnedToLobby':
      hide(D.matchHud); hide(D.deathScreen);
      hide(D.exfilProg); hide(D.successScreen); hide(D.matchFound);
      pillStop();
      D.exfilBar.style.transition = 'none'; D.exfilBar.style.width = '0%';
      if (S.cntTick) { clearInterval(S.cntTick); S.cntTick = null; }
      S.party = null;
      break;

    case 'playerDied':
      hide(D.matchHud); hide(D.exfilProg);
      pillStop(); show(D.deathScreen);
      break;
  }
});

// ─── Button events ────────────────────────────────────
D.btnClose.addEventListener('click', function() {
  nuiCallback('closeMenu', {});
  hide(D.mainScreen);
  if (S.party && S.party.inQueue) pillStart('queue');
});

D.btnStorage.addEventListener('click', function() {
  nuiCallback('closeMenu', {});
  hide(D.mainScreen);
  nuiCallback('openStash', {});
});

D.modeBtns.forEach(function(b) {
  b.addEventListener('click', function() {
    S.mode = b.dataset.mode;
    nuiCallback('setMode', { mode: b.dataset.mode });
    D.modeBtns.forEach(function(x) { x.classList.toggle('active', x === b); });
  });
});

D.btnInvite.addEventListener('click', function() {
  var id = parseInt(D.inviteInput.value);
  if (id) nuiCallback('invitePlayer', { targetSrc: id });
  D.inviteInput.value = '';
});
D.inviteInput.addEventListener('keydown', function(e) {
  if (e.key === 'Enter') D.btnInvite.click();
});

D.btnQueue.addEventListener('click', function() {
  if (!S.selectedMap) { notif('Select a zone on the map first.', 'error'); return; }
  nuiCallback('queueJoin', { mode: S.mode, mapId: S.selectedMap });
});

D.btnCancelQ.addEventListener('click', function() {
  nuiCallback('queueCancel', {});
  queueStop(); pillStop();
});

D.btnLeave.addEventListener('click', function() { nuiCallback('leaveParty', {}); });

D.btnAccept.addEventListener('click', function() {
  if (S.inviteKey) nuiCallback('acceptInvite', { inviteKey: S.inviteKey });
  hide(D.inviteToast); S.inviteKey = null;
});
D.btnDecline.addEventListener('click', function() {
  if (S.inviteKey) nuiCallback('declineInvite', { inviteKey: S.inviteKey });
  hide(D.inviteToast); S.inviteKey = null;
});

D.pillExpand.addEventListener('click', function() {
  pillStop();
  show(D.mainScreen);
  renderParty();
  nuiCallback('openMenu', {});
});
