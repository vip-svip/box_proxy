<!DOCTYPE html>
<html lang="zh-CN" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#111214">
<meta name="color-scheme" content="light dark">
<title>Box Proxy</title>
<link rel="stylesheet" href="style.css">
</head>
<body>

<header class="topbar">
  <div class="brand">
    <span class="logo">B</span>
    <h1 id="title">Box Proxy</h1>
  </div>
  <div class="ops">
    <button class="ic" title="导入本地文件" onclick="triggerImportLocal()">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 3v11"/><path d="M8 10l4 4 4-4"/><path d="M5 19h14"/>
      </svg>
    </button>
    <button class="plus" title="快速添加" onclick="openQuickAdd()">+</button>
  </div>
</header>

<main id="view"></main>

<nav class="tabbar">
  <a data-tab="home" onclick="go('home')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/></svg>
    <span>首页</span>
  </a>
  <a data-tab="config" onclick="go('config')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6h16M4 12h16M4 18h16"/><circle cx="8" cy="6" r="2" fill="currentColor"/><circle cx="16" cy="12" r="2" fill="currentColor"/><circle cx="10" cy="18" r="2" fill="currentColor"/></svg>
    <span>配置</span>
  </a>
  <a data-tab="modules" onclick="go('modules')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l8 4.5v9L12 20l-8-4.5v-9z"/><path d="M12 11l8-4.5M12 11v9M12 11L4 6.5"/></svg>
    <span>模块</span>
  </a>
  <a data-tab="nodes" onclick="go('nodes')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="18" r="3"/><path d="M12 9v3M12 12L7 15M12 12l5 3"/></svg>
    <span>节点</span>
  </a>
  <a data-tab="setting" onclick="go('setting')">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1A1.6 1.6 0 0 0 6.6 19l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.6 1.6 0 0 0 3 13.6H3a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 4.6 7L4.5 7a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 10 3.6V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7H21a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1z"/></svg>
    <span>设置</span>
  </a>
</nav>

<input id="fileInput" type="file" accept=".yaml,.yml,.conf,.txt,.json" style="display:none" onchange="onLocalFile(event)">
<script src="app.js"></script>
</body>
</html>
