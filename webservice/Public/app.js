"use strict";

// Custom per-category file upload is implemented end-to-end on the server, but
// the UI for it is hidden for now. Flip this to re-enable the upload controls.
const ALLOW_CUSTOM_UPLOAD = false;

const DEFAULT_ACCOUNT = "chris.davis";

// Inline Lucide (https://lucide.dev, ISC license) icons — no CDN dependency.
const svg = (paths) =>
    `<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const ICONS = {
    mail: svg('<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>'),
    users: svg('<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>'),
    calendar: svg('<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/>'),
    tasks: svg('<path d="m3 17 2 2 4-4"/><path d="m3 7 2 2 4-4"/><path d="M13 6h8"/><path d="M13 12h8"/><path d="M13 18h8"/>'),
    drive: svg('<line x1="22" x2="2" y1="12" y2="12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/><line x1="6" x2="6.01" y1="16" y2="16"/><line x1="10" x2="10.01" y1="16" y2="16"/>'),
};

const CATEGORIES = [
    { key: "mails",        label: "Mails",         icon: ICONS.mail,     hasAccount: true,  accept: ".eml",  multiple: true,  bundled: "Gold account",             upload: "Select .eml files" },
    { key: "contacts",     label: "Contacts",      icon: ICONS.users,    hasAccount: false, accept: ".json", multiple: false, bundled: "Generated (30 contacts)",   upload: "Contacts JSON file" },
    { key: "appointments", label: "Appointments",  icon: ICONS.calendar, hasAccount: false, accept: ".json", multiple: false, bundled: "Generated (180 days)",      upload: "Appointments JSON file" },
    { key: "tasks",        label: "Tasks",         icon: ICONS.tasks,    hasAccount: false, accept: ".json", multiple: false, bundled: "Bundled tasks.json",        upload: "Tasks JSON file" },
    { key: "files",        label: "Files (Drive)", icon: ICONS.drive,    hasAccount: false, accept: "",      multiple: true,  bundled: "Bundled test files",       upload: "Select files" },
];

// Order operations run in; files last so the Drive check / skip is visible.
const RUN_ORDER = ["mails", "contacts", "appointments", "tasks", "files"];

let accounts = [];

// ---------- helpers ----------
const $ = (id) => document.getElementById(id);
const val = (id) => $(id).value.trim();

// Resolves the App Suite host: a preset value, or the custom text field.
function serverValue() {
    const sel = $("serverSelect");
    return sel.value === "custom" ? val("server") : sel.value;
}

function updateServerField() {
    const custom = $("serverSelect").value === "custom";
    // Toggle the cell's visibility (not display) so username/password stay on
    // their own row whether or not the URL field is shown.
    $("serverUrlField").classList.toggle("cell-hidden", !custom);
    if (custom) $("server").focus();
}

function credentials() {
    return {
        server: serverValue(),
        userName: val("userName"),
        password: val("password"),
        // Inverted in the UI: the checkbox asks to *ignore* invalid certificates.
        validateCertificate: !$("insecure").checked,
    };
}

function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result).split(",")[1]);
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}

// ---------- build category UI ----------
function buildCategories() {
    const host = $("categories");
    host.innerHTML = "";
    for (const cat of CATEGORIES) {
        const el = document.createElement("div");
        el.className = "category on";
        el.dataset.key = cat.key;

        const accountSelect = cat.hasAccount
            ? `<select class="cat-account" data-key="${cat.key}">${accounts.map(a => `<option ${a === DEFAULT_ACCOUNT ? "selected" : ""}>${a}</option>`).join("")}</select>`
            : "";

        const uploadControls = ALLOW_CUSTOM_UPLOAD ? `
                <div class="seg" data-key="${cat.key}">
                    <label class="active"><input type="radio" name="src-${cat.key}" value="bundled" checked>Bundled</label>
                    <label><input type="radio" name="src-${cat.key}" value="upload">Upload my own</label>
                </div>
                <input class="cat-files hidden" type="file" data-key="${cat.key}" accept="${cat.accept}" ${cat.multiple ? "multiple" : ""}>` : "";

        el.innerHTML = `
            <div class="category-head">
                <label class="category-title">
                    <span class="category-icon">${cat.icon}</span>
                    <span>${cat.label}</span>
                </label>
                <label class="checkbox">
                    <input type="checkbox" class="cat-enabled" data-key="${cat.key}" checked>
                    <span>Enabled</span>
                </label>
            </div>
            <div class="category-body">
                ${uploadControls}
                <span class="cat-bundled hint">${cat.bundled}</span>
                ${accountSelect}
            </div>`;
        host.appendChild(el);

        // enable/disable toggle
        const enabled = el.querySelector(".cat-enabled");
        enabled.addEventListener("change", () => {
            el.classList.toggle("on", enabled.checked);
            el.classList.toggle("off", !enabled.checked);
        });

        // source selector wiring (only present when uploads are enabled)
        const seg = el.querySelector(".seg");
        if (seg) {
            const bundledHint = el.querySelector(".cat-bundled");
            const fileInput = el.querySelector(".cat-files");
            const accountEl = el.querySelector(".cat-account");
            seg.querySelectorAll("input").forEach((radio) => {
                radio.addEventListener("change", () => {
                    seg.querySelectorAll("label").forEach(l => l.classList.remove("active"));
                    radio.parentElement.classList.add("active");
                    const upload = radio.value === "upload";
                    fileInput.classList.toggle("hidden", !upload);
                    bundledHint.classList.toggle("hidden", upload);
                    if (accountEl) accountEl.classList.toggle("hidden", upload);
                });
            });
        }
    }
}

async function selectionFor(cat) {
    const el = document.querySelector(`.category[data-key="${cat.key}"]`);
    const enabled = el.querySelector(".cat-enabled").checked;
    const accountEl = el.querySelector(".cat-account");

    const segInput = ALLOW_CUSTOM_UPLOAD ? el.querySelector(`input[name="src-${cat.key}"]:checked`) : null;
    const source = segInput ? segInput.value : "bundled";

    let files = null;
    if (source === "upload") {
        const fileInput = el.querySelector(".cat-files");
        if (fileInput && fileInput.files.length > 0) {
            files = [];
            for (const f of fileInput.files) {
                files.push({ name: f.name, base64: await fileToBase64(f) });
            }
        }
    }
    return {
        enabled,
        source,
        account: accountEl ? accountEl.value : null,
        files,
    };
}

// ---------- drive check ----------
async function checkDrive() {
    const pill = $("drivePill");
    const btn = $("checkDriveBtn");
    pill.className = "pill neutral";
    pill.textContent = "Checking…";
    pill.classList.remove("hidden");
    btn.disabled = true;
    try {
        const res = await fetch("/api/check-drive", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(credentials()),
        });
        if (!res.ok) throw new Error(await res.text());
        const data = await res.json();
        pill.className = data.enabled ? "pill ok" : "pill err";
        pill.textContent = data.enabled ? "Drive enabled" : "Drive NOT enabled";
    } catch (e) {
        pill.className = "pill err";
        pill.textContent = "Check failed";
    } finally {
        btn.disabled = false;
    }
}

// ---------- run ----------
function opRow(key) {
    return document.querySelector(`.op[data-key="${key}"]`);
}

function setupOperations(selectedKeys) {
    const host = $("operations");
    host.innerHTML = "";
    for (const key of RUN_ORDER) {
        if (!selectedKeys.includes(key)) continue;
        const cat = CATEGORIES.find(c => c.key === key);
        const el = document.createElement("div");
        el.className = "op";
        el.dataset.key = key;
        el.innerHTML = `
            <div class="op-head">
                <div class="op-name"><span class="category-icon">${cat.icon}</span><span>${cat.label}</span></div>
                <span class="op-status">Waiting</span>
            </div>
            <div class="op-msg"></div>
            <div class="bar"><span></span></div>`;
        host.appendChild(el);
    }
}

function updateOp(ev) {
    const el = opRow(ev.operation);
    if (!el) return;
    const status = el.querySelector(".op-status");
    const msg = el.querySelector(".op-msg");
    const bar = el.querySelector(".bar > span");

    if (ev.message) msg.textContent = ev.message;

    switch (ev.kind) {
        case "started":
            el.className = "op running";
            status.className = "op-status running";
            status.textContent = "Running";
            break;
        case "progress":
            if (ev.total > 0) bar.style.width = Math.round((ev.current / ev.total) * 100) + "%";
            break;
        case "finished":
            el.className = "op done";
            status.className = "op-status done";
            status.textContent = "Done";
            bar.style.width = "100%";
            break;
        case "failed":
            el.className = "op failed";
            if (el.dataset.key === "files") {
                status.className = "op-status skipped";
                status.textContent = "Skipped";
            } else {
                status.className = "op-status failed";
                status.textContent = "Failed";
            }
            break;
    }
}

function appendLog(ev, logId = "log", detailsId = "logDetails") {
    const log = $(logId);
    const prefix = ev.operation.startsWith("_") ? "" : `[${ev.operation}] `;
    log.textContent += `${prefix}${ev.message}\n`;
    log.scrollTop = log.scrollHeight;
    $(detailsId).classList.remove("hidden");
}

async function run() {
    const btn = $("runBtn");
    btn.disabled = true;

    // build request
    const request = { credentials: credentials() };
    const selectedKeys = [];
    for (const cat of CATEGORIES) {
        const sel = await selectionFor(cat);
        request[cat.key] = sel;
        if (sel.enabled) selectedKeys.push(cat.key);
    }

    if (selectedKeys.length === 0) {
        $("runStatus").textContent = "Select at least one category to seed.";
        btn.disabled = false;
        return;
    }

    setupOperations(selectedKeys);
    $("log").textContent = "";
    $("runStatus").textContent = "Running…";

    let jobId;
    try {
        const res = await fetch("/api/run", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(request),
        });
        if (!res.ok) throw new Error(await res.text());
        jobId = (await res.json()).jobId;
    } catch (e) {
        $("runStatus").textContent = "Could not start: " + e.message;
        btn.disabled = false;
        return;
    }

    const es = new EventSource(`/api/run/${jobId}/events`);
    es.onmessage = (e) => {
        const ev = JSON.parse(e.data);
        appendLog(ev);
        if (ev.operation === "_run" && ev.kind === "finished") {
            es.close();
            $("runStatus").textContent = "All done.";
            btn.disabled = false;
            return;
        }
        updateOp(ev);
    };
    es.onerror = () => {
        es.close();
        if (btn.disabled) {
            $("runStatus").textContent = "Connection to the server was lost.";
            btn.disabled = false;
        }
    };
}

// ---------- delete appointments ----------
function setupDeleteOperation() {
    $("deleteOperations").innerHTML = `
        <div class="op" data-key="delete">
            <div class="op-head">
                <div class="op-name"><span class="category-icon">${ICONS.calendar}</span><span>Delete appointments</span></div>
                <span class="op-status">Waiting</span>
            </div>
            <div class="op-msg"></div>
            <div class="bar"><span></span></div>
        </div>`;
}

async function deleteAppointments() {
    const years = parseInt($("deleteYears").value, 10);
    const who = val("userName") || "this user";
    if (!confirm(`Delete ALL appointments within ±${years} year(s) for ${who}?\n\nThis cannot be undone.`)) return;

    const btn = $("deleteBtn");
    btn.disabled = true;
    setupDeleteOperation();
    $("deleteLog").textContent = "";
    $("deleteStatus").textContent = "Deleting…";

    let jobId;
    try {
        const res = await fetch("/api/delete-appointments", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ credentials: credentials(), years }),
        });
        if (!res.ok) throw new Error(await res.text());
        jobId = (await res.json()).jobId;
    } catch (e) {
        $("deleteStatus").textContent = "Could not start: " + e.message;
        btn.disabled = false;
        return;
    }

    const es = new EventSource(`/api/run/${jobId}/events`);
    es.onmessage = (e) => {
        const ev = JSON.parse(e.data);
        appendLog(ev, "deleteLog", "deleteLogDetails");
        if (ev.operation === "_run" && ev.kind === "finished") {
            es.close();
            $("deleteStatus").textContent = "Done.";
            btn.disabled = false;
            return;
        }
        updateOp(ev);
    };
    es.onerror = () => {
        es.close();
        if (btn.disabled) {
            $("deleteStatus").textContent = "Connection to the server was lost.";
            btn.disabled = false;
        }
    };
}

// ---------- config / init ----------
async function loadConfig() {
    try {
        const res = await fetch("/api/config");
        const data = await res.json();
        accounts = data.accounts || [];
        if (!data.demoAvailable) {
            $("runStatus").textContent = "Warning: bundled demo data not found on the server.";
        }
    } catch (e) {
        accounts = [];
    }
    buildCategories();
}

$("serverSelect").addEventListener("change", updateServerField);
$("checkDriveBtn").addEventListener("click", checkDrive);
$("runBtn").addEventListener("click", run);
$("deleteBtn").addEventListener("click", deleteAppointments);
updateServerField();
loadConfig();
