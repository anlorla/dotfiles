var { ExtensionCommon } = ChromeUtils.importESModule(
  "resource://gre/modules/ExtensionCommon.sys.mjs"
);
var { ExtensionSupport } = ChromeUtils.importESModule(
  "resource:///modules/ExtensionSupport.sys.mjs"
);

const AVATAR_CLASS = "initial-avatar-badge";
const SIZE = 32;

// Catppuccin Mocha 十色：按发件人邮箱哈希取，同一发件人恒定同色
const PALETTE = [
  "#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#94e2d5",
  "#89b4fa", "#cba6f7", "#f5c2e7", "#eba0ac", "#89dceb",
];

function hashString(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (hash << 5) - hash + str.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
}

function initialsFor(display, email) {
  const clean = (display || "").replace(/^["']|["']$/g, "").trim();
  if (clean) {
    if (/[一-鿿぀-ヿ가-힯]/.test(clean[0])) return clean[0];
    const parts = clean.split(/[\s,._-]+/).filter(Boolean);
    if (parts.length >= 2) {
      const a = parts[0][0];
      const b = parts[parts.length - 1][0];
      if (/[a-zA-Z]/.test(a) && /[a-zA-Z]/.test(b)) return (a + b).toUpperCase();
    }
    return clean[0].toUpperCase();
  }
  const local = (email || "").split("@")[0] || "?";
  return (local[0] || "?").toUpperCase();
}

function parseAuthor(raw) {
  if (!raw) return { display: "", email: "" };
  const m = raw.match(/^\s*(.*?)\s*<([^>]+)>\s*$/);
  if (m) return { display: m[1] || "", email: (m[2] || "").toLowerCase() };
  const t = raw.trim();
  return t.includes("@") ? { display: "", email: t.toLowerCase() } : { display: t, email: "" };
}

function buildAvatar(doc, raw) {
  const { display, email } = parseAuthor(raw);
  const key = email || display || "?";
  const bg = PALETTE[hashString(key) % PALETTE.length];
  const text = initialsFor(display, email);

  const el = doc.createElement("div");
  el.className = AVATAR_CLASS;
  el.textContent = text;
  el.setAttribute("data-initial-avatar-key", key);
  el.style.cssText = [
    `width:${SIZE}px`,
    `min-width:${SIZE}px`,
    `height:${SIZE}px`,
    "border-radius:50%",
    `background-color:${bg}`,
    "color:#11111b",
    "display:inline-flex",
    "align-items:center",
    "justify-content:center",
    `font-size:${text.length > 1 ? 12 : 15}px`,
    "font-weight:600",
    "line-height:1",
    "margin-inline-end:8px",
    "flex:0 0 auto",
    "align-self:center",
    "user-select:none",
    "overflow:hidden",
  ].join(";");
  return el;
}

// 卡片视图：.card-container > .thread-card-column（首个）为插入点
// 表格视图：直接插到 subject / correspondent 单元格最前
function decorateRow(doc, row) {
  const senderEl = row.querySelector("[class*='sender']");
  const raw = senderEl
    ? (senderEl.getAttribute("title") || senderEl.textContent || "").trim()
    : "";
  if (!raw) return;

  const key = parseAuthor(raw).email || parseAuthor(raw).display || "?";
  const existing = row.querySelector("." + AVATAR_CLASS);
  if (existing) {
    // 行被复用（虚拟滚动）时若发件人变了，就重建
    if (existing.getAttribute("data-initial-avatar-key") === key) return;
    existing.remove();
  }

  const column = row.querySelector(".thread-card-column");
  const avatar = buildAvatar(doc, raw);

  if (column) {
    // 让头像在整张卡片高度内垂直居中
    column.style.display = "flex";
    column.style.flexDirection = "row";
    column.style.alignItems = "center";
    if (column.firstChild !== avatar) column.insertBefore(avatar, column.firstChild);
  } else {
    const cell =
      row.querySelector("[class*='correspondent']") ||
      row.querySelector("[class*='subject']") ||
      row.querySelector("td");
    if (!cell) return;
    const cs = doc.defaultView.getComputedStyle(cell);
    if (cs.display !== "flex") {
      cell.style.display = "flex";
      cell.style.alignItems = "center";
    }
    cell.insertBefore(avatar, cell.firstChild);
  }
}

function decorateAll(doc) {
  for (const row of doc.querySelectorAll("#threadTree tbody tr")) {
    try {
      decorateRow(doc, row);
    } catch (_) {}
  }
}

const observed = new WeakSet();

function attach(win) {
  try {
    const a3 = win.document.getElementById("tabmail")?.currentAbout3Pane;
    const doc = a3?.document;
    if (!doc) return false;
    const tree = doc.getElementById("threadTree");
    if (!tree) return false;

    decorateAll(doc);

    if (observed.has(tree)) return true;
    const obs = new doc.defaultView.MutationObserver(() => decorateAll(doc));
    obs.observe(tree, { childList: true, subtree: true });
    observed.add(tree);
    return true;
  } catch (e) {
    console.error("[Initial Avatars]", e);
    return false;
  }
}

var avatarApi = class extends ExtensionCommon.ExtensionAPI {
  getAPI(context) {
    return {
      avatarApi: {
        async start() {
          const hook = (win) => {
            let n = 0;
            const t = win.setInterval(() => {
              n++;
              if (attach(win) || n > 40) win.clearInterval(t);
            }, 500);
          };
          ExtensionSupport.registerWindowListener("initial-avatars-listener", {
            chromeURLs: ["chrome://messenger/content/messenger.xhtml"],
            onLoadWindow: hook,
          });
          for (const win of Services.wm.getEnumerator("mail:3pane")) hook(win);
        },
        async stop() {
          ExtensionSupport.unregisterWindowListener("initial-avatars-listener");
        },
      },
    };
  }

  onShutdown(isAppShutdown) {
    if (isAppShutdown) return;
    try {
      ExtensionSupport.unregisterWindowListener("initial-avatars-listener");
    } catch (_) {}
    for (const win of Services.wm.getEnumerator("mail:3pane")) {
      try {
        const doc = win.document.getElementById("tabmail")?.currentAbout3Pane?.document;
        if (!doc) continue;
        for (const el of doc.querySelectorAll("." + AVATAR_CLASS)) el.remove();
      } catch (_) {}
    }
  }
};
