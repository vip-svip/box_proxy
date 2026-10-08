/* Box Proxy WebUI
 * 运行于 KernelSU WebView。通过全局 kernelsu.exec() 调用 shell。
 * 若在普通浏览器中打开（无 kernelsu），自动进入 DEMO 模式便于预览。
 */
'use strict';

const KS = (typeof kernelsu !== 'undefined') ? kernelsu : null;
const DEMO = !KS;
const MOD = '/data/adb/modules/box_proxy';
const MG  = 'sh ' + MOD + '/bin/manager.sh';

let state = { files: [], status: 'stopped', core: 'not installed', autostart: false, tab: 'config' };

/* ---------- shell bridge ---------- */
async function exec(cmd){
  if (DEMO) return demoExec(cmd);
  try{
    const r = await KS.exec(cmd);
    return { out:(r.stdout||'').trim(), err:(r.stderr||'').trim(), code:r.errno };
  }catch(e){ return { out:'', err:String(e), code:-1 }; }
}
async function mg(args){ return exec(MG + ' ' + args); }

/* ---------- helpers ---------- */
function toast(msg){
  let t = document.querySelector('.toast');
  if(!t){ t=document.createElement('div'); t.className='toast'; document.body.appendChild(t); }
  t.textContent = msg; t.classList.add('show');
  clearTimeout(t._t); t._t=setTimeout(()=>t.classList.remove('show'), 1800);
}
const $ = s => document.querySelector(s);
function esc(s){ return String(s).replace(/[&<>"]/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }

async function refresh(){
  const l = await mg('list');
  state.files = l.out.split('\n').filter(Boolean).map(line=>{
    const p = line.split('|');
    return { name:p[0], size:p[1], time:p[2], active:p[3]==='1' };
  });
  state.status  = (await mg('status')).out || 'stopped';
  state.core    = (await mg('core-version')).out || 'not installed';
  state.autostart = (await mg('autostart')).out === 'on';
}

/* ---------- router ---------- */
function go(tab){
  state.tab = tab;
  document.querySelectorAll('.tabbar a').forEach(a=>a.classList.toggle('active', a.dataset.tab===tab));
  const titles = { home:'首页', config:'配置', data:'数据', setting:'设置' };
  $('#title').textContent = titles[tab];
  if(tab==='home')    renderHome();
  if(tab==='config')  renderConfig();
  if(tab==='data')    renderData();
  if(tab==='setting') renderSetting();
}

/* ---------- views ---------- */
async function renderHome(){
  await refresh();
  const on = state.status==='running';
  $('#view').innerHTML = `
    <div class="card" style="padding:20px;text-align:center;">
      <div style="font-size:15px;color:var(--sub);">当前状态</div>
      <div style="margin:12px 0;"><span class="pill ${on?'on':'off'}">${on?'运行中':'已停止'}</span></div>
      <div style="font-size:13px;color:var(--sub);margin-bottom:16px;">配置：${esc(activeName()||'—')}</div>
      <button class="btn ${on?'danger':''}" onclick="toggle()">${on?'停止代理':'启动代理'}</button>
    </div>
    <div class="grid">
      <div class="stat"><div class="k">内核</div><div class="v" style="font-size:13px;">${esc(shortCore())}</div></div>
      <div class="stat"><div class="k">配置文件</div><div class="v">${state.files.length}</div></div>
    </div>
    <div style="height:14px"></div>
    <button class="btn ghost" onclick="go('config')">管理配置</button>
  `;
}
function activeName(){ const f=state.files.find(x=>x.active); return f?f.name:''; }
function shortCore(){ const m=state.core.match(/v[\d.]+/); return m?m[0]:state.core; }

async function renderConfig(){
  await refresh();
  $('#view').innerHTML = `
    <div class="card">
      <div class="row" onclick="resetConfig()">
        <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 12a8 8 0 1 0 3-6.2L4 8"/><path d="M4 4v4h4"/></svg>
        <div class="txt">恢复默认配置</div><div class="chev">›</div>
      </div>
      <div class="row" onclick="openImport()">
        <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M7 15a4 4 0 0 1 .8-7.9A5 5 0 0 1 17 8a3.5 3.5 0 0 1 .5 7"/><path d="M12 12v6M9.5 15.5 12 18l2.5-2.5"/></svg>
        <div class="txt">导入…（在线地址）</div><div class="chev">›</div>
      </div>
      <div class="row" onclick="updateAll()">
        <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M2 8a15 15 0 0 1 20 0"/><path d="M5 11a10 10 0 0 1 14 0"/><path d="M8.5 14.5a5 5 0 0 1 7 0"/><circle cx="12" cy="18" r="1.4" fill="currentColor"/></svg>
        <div class="txt">Wi-Fi 上传 / 在线更新全部</div><div class="chev">›</div>
      </div>
      <div class="row" onclick="showModules()">
        <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M8 3H5v3M16 3h3v3M8 21H5v-3M16 21h3v-3"/><path d="M10 9l-1 1 1 1M14 9l1 1-1 1"/></svg>
        <div class="txt">模块</div><div class="chev">›</div>
      </div>
      <div class="row" onclick="testRules()">
        <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 3h6M10 3v6l-5 9a1.5 1.5 0 0 0 1.3 2.2h11.4A1.5 1.5 0 0 0 19 18l-5-9V3"/></svg>
        <div class="txt">测试规则</div><div class="chev">›</div>
      </div>
    </div>

    <div class="section">本地文件</div>
    <div class="card" id="files"></div>
  `;
  renderFiles();
}
function renderFiles(){
  const box = $('#files');
  if(!state.files.length){ box.innerHTML = `<div class="row"><div class="txt" style="color:var(--sub)">暂无配置，点右上角 ＋ 导入在线地址</div></div>`; return; }
  box.innerHTML = state.files.map(f=>`
    <div class="file ${f.active?'active':''}">
      <div class="dot"></div>
      <div class="meta" onclick="useConfig('${esc(f.name)}')">
        <div class="name">${esc(f.name)}</div>
        <div class="sub">${esc(f.time)} · ${esc(f.size)}</div>
      </div>
      <div class="check">✓</div>
      <div class="info" onclick="fileInfo('${esc(f.name)}')">i</div>
    </div>
  `).join('');
}

async function renderData(){
  await refresh();
  const on = state.status==='running';
  $('#view').innerHTML = `
    <div class="card" style="padding:16px;">
      <div class="row" style="padding:0 0 12px;">
        <div class="txt">代理开关</div>
        <div class="switch ${on?'on':''}" onclick="toggle()"><i></i></div>
      </div>
      <div style="font-size:13px;color:var(--sub);">流量统计依赖内核 API，此处展示实时连通性检测。</div>
    </div>
    <button class="btn ghost" onclick="checkIp()">检测出口 IP</button>
    <div style="height:12px"></div>
    <div class="section">运行日志</div>
    <button class="btn ghost" onclick="showLog()">查看最新日志</button>
  `;
}

async function renderSetting(){
  await refresh();
  const ai = state.autostart;
  $('#view').innerHTML = `
    <div class="card">
      <div class="row">
        <div class="txt">开机自启</div>
        <div class="switch ${ai?'on':''}" onclick="toggleAutostart()"><i></i></div>
      </div>
      <div class="row" onclick="installCore()">
        <div class="txt">下载 / 更新内核</div><div class="chev">${esc(shortCore())} ›</div>
      </div>
      <div class="row" onclick="showOnline()">
        <div class="txt">在线资源地址</div><div class="chev">›</div>
      </div>
      <div class="row" onclick="showLog()">
        <div class="txt">日志</div><div class="chev">›</div>
      </div>
    </div>
    <div class="section">关于</div>
    <div class="card" style="padding:16px;">
      <div style="font-size:14px;">Box Proxy v1.0.0</div>
      <div style="font-size:12px;color:var(--sub);margin-top:6px;">KernelSU 在线订阅代理平台 · mihomo 内核 · TUN 全局代理（复用设备已有网络能力，仅作本地配置管理）</div>
    </div>
  `;
}

/* ---------- actions ---------- */
async function toggle(){
  const r = await mg('toggle');
  toast(r.out.split('\n').pop() || '完成');
  go(state.tab);
}
async function useConfig(name){
  const r = await mg('use "'+name+'"');
  toast(r.out || ('已启用 '+name));
  renderConfig();
}
async function resetConfig(){
  if(!confirm('恢复默认配置？将清空所有本地配置（不可撤销）')) return;
  const r = await mg('reset'); toast(r.out); renderConfig();
}
async function updateAll(){
  if(!confirm('在线更新全部订阅？')) return;
  toast('正在更新…');
  const r = await mg('update-all');
  toast(r.out.split('\n').length>1 ? '更新完成' : (r.out||'无订阅'));
  renderConfig();
}
async function toggleAutostart(){
  const r = await mg('autostart ' + (state.autostart?'off':'on'));
  toast(r.out); renderSetting();
}
async function installCore(){
  toast('正在下载内核…');
  const r = await exec('sh ' + MOD + '/bin/fetch_core.sh');
  toast(r.out.split('\n').pop() || '完成');
  renderSetting();
}
async function checkIp(){
  toast('检测中…');
  const r = await mg('ip');
  toast('出口 IP：' + (r.out || '获取失败'));
}
async function showLog(){
  const r = await mg('logs 120');
  openSheet('运行日志', `<pre class="log">${esc(r.out||'(空)')}</pre>
    <div class="actions"><button class="btn" onclick="closeSheet()">关闭</button></div>`);
}
function testRules(){
  openSheet('测试规则', `
    <label>输入域名或 IP，测试其命中策略</label>
    <input id="ruleInput" placeholder="例如 google.com">
    <div class="actions">
      <button class="btn ghost" onclick="closeSheet()">取消</button>
      <button class="btn" onclick="doTestRule()">测试</button>
    </div>
    <pre class="log" id="ruleOut" style="margin-top:14px;display:none"></pre>`);
}
async function doTestRule(){
  const d = ($('#ruleInput').value||'').trim();
  if(!d) return toast('请输入域名');
  const r = await mg('test-rule "'+d+'"');
  const el = $('#ruleOut'); el.style.display='block';
  el.textContent = r.out || '当前内核未启用规则测试';
}
function showModules(){
  openSheet('模块 / 在线资源', `
    <div style="font-size:13px;color:var(--sub);line-height:1.7">
      在线地址即“资源订阅”，可在下方填入模块索引地址，网页会读取并列出可用资源导入。
    </div>
    <label>在线索引地址</label>
    <input id="onlineIdx" value="https://raw.githubusercontent.com/yourname/box-proxy/main/online/index.json">
    <div class="actions">
      <button class="btn ghost" onclick="closeSheet()">关闭</button>
      <button class="btn" onclick="loadIndex()">加载</button>
    </div>
    <div id="idxOut" style="margin-top:14px;font-size:13px;line-height:1.9"></div>`);
}
function showOnline(){ showModules(); }
async function loadIndex(){
  const url = ($('#onlineIdx').value||'').trim();
  const el = $('#idxOut'); el.innerHTML = '加载中…';
  if(DEMO){ el.innerHTML = '<div style="color:var(--sub)">DEMO 模式：真机上将从在线地址拉取资源列表并可一键导入。</div>'; return; }
  const r = await exec(`curl -sL --connect-timeout 12 '${url}'`);
  try{
    const j = JSON.parse(r.out);
    const src = (j.sources||[]).concat(j.modules||[]);
    el.innerHTML = src.map(s=>`<div>• <b>${esc(s.name)}</b><br><span style="color:var(--sub);font-size:12px">${esc(s.url||'')}</span><br><button class="btn ghost" style="padding:6px;margin:6px 0;font-size:13px" onclick="importUrl('${esc(s.url||'')}','${esc(s.id||s.name)}')">导入此地址</button></div>`).join('') || '(无资源)';
  }catch(e){ el.innerHTML = '<div style="color:#e5484d">解析失败：'+esc(r.err||r.out||e)+'</div>'; }
}
async function importUrl(url,name){
  closeSheet();
  toast('导入中…');
  const r = await mg(`import '${url}' '${name}'`);
  toast(r.out || '完成');
  renderConfig();
}
function fileInfo(name){
  const f = state.files.find(x=>x.name===name);
  openSheet(name, `
    <div style="font-size:13px;line-height:2;color:var(--text)">
      大小：${esc(f.size)}<br>修改时间：${esc(f.time)}<br>状态：${f.active?'使用中':'未启用'}
    </div>
    <div class="actions" style="flex-wrap:wrap">
      <button class="btn" onclick="useConfig('${esc(name)}');closeSheet()">启用</button>
      <button class="btn ghost" onclick="updateOne('${esc(name)}')">在线更新</button>
      <button class="btn ghost" onclick="renameFile('${esc(name)}')">重命名</button>
      <button class="btn danger" onclick="deleteFile('${esc(name)}')">删除</button>
    </div>`);
}
async function updateOne(name){
  const r = await mg('update "'+name+'"'); toast(r.out||'完成'); closeSheet(); renderConfig();
}
async function deleteFile(name){
  if(!confirm('删除 '+name+' ?')) return;
  const r = await mg('delete "'+name+'"'); toast(r.out); closeSheet(); renderConfig();
}
async function renameFile(old){
  const nn = prompt('新文件名', old); if(!nn||nn===old) return;
  const r = await mg(`rename '${old}' '${nn}'`); toast(r.out||'完成'); closeSheet(); renderConfig();
}

/* ---------- import sheet ---------- */
function openImport(){
  openSheet('导入在线配置', `
    <label>在线地址（订阅 URL / Clash-YAML）</label>
    <input id="impUrl" placeholder="https://example.com/sub.yaml">
    <label>保存名称（可留空自动命名）</label>
    <input id="impName" placeholder="fanqie-lite">
    <div class="actions">
      <button class="btn ghost" onclick="closeSheet()">取消</button>
      <button class="btn" onclick="doImport()">导入</button>
    </div>`);
}
async function doImport(){
  const url = ($('#impUrl').value||'').trim();
  const name = ($('#impName').value||'').trim();
  if(!url) return toast('请填写在线地址');
  toast('下载中…');
  const r = await mg(`import '${url}' '${name}'`);
  toast(r.err || r.out || '完成');
  closeSheet(); renderConfig();
}
function openSheet(title, html){
  let m = document.querySelector('.mask');
  if(!m){ m=document.createElement('div'); m.className='mask'; document.body.appendChild(m); }
  m.innerHTML = `<div class="sheet"><h3>${esc(title)}</h3>${html}</div>`;
  m.classList.add('show');
  m.onclick = e => { if(e.target===m) closeSheet(); };
}
function closeSheet(){ const m=document.querySelector('.mask'); if(m) m.classList.remove('show'); }

/* ---------- DEMO data ---------- */
const DEMO_FILES = [
  ['fanqie-lite.conf','45.1K','2026-10-08 12:12:26',true],
  ['fanqie-yfamilys-integrated.conf','86.0K','2026-10-07 13:44:07',false],
  ['wloc.conf','20.5K','2026-10-07 07:55:34',false],
  ['fanqie-adblock.conf','20.5K','2026-10-07 07:17:00',false],
  ['shadowrocket_basic.conf','61.4K','2026-10-07 06:52:06',false],
  ['ddgksf2013.conf','41.0K','2026-10-07 02:32:51',false],
  ['As-Lucky.conf','45.1K','2026-10-07 02:32:25',false],
  ['sr_proxy_banad.conf','6.6M','2026-10-07 02:20:55',false],
  ['default.conf','122.9K','2026-10-07 02:18:09',false],
];
function demoExec(cmd){
  const a = cmd.replace(MG,'').trim();
  const c = a.split(' ')[0];
  if(c==='list')    return { out: DEMO_FILES.map(f=>f.join('|')).join('\n'), err:'', code:0 };
  if(c==='status')  return { out:'stopped', err:'', code:0 };
  if(c==='core-version') return { out:'Mihomo Meta v1.18.8 (DEMO)', err:'', code:0 };
  if(c==='autostart') return { out:'off', err:'', code:0 };
  if(c==='logs')    return { out:'[DEMO] mihomo started\n[DEMO] tun device created\n[DEMO] listening 7890', err:'', code:0 };
  if(c==='ip')      return { out:'203.0.113.7 (DEMO)', err:'', code:0 };
  return { out:'[DEMO] '+a, err:'', code:0 };
}

/* ---------- boot ---------- */
document.addEventListener('DOMContentLoaded', ()=>{ if(DEMO) toast('DEMO 预览模式'); go('config'); });
