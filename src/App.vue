<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { categoryLabel, demoSubmissions, type Category } from './domain/demoData'
import { filterReportsForOwner, type OwnedReport } from './domain/reportVisibility'

type Role = 'COMMUNITY_MEMBER' | 'GOVERNMENT_REVIEWER' | 'DEPARTMENT_OFFICIAL' | 'INVESTIGATOR' | 'AUDITOR' | 'ADMIN'
const roles: Role[] = ['COMMUNITY_MEMBER', 'GOVERNMENT_REVIEWER', 'DEPARTMENT_OFFICIAL', 'INVESTIGATOR', 'AUDITOR', 'ADMIN']
const ownerId = 'demo-community-member'
const role = ref<Role>('COMMUNITY_MEMBER')
const page = ref('My needs')
const notice = ref('')
const showForm = ref(false)
const reportDetail = ref<OwnedReport | null>(null)
const categoryOptions: Category[] = ['PUBLIC_LIGHTING', 'ROADS_TRANSPORT', 'WATER', 'SANITATION', 'STORMWATER', 'WASTE_MANAGEMENT', 'PUBLIC_FACILITIES']
const seededReports: OwnedReport[] = demoSubmissions.map(item => ({ ...item, ownerId: null }))
function loadReports(): OwnedReport[] {
  try {
    const stored = localStorage.getItem('civicproof-reports')
    return stored ? JSON.parse(stored) as OwnedReport[] : seededReports
  } catch { return seededReports }
}
const reports = ref<OwnedReport[]>(loadReports())
const myReports = computed(() => filterReportsForOwner(reports.value, ownerId))
const isCommunity = computed(() => role.value === 'COMMUNITY_MEMBER')
const form = ref({ title: '', description: '', category: 'PUBLIC_LIGHTING' as Category, area: '', location: '' })
const areas = [...new Set(demoSubmissions.map(item => item.area))]
const visibleReports = computed(() => isCommunity.value ? myReports.value : reports.value)

watch(reports, value => localStorage.setItem('civicproof-reports', JSON.stringify(value)), { deep: true })
watch(role, value => {
  reportDetail.value = null
  page.value = value === 'COMMUNITY_MEMBER' ? 'My needs' : 'All submissions'
})
function flash(message: string) {
  notice.value = message
  window.setTimeout(() => { if (notice.value === message) notice.value = '' }, 5000)
}
function submitNeed() {
  if (form.value.title.trim().length < 3 || form.value.description.trim().length < 10 || !form.value.area || !form.value.location.trim()) {
    flash('Please complete each field. Titles need 3+ characters and descriptions need 10+ characters.')
    return
  }
  const sample = demoSubmissions.find(item => item.area === form.value.area) ?? demoSubmissions[0]!
  const need: OwnedReport = {
    id: `report-${crypto.randomUUID()}`,
    type: 'COMMUNITY_NEED', title: form.value.title.trim(), description: form.value.description.trim(), category: form.value.category,
    area: form.value.area, latitude: sample.latitude, longitude: sample.longitude, createdAt: new Date().toISOString().slice(0, 10),
    status: 'Registered', matches: [], ownerId
  }
  reports.value = [need, ...reports.value]
  reportDetail.value = need
  showForm.value = false
  form.value = { title: '', description: '', category: 'PUBLIC_LIGHTING', area: '', location: '' }
  flash('Your need has been registered. It is visible here only in this browser demo.')
}
function openReport(item: OwnedReport) {
  // Re-check ownership at the point of access, not only when building the list.
  if (isCommunity.value && item.ownerId !== ownerId) return
  reportDetail.value = item
}
</script>

