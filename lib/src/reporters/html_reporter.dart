import 'dart:convert';

import '../models/report.dart';

/// Renders a self-contained Lighthouse-style HTML dashboard from [GuardianReport].
class HtmlReporter {
  String render(GuardianReport report) {
    final json = const JsonEncoder().convert(report.toJson());
    // Prevent </script> breakage inside the inline payload.
    final escaped = json
        .replaceAll('<', r'\u003c')
        .replaceAll('>', r'\u003e')
        .replaceAll('&', r'\u0026');

    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Flutter Health Guard Report</title>
<style>
:root {
  --bg: #0f1419;
  --surface: #1a2332;
  --surface2: #243044;
  --border: #2d3a4f;
  --text: #e7ecf3;
  --muted: #8b9bb4;
  --accent: #3ecf8e;
  --warn: #f5a524;
  --crit: #f31260;
  --info: #66b3ff;
  --gauge-track: #2a3548;
  --radius: 12px;
  --font: "Segoe UI", system-ui, -apple-system, sans-serif;
  --mono: ui-monospace, "Cascadia Code", Consolas, monospace;
}
@media (prefers-color-scheme: light) {
  :root {
    --bg: #f4f6f9;
    --surface: #ffffff;
    --surface2: #eef2f7;
    --border: #d8e0ea;
    --text: #1a2332;
    --muted: #5a6b82;
    --gauge-track: #dce3ee;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: var(--font);
  background: radial-gradient(1200px 600px at 10% -10%, #1b3a2f 0%, transparent 50%),
              radial-gradient(900px 500px at 100% 0%, #1a2a44 0%, transparent 45%),
              var(--bg);
  color: var(--text);
  min-height: 100vh;
  line-height: 1.5;
}
header { padding: 28px 24px 12px; max-width: 1100px; margin: 0 auto; }
.brand {
  font-size: 13px; letter-spacing: 0.18em; text-transform: uppercase;
  color: var(--accent); font-weight: 700;
}
h1 { margin: 6px 0 4px; font-size: 28px; font-weight: 700; }
.meta { color: var(--muted); font-size: 13px; }
.layout { max-width: 1100px; margin: 0 auto; padding: 12px 24px 48px; display: grid; gap: 16px; }
.hero {
  display: grid; grid-template-columns: 180px 1fr; gap: 24px; align-items: center;
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 24px;
}
.gauge { width: 160px; height: 160px; position: relative; margin: 0 auto; }
.gauge svg { transform: rotate(-90deg); }
.gauge .value {
  position: absolute; inset: 0; display: grid; place-items: center;
  font-size: 36px; font-weight: 800;
}
.gauge .label {
  position: absolute; bottom: 28px; left: 0; right: 0; text-align: center;
  font-size: 11px; color: var(--muted); text-transform: uppercase; letter-spacing: 0.08em;
}
.cats { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 10px; }
.cat { background: var(--surface2); border-radius: 10px; padding: 12px; }
.cat .name { font-size: 12px; color: var(--muted); }
.cat .score { font-size: 22px; font-weight: 700; margin-top: 2px; }
.bar { height: 6px; border-radius: 99px; background: var(--gauge-track); margin-top: 8px; overflow: hidden; }
.bar > i { display: block; height: 100%; border-radius: 99px; background: var(--accent); }
.grid2 { display: grid; grid-template-columns: 1.2fr 0.8fr; gap: 16px; }
@media (max-width: 800px) { .hero, .grid2 { grid-template-columns: 1fr; } }
section {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 20px;
}
section h2 {
  margin: 0 0 14px; font-size: 16px;
  display: flex; align-items: center; justify-content: space-between;
}
.badge {
  font-size: 11px; padding: 2px 8px; border-radius: 99px;
  background: var(--surface2); color: var(--muted); font-weight: 600;
}
.rec {
  border: 1px solid var(--border); border-radius: 10px; padding: 14px;
  margin-bottom: 10px; background: var(--surface2);
}
.rec:last-child { margin-bottom: 0; }
.sev {
  display: inline-block; font-size: 10px; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.06em;
  padding: 2px 7px; border-radius: 6px; margin-right: 8px;
}
.sev.critical { background: rgba(243,18,96,.2); color: var(--crit); }
.sev.warning { background: rgba(245,165,36,.2); color: var(--warn); }
.sev.info { background: rgba(102,179,255,.2); color: var(--info); }
.rec h3 { margin: 6px 0; font-size: 14px; }
.rec p { margin: 0; color: var(--muted); font-size: 13px; }
.fixes { margin: 8px 0 0; padding-left: 18px; font-size: 13px; }
.improve { margin-top: 8px; font-size: 12px; color: var(--accent); font-weight: 600; }
table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--border); }
th { color: var(--muted); font-weight: 600; font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; }
tr:hover td { background: var(--surface2); }
.mono { font-family: var(--mono); font-size: 12px; }
.pill { display: inline-block; padding: 1px 7px; border-radius: 99px; font-size: 11px; font-weight: 700; }
.pill.ok { background: rgba(62,207,142,.2); color: var(--accent); }
.pill.bad { background: rgba(243,18,96,.2); color: var(--crit); }
.statrow { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
@media (max-width: 700px) { .statrow { grid-template-columns: repeat(2, 1fr); } }
.stat { background: var(--surface2); border-radius: 10px; padding: 12px; }
.stat .k { font-size: 11px; color: var(--muted); text-transform: uppercase; }
.stat .v { font-size: 18px; font-weight: 700; margin-top: 2px; }
details { margin-top: 8px; }
summary { cursor: pointer; color: var(--muted); font-size: 12px; user-select: none; }
pre {
  background: var(--bg); border: 1px solid var(--border); border-radius: 8px;
  padding: 10px; overflow: auto; font-family: var(--mono); font-size: 11px; max-height: 220px;
}
.timeline { position: relative; padding-left: 18px; }
.timeline::before {
  content: ""; position: absolute; left: 4px; top: 4px; bottom: 4px;
  width: 2px; background: var(--border);
}
.tl-item { position: relative; margin-bottom: 12px; }
.tl-item::before {
  content: ""; position: absolute; left: -16px; top: 6px;
  width: 8px; height: 8px; border-radius: 50%; background: var(--accent);
}
.tl-item .t { font-size: 11px; color: var(--muted); }
.tl-item .n { font-weight: 600; font-size: 13px; }
.search {
  width: 100%; padding: 10px 12px; border-radius: 8px; border: 1px solid var(--border);
  background: var(--surface2); color: var(--text); margin-bottom: 12px; font: inherit;
}
footer { max-width: 1100px; margin: 0 auto; padding: 0 24px 40px; color: var(--muted); font-size: 12px; }
</style>
</head>
<body>
<header>
  <div class="brand">Flutter Health Guard</div>
  <h1>Health Report</h1>
  <div class="meta" id="meta"></div>
</header>
<div class="layout">
  <div class="hero">
    <div class="gauge" id="overall-gauge"></div>
    <div class="cats" id="cats"></div>
  </div>
  <div class="grid2">
    <section>
      <h2>Recommendations <span class="badge" id="rec-count"></span></h2>
      <div id="recs"></div>
    </section>
    <section>
      <h2>Session</h2>
      <div class="statrow" id="session-stats"></div>
      <div style="margin-top:16px" id="device"></div>
    </section>
  </div>
  <section>
    <h2>Performance</h2>
    <div class="statrow" id="perf-stats"></div>
  </section>
  <section>
    <h2>Network <span class="badge" id="net-count"></span></h2>
    <input class="search" id="net-search" placeholder="Filter requests…"/>
    <div style="overflow:auto">
      <table>
        <thead><tr><th>Method</th><th>URL</th><th>Status</th><th>Time</th><th>Size</th></tr></thead>
        <tbody id="net-body"></tbody>
      </table>
    </div>
  </section>
  <div class="grid2">
    <section>
      <h2>Widget Rebuilds</h2>
      <table>
        <thead><tr><th>Widget</th><th>Rebuilds</th><th>Avg Build</th><th>Max</th></tr></thead>
        <tbody id="widget-body"></tbody>
      </table>
    </section>
    <section>
      <h2>Navigation Timeline</h2>
      <div class="timeline" id="nav-timeline"></div>
    </section>
  </div>
  <section>
    <h2>Crashes <span class="badge" id="crash-count"></span></h2>
    <div id="crashes"></div>
  </section>
</div>
<footer>Generated by flutter_health_guard · JSON is the source of truth · HTML is a renderer</footer>
<script>
const REPORT = $escaped;

function scoreColor(s) {
  if (s >= 90) return "#3ecf8e";
  if (s >= 70) return "#f5a524";
  return "#f31260";
}
function esc(s) {
  return String(s == null ? "" : s).replace(/[&<>"']/g, function(m) {
    return ({ "&":"&amp;", "<":"&lt;", ">":"&gt;", '"':"&quot;", "'":"&#39;" })[m];
  });
}
function fmtBytes(n) {
  if (n == null) return "—";
  if (n < 1024) return n + " B";
  if (n < 1048576) return (n/1024).toFixed(1) + " KB";
  return (n/1048576).toFixed(2) + " MB";
}
function gauge(el, score) {
  var c = scoreColor(score);
  var r = 64, circ = 2 * Math.PI * r;
  var offset = circ - (score / 100) * circ;
  el.innerHTML =
    '<svg width="160" height="160" viewBox="0 0 160 160">' +
    '<circle cx="80" cy="80" r="' + r + '" fill="none" stroke="var(--gauge-track)" stroke-width="12"/>' +
    '<circle cx="80" cy="80" r="' + r + '" fill="none" stroke="' + c + '" stroke-width="12" stroke-linecap="round" stroke-dasharray="' + circ + '" stroke-dashoffset="' + offset + '" style="transition:stroke-dashoffset 800ms ease"/>' +
    '</svg><div class="value" style="color:' + c + '">' + score + '</div><div class="label">Overall</div>';
}
function render() {
  var r = REPORT, s = r.scores;
  document.getElementById("meta").textContent =
    "Session " + r.sessionId + " · " + new Date(r.generatedAt).toLocaleString() +
    " · " + Math.round(r.sessionDurationMs/1000) + "s";
  gauge(document.getElementById("overall-gauge"), s.overall);

  var cats = document.getElementById("cats");
  (s.categories || []).forEach(function(c) {
    var color = scoreColor(c.score);
    cats.innerHTML +=
      '<div class="cat"><div class="name">' + esc(c.name) + '</div>' +
      '<div class="score" style="color:' + color + '">' + c.score + '</div>' +
      '<div class="bar"><i style="width:' + c.score + '%;background:' + color + '"></i></div></div>';
  });

  var recs = r.recommendations || [];
  document.getElementById("rec-count").textContent = recs.length;
  document.getElementById("recs").innerHTML = recs.map(function(rec) {
    var fixes = (rec.fixes || []).map(function(f) { return "<li>" + esc(f) + "</li>"; }).join("");
    return '<div class="rec"><span class="sev ' + esc(rec.severity) + '">' + esc(rec.severity) +
      '</span><span class="badge">' + esc(rec.category) + '</span><h3>' + esc(rec.title) +
      '</h3><p>' + esc(rec.message) + '</p>' +
      (fixes ? '<ul class="fixes">' + fixes + '</ul>' : '') +
      (rec.estimatedImprovement ? '<div class="improve">Estimated improvement: ' + esc(rec.estimatedImprovement) + '</div>' : '') +
      '</div>';
  }).join("") || '<p class="meta">No recommendations.</p>';

  var sum = r.summary || {};
  document.getElementById("session-stats").innerHTML =
    '<div class="stat"><div class="k">Crashes</div><div class="v">' + (sum.crashCount||0) + '</div></div>' +
    '<div class="stat"><div class="k">Requests</div><div class="v">' + (sum.networkRequestCount||0) + '</div></div>' +
    '<div class="stat"><div class="k">Avg FPS</div><div class="v">' + Number(sum.averageFps||0).toFixed(1) + '</div></div>' +
    '<div class="stat"><div class="k">Startup</div><div class="v">' + (r.startupTimeMs != null ? r.startupTimeMs + " ms" : "—") + '</div></div>';

  if (r.device) {
    document.getElementById("device").innerHTML =
      '<div class="meta">Device</div><div style="margin-top:6px;font-size:13px"><strong>' +
      esc(r.device.platform) + '</strong> · ' + esc(r.device.osVersion) +
      '<br/>Locale ' + esc(r.device.locale) +
      (r.device.numberOfProcessors ? ' · ' + r.device.numberOfProcessors + ' CPUs' : '') + '</div>';
  }

  var p = r.performance || {};
  document.getElementById("perf-stats").innerHTML =
    '<div class="stat"><div class="k">Frames</div><div class="v">' + (p.totalFrames||0) + '</div></div>' +
    '<div class="stat"><div class="k">Slow</div><div class="v">' + (p.slowFrames||0) + '</div></div>' +
    '<div class="stat"><div class="k">Jank</div><div class="v">' + (p.jankFrames||0) + '</div></div>' +
    '<div class="stat"><div class="k">Max Frame</div><div class="v">' + (p.maxFrameMs||0) + ' ms</div></div>';

  var net = r.network || [];
  document.getElementById("net-count").textContent = net.length;
  var netBody = document.getElementById("net-body");
  function renderNet(filter) {
    filter = (filter || "").toLowerCase();
    var rows = net.filter(function(n) {
      return !filter || (n.method + " " + n.url).toLowerCase().indexOf(filter) >= 0;
    }).map(function(n) {
      var url = n.url.length > 64 ? n.url.slice(0,64) + "…" : n.url;
      return '<tr><td class="mono">' + esc(n.method) + '</td><td class="mono" title="' + esc(n.url) + '">' +
        esc(url) + '</td><td><span class="pill ' + (n.success ? "ok" : "bad") + '">' +
        (n.statusCode != null ? n.statusCode : "ERR") + '</span></td><td>' +
        (n.durationMs != null ? n.durationMs + " ms" : "—") + '</td><td>' +
        fmtBytes(n.responseSizeBytes) + '</td></tr>' +
        '<tr><td colspan="5"><details><summary>Headers / body</summary><pre>' +
        esc(JSON.stringify({
          requestHeaders: n.requestHeaders,
          responseHeaders: n.responseHeaders,
          requestBody: n.requestBody,
          responseBody: n.responseBody,
          error: n.error
        }, null, 2)) + '</pre></details></td></tr>';
    }).join("");
    netBody.innerHTML = rows || '<tr><td colspan="5" class="meta">No network activity captured.</td></tr>';
  }
  renderNet("");
  document.getElementById("net-search").addEventListener("input", function(e) {
    renderNet(e.target.value);
  });

  document.getElementById("widget-body").innerHTML = (r.widgets || []).map(function(w) {
    return '<tr><td>' + esc(w.widgetName) + '</td><td>' + w.rebuilds +
      '</td><td>' + w.averageBuildMs + ' ms</td><td>' + w.maxBuildMs + ' ms</td></tr>';
  }).join("") || '<tr><td colspan="4" class="meta">Wrap widgets with GuardianWatch to track rebuilds.</td></tr>';

  document.getElementById("nav-timeline").innerHTML = (r.navigation || []).map(function(n) {
    return '<div class="tl-item"><div class="t">' + new Date(n.timestamp).toLocaleTimeString() +
      ' · ' + esc(n.action) + '</div><div class="n">' + esc(n.routeName) + '</div></div>';
  }).join("") || '<p class="meta">Add Guardian.navigatorObserver to MaterialApp.</p>';

  var crashes = r.crashes || [];
  document.getElementById("crash-count").textContent = crashes.length;
  document.getElementById("crashes").innerHTML = crashes.map(function(c) {
    return '<div class="rec"><span class="sev critical">crash</span><h3>' + esc(c.type) +
      '</h3><p>' + esc(c.message) + '</p>' +
      (c.stackTrace ? '<details><summary>Stack trace</summary><pre>' + esc(c.stackTrace) + '</pre></details>' : '') +
      '</div>';
  }).join("") || '<p class="meta">No crashes detected. ✓</p>';
}
render();
</script>
</body>
</html>
''';
  }
}