<template>
  <div class="privacy-app">
    <aside class="sidebar">
      <div class="brand"><span class="brand-mark">C</span><span>Civic<strong>Proof</strong><small>PUBLIC ACCOUNTABILITY</small></span></div>
      <p class="workspace-label">{{ isCommunity ? 'COMMUNITY SPACE' : 'STAFF DEMO WORKSPACE' }}</p>
      <nav aria-label="Main navigation">
        <button v-if="isCommunity" :class="['nav-item',{active:page==='My needs'}]" @click="page='My needs';reportDetail=null">My needs</button>
        <template v-else>
          <button :class="['nav-item',{active:page==='All submissions'}]" @click="page='All submissions';reportDetail=null">All submissions</button>
          <button class="nav-item" @click="page='My needs';reportDetail=null">Community-member preview</button>
        </template>
      </nav>
      <div class="sidebar-bottom">
        <span class="demo-tag">DEMO ROLE · NOT AUTHENTICATION</span>
        <label for="role-select">Preview as</label>
        <select id="role-select" v-model="role"><option v-for="item in roles" :key="item" :value="item">{{ item.replaceAll('_',' ') }}</option></select>
        <p>Role switching is a local demonstration convenience, not a security control.</p>
      </div>
    </aside>

    <main class="main-area">
      <header class="topbar"><span>{{ isCommunity ? 'Community space / My needs' : `Staff demo / ${page}` }}</span><span class="demo-tag">SYNTHETIC BROWSER DEMO</span></header>
      <div class="content">
        <template v-if="isCommunity">
          <section class="heading-row"><div><div class="eyebrow">PRIVATE TO YOUR DEMO PROFILE</div><h1>My community needs</h1><p>Report a need and follow the status of submissions you created.</p></div><button class="primary" @click="showForm=true">＋ Report a need</button></section>
          <div class="privacy-note"><strong>Your view is limited:</strong> other residents’ submissions, project registers, match suggestions, investigations, staff notes and other people’s evidence are not shown here.</div>
          <section v-if="reportDetail && reportDetail.ownerId===ownerId" class="panel detail">
            <button class="back" @click="reportDetail=null">← Back to my needs</button>
            <div class="eyebrow">YOUR SUBMISSION · {{ reportDetail.createdAt }}</div><h2>{{ reportDetail.title }}</h2>
            <div class="summary"><span>{{ categoryLabel(reportDetail.category) }}</span><span>{{ reportDetail.area }}</span><span class="status">{{ reportDetail.status }}</span></div>
            <p class="description">{{ reportDetail.description }}</p>
            <p class="status-help">This is the status recorded for your submission. Staff-only review notes and project matching details are not part of this view.</p>
          </section>
          <section v-else class="panel needs-panel"><div class="panel-heading"><div><div class="eyebrow">SUBMISSIONS YOU CREATED</div><h2>Your existing needs</h2></div><span class="count">{{ myReports.length }}</span></div>
            <div v-if="myReports.length" class="needs-list"><button v-for="item in myReports" :key="item.id" class="need-row" @click="openReport(item)"><span class="need-icon">＋</span><span class="need-main"><strong>{{ item.title }}</strong><small>{{ categoryLabel(item.category) }} · {{ item.area }} · {{ item.createdAt }}</small></span><span class="status">{{ item.status }}</span><span aria-hidden="true">›</span></button></div>
            <div v-else class="empty-state"><span class="empty-icon">＋</span><h3>No needs submitted yet</h3><p>Use “Report a need” to send your first community need. Once submitted, it will appear here for you to follow.</p><button class="secondary" @click="showForm=true">Report your first need</button></div>
          </section>
        </template>
        <template v-else>
          <section class="heading-row"><div><div class="eyebrow">STAFF VIEW · SYNTHETIC DEMO</div><h1>All submissions</h1><p>Staff preview only. Role switching is not authentication; do not use this demo for real data.</p></div></section>
          <section class="panel needs-panel"><div class="panel-heading"><div><div class="eyebrow">ALL DEMO SUBMISSIONS</div><h2>{{ visibleReports.length }} submissions</h2></div></div><div class="needs-list"><button v-for="item in visibleReports" :key="item.id" class="need-row" @click="openReport(item)"><span class="need-icon">＋</span><span class="need-main"><strong>{{ item.title }}</strong><small>{{ item.area }} · {{ item.ownerId ? 'Community member' : 'Seeded synthetic report' }}</small></span><span class="status">{{ item.status }}</span></button></div></section>
        </template>
      </div>
    </main>

    <div v-if="showForm" class="overlay" @click.self="showForm=false"><section class="dialog" role="dialog" aria-modal="true" aria-labelledby="need-form-title"><button class="close" aria-label="Close" @click="showForm=false">×</button><div class="eyebrow">COMMUNITY SUBMISSION</div><h2 id="need-form-title">Report a community need</h2><p>You can submit a need without knowing a project ID or proving residency.</p><form @submit.prevent="submitNeed"><label>Need title<input v-model="form.title" required minlength="3" maxlength="160" placeholder="What does your community need?"/></label><label>Category<select v-model="form.category"><option v-for="category in categoryOptions" :key="category" :value="category">{{ categoryLabel(category) }}</option></select></label><label>Description<textarea v-model="form.description" required minlength="10" maxlength="10000" rows="4" placeholder="Describe the need"></textarea></label><label>Area<select v-model="form.area" required><option disabled value="">Choose an area</option><option v-for="area in areas" :key="area" :value="area">{{ area }}</option></select></label><label>Nearby location<input v-model="form.location" required maxlength="200" placeholder="Street, landmark or nearby place"/></label><p class="form-note">Your report is saved in this browser demo. It is not sent to a government office.</p><button class="primary submit">Submit need</button></form></section></div>
    <div v-if="notice" class="toast" role="status">{{ notice }}<button aria-label="Dismiss" @click="notice=''">×</button></div>
    <footer>Browser demo only · No real authentication, backend access control or data transmission is configured.</footer>
  </div>
</template>

<style scoped>
.privacy-app{min-height:100vh;background:#f5f7f4;color:#26372e;font:14px 'DM Sans',Arial,sans-serif}.sidebar{position:fixed;inset:0 auto 0 0;width:245px;background:#102b24;color:#edf5ef;padding:24px 18px;display:flex;flex-direction:column}.brand{display:flex;align-items:center;gap:11px;font-size:17px;font-weight:700}.brand strong{color:#d9f36b}.brand small{display:block;color:#9eb4a9;font-size:8px;letter-spacing:1px;margin-top:4px}.brand-mark{width:36px;height:36px;border-radius:10px;background:#d9f36b;color:#173729;display:grid;place-items:center;font-size:19px;font-weight:800}.workspace-label,.eyebrow{font-size:9px;letter-spacing:1px;font-weight:700;color:#829187}.workspace-label{margin:38px 8px 12px;color:#91aaa0}.sidebar nav{display:grid;gap:6px}.nav-item{border:0;background:transparent;color:#c6d3cb;text-align:left;padding:11px;border-radius:6px;cursor:pointer;font-size:11px}.nav-item.active,.nav-item:hover{background:#1b4034;color:white}.sidebar-bottom{margin-top:auto;border-top:1px solid #2c493d;padding-top:16px}.demo-tag{display:inline-block;background:#edf3df;color:#657b41;border-radius:4px;padding:5px 7px;font-size:8px;font-weight:700;letter-spacing:.4px}.sidebar-bottom label{display:block;margin:14px 0 6px;font-size:9px;color:#bfcec5}.sidebar-bottom select{width:100%;padding:8px;background:#193a2f;color:white;border:1px solid #3c594c;border-radius:5px;font-size:9px}.sidebar-bottom p{font-size:8px;color:#a6b8ae;line-height:1.5}.main-area{margin-left:245px;min-height:100vh;padding-bottom:48px}.topbar{height:56px;background:#fff;border-bottom:1px solid #e6ebe6;padding:0 34px;display:flex;align-items:center;justify-content:space-between;font-size:10px;color:#738078}.content{max-width:1050px;margin:auto;padding:38px 34px}.heading-row{display:flex;align-items:center;justify-content:space-between;gap:20px;margin-bottom:20px}.heading-row .eyebrow{color:#839086}.heading-row h1{font-size:26px;letter-spacing:-.7px;margin:7px 0;color:#20352a}.heading-row p{font-size:11px;color:#78857d;margin:0}.primary,.secondary{border:0;border-radius:5px;padding:11px 14px;background:#244a38;color:#fff;font-size:10px;font-weight:700;cursor:pointer}.primary:hover{background:#173d2d}.secondary{background:white;border:1px solid #dfe6df;color:#476049}.privacy-note{padding:13px 15px;background:#f3f5e9;border:1px solid #e7e9d8;border-radius:6px;color:#6b7256;font-size:10px;line-height:1.55;margin-bottom:15px}.panel{background:#fff;border:1px solid #e6ebe6;border-radius:8px;padding:19px}.panel-heading{display:flex;align-items:center;justify-content:space-between;margin-bottom:10px}.panel-heading h2{margin:5px 0 0;font-size:15px}.count{min-width:28px;height:28px;display:grid;place-items:center;border-radius:50%;background:#eef3e7;color:#627a43;font-weight:700;font-size:10px}.need-row{width:100%;display:flex;align-items:center;gap:12px;padding:13px 2px;background:#fff;border:0;border-top:1px solid #edf0ed;text-align:left;color:#39483e;cursor:pointer}.need-row:hover{background:#fafbf8}.need-icon{width:31px;height:31px;display:grid;place-items:center;border-radius:7px;background:#f0f4e8;color:#81984f}.need-main{flex:1;min-width:0}.need-main strong,.need-main small{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.need-main strong{font-size:10px}.need-main small{font-size:8px;color:#859087;margin-top:4px}.status{border-radius:12px;background:#f1f3ee;color:#68776c;padding:5px 8px;font-size:8px}.empty-state{text-align:center;padding:45px 20px 34px;border-top:1px solid #edf0ed}.empty-icon{margin:auto;width:42px;height:42px;border-radius:50%;background:#f0f4e8;color:#70864b;display:grid;place-items:center;font-size:22px}.empty-state h3{margin:12px 0 5px;font-size:13px}.empty-state p{max-width:370px;margin:0 auto 15px;color:#78857d;font-size:10px;line-height:1.6}.detail{max-width:760px}.back{border:0;background:none;color:#627d4d;font-size:10px;padding:0;margin-bottom:22px;cursor:pointer}.detail h2{font-size:20px;margin:8px 0}.summary{display:flex;align-items:center;gap:8px;color:#76837a;font-size:9px}.description{font-size:12px;line-height:1.7;color:#4e5e54;margin-top:22px}.status-help,.form-note{font-size:9px;line-height:1.6;color:#77837b;background:#f6f8f5;padding:10px;border-radius:5px}.overlay{position:fixed;inset:0;background:#10251f9c;z-index:5;display:grid;place-items:center;padding:16px}.dialog{position:relative;width:min(500px,100%);max-height:94vh;overflow:auto;background:white;border-radius:9px;padding:25px}.dialog h2{margin:7px 0;font-size:19px}.dialog>p{font-size:10px;color:#77837b}.close{position:absolute;right:13px;top:10px;border:0;background:none;font-size:23px;color:#718077;cursor:pointer}.dialog form{display:grid;gap:11px;margin-top:17px}.dialog label{display:grid;gap:5px;font-size:9px;font-weight:600;color:#526157}.dialog input,.dialog select,.dialog textarea{width:100%;border:1px solid #dfe6df;border-radius:5px;padding:9px;font:10px Arial,sans-serif;color:#35443a;background:white}.dialog textarea{resize:vertical}.form-note{margin:0}.submit{width:100%}.toast{position:fixed;right:20px;bottom:42px;z-index:8;max-width:420px;padding:12px 14px;background:#18392d;color:white;border-radius:6px;font-size:10px;display:flex;gap:12px;align-items:center}.toast button{border:0;background:none;color:white;font-size:17px}footer{position:fixed;bottom:0;left:245px;right:0;text-align:center;padding:9px;background:#f5f7f4;color:#8b958e;font-size:8px}@media(max-width:700px){.sidebar{position:static;width:auto;padding:12px 15px;display:flex;flex-direction:row;align-items:center;gap:14px}.brand{font-size:14px}.brand small,.workspace-label,.sidebar-bottom{display:none}.sidebar nav{display:flex;margin-left:auto}.nav-item{padding:8px;font-size:9px}.main-area{margin:0}.topbar{height:43px;padding:0 14px}.content{padding:25px 14px}.heading-row{align-items:flex-start}.heading-row h1{font-size:21px}.heading-row>.primary{white-space:nowrap;padding:9px;font-size:9px}.need-row{gap:7px}.need-main strong{font-size:9px}.status{font-size:7px;padding:4px 6px}.main-area{padding-bottom:0}footer{position:static;font-size:7px}.topbar .demo-tag{font-size:6px}}
</style>
