<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { categoryLabel, demoSubmissions, projects, type Category, type CivicProject, type CivicSubmission, type SubmissionType } from './domain/demoData'
import { findMatches } from './domain/matching'

type Role = 'COMMUNITY_MEMBER' | 'GOVERNMENT_REVIEWER' | 'DEPARTMENT_OFFICIAL' | 'INVESTIGATOR' | 'AUDITOR' | 'ADMIN'
type Response = { id: string; reportId: string; author: string; text: string; date: string }
type Finding = { id: string; reportId: string; text: string; classification: string; date: string }
type Action = { id: string; reportId: string; title: string; status: string }
type Review = { id: string; reportId: string; projectId: string; status: 'CONFIRMED' | 'REJECTED'; reason: string }
type Report = CivicSubmission & { matchCandidates: string[]; investigationType: 'COMMUNITY_NEED' | 'PROJECT_ACCOUNTABILITY' | null; finding?: string; actions?: string[] }

const roles: Role[] = ['COMMUNITY_MEMBER', 'GOVERNMENT_REVIEWER', 'DEPARTMENT_OFFICIAL', 'INVESTIGATOR', 'AUDITOR', 'ADMIN']
const role = ref<Role>('COMMUNITY_MEMBER')
const activePage = ref('Overview')
const modalOpen = ref(false)
const activeReportId = ref<string | null>(null)
const search = ref('')
const projectStatusFilter = ref('ALL')
const projectCategoryFilter = ref('ALL')
const notice = ref('')
const currentDate = new Date().toISOString().slice(0, 10)
const demoItems = demoSubmissions.map((item, index): Report => ({
  ...item,
  matchCandidates: item.matches,
  investigationType: item.status === 'Under investigation' ? 'COMMUNITY_NEED' : item.status === 'Investigation opened' ? 'PROJECT_ACCOUNTABILITY' : null,
  status: item.status,
  ...(index === 1 ? { finding: 'Reported road delivery remains unverified; compare the original scope with an authorised inspection before drawing conclusions.' } : {})
}))
const reports = ref<Report[]>(load('civicproof-reports', demoItems))
const responses = ref<Response[]>(load('civicproof-responses', [
  { id: 'response-demo-1', reportId: 'demo-report-001', author: 'Public Lighting Department (synthetic)', text: 'Acknowledged. A technical assessment has been requested; this is not a resolution.', date: '2026-11-16' }
]))
const findings = ref<Finding[]>(load('civicproof-findings', []))
const actions = ref<Action[]>(load('civicproof-actions', []))
const reviews = ref<Review[]>(load('civicproof-reviews', []))
const form = ref({ type: 'COMMUNITY_NEED' as SubmissionType, category: 'PUBLIC_LIGHTING' as Category, title: '', description: '', area: 'Khayelitsha', location: '' })
const responseText = ref('')
const findingText = ref('')
const actionText = ref('')
const findingClass = ref('COMMUNITY_REPORTED')
const reportDetail = computed(() => reports.value.find(item => item.id === activeReportId.value) ?? null)
const openMatches = computed(() => reports.value.flatMap(report => report.matchCandidates.filter(id => !reviews.value.some(review => review.reportId === report.id && review.projectId === id)).map(projectId => ({ report, project: projects.find(item => item.id === projectId) })).filter(item => item.project)))
const shownReports = computed(() => reports.value.filter(item => `${item.title} ${item.area} ${categoryLabel(item.category)}`.toLowerCase().includes(search.value.toLowerCase())))
const shownProjects = computed(() => projects.filter(item => (projectStatusFilter.value === 'ALL' || item.status === projectStatusFilter.value) && (projectCategoryFilter.value === 'ALL' || item.category === projectCategoryFilter.value) && `${item.name} ${item.area}`.toLowerCase().includes(search.value.toLowerCase())))
const investigations = computed(() => reports.value.filter(item => item.investigationType))
const officialRoles: Role[] = ['DEPARTMENT_OFFICIAL', 'ADMIN']
const reviewerRoles: Role[] = ['GOVERNMENT_REVIEWER', 'ADMIN']
const investigatorRoles: Role[] = ['INVESTIGATOR', 'ADMIN']

function load<T>(key: string, fallback: T): T {
  try { const saved = localStorage.getItem(key); return saved ? JSON.parse(saved) as T : fallback }
  catch { return fallback }
}
watch(reports, value => localStorage.setItem('civicproof-reports', JSON.stringify(value)), { deep: true })
watch(responses, value => localStorage.setItem('civicproof-responses', JSON.stringify(value)), { deep: true })
watch(findings, value => localStorage.setItem('civicproof-findings', JSON.stringify(value)), { deep: true })
watch(actions, value => localStorage.setItem('civicproof-actions', JSON.stringify(value)), { deep: true })
watch(reviews, value => localStorage.setItem('civicproof-reviews', JSON.stringify(value)), { deep: true })

function flash(message: string) { notice.value = message; window.setTimeout(() => { if (notice.value === message) notice.value = '' }, 5500) }
function openReport(item: Report) { activeReportId.value = item.id; activePage.value = 'Community needs' }
function newReport() { modalOpen.value = true; activeReportId.value = null }
function submitReport() {
  if (form.value.title.trim().length < 3 || form.value.description.trim().length < 10 || !form.value.location.trim()) { flash('Add a title, a description of at least 10 characters, and a location.'); return }
  const areaProject = projects.find(item => item.area === form.value.area)!
  const match = findMatches({ type: form.value.type, category: form.value.category, description: `${form.value.title} ${form.value.description}`, area: form.value.area, latitude: areaProject.latitude, longitude: areaProject.longitude }, projects)
  const id = `report-${crypto.randomUUID()}`
  const noProject = match.status === 'NO_MATCH'
  const item: Report = {
    id, type: form.value.type, title: form.value.title.trim(), description: form.value.description.trim(), category: form.value.category, area: form.value.area,
    latitude: areaProject.latitude, longitude: areaProject.longitude, createdAt: currentDate,
    status: noProject && form.value.type === 'COMMUNITY_NEED' ? 'Under investigation' : match.status === 'NO_MATCH' ? 'Registered' : 'Match review',
    matches: match.candidates.map(candidate => candidate.project.id), matchCandidates: match.candidates.map(candidate => candidate.project.id),
    synthetic: true, investigationType: noProject && form.value.type === 'COMMUNITY_NEED' ? 'COMMUNITY_NEED' : null
  }
  reports.value.unshift(item)
  modalOpen.value = false
  form.value.title = ''; form.value.description = ''; form.value.location = ''
  activeReportId.value = id; activePage.value = 'Community needs'
  flash(noProject ? 'Report registered. No matching public project was identified in the records currently available.' : `${match.candidates.length} possible project match(es) suggested for human review.`)
}
function review(report: Report, project: CivicProject, decision: 'CONFIRMED' | 'REJECTED') {
  const reason = decision === 'CONFIRMED' ? 'Reviewer confirmed the relationship for investigation; the underlying report remains unverified.' : 'Reviewer rejected the suggested relationship; the community report remains registered.'
  reviews.value.unshift({ id: crypto.randomUUID(), reportId: report.id, projectId: project.id, status: decision, reason })
  if (decision === 'CONFIRMED') {
    report.investigationType = 'PROJECT_ACCOUNTABILITY'; report.status = 'Investigation opened'
    flash('Match confirmed. A project accountability investigation is open; this does not verify the allegation.')
  } else {
    report.matchCandidates = report.matchCandidates.filter(id => id !== project.id)
    report.matches = report.matches.filter(id => id !== project.id)
    if (!report.matchCandidates.length && report.type === 'COMMUNITY_NEED') { report.investigationType = 'COMMUNITY_NEED'; report.status = 'Under investigation' }
    else if (!report.matchCandidates.length) report.status = 'Registered'
    flash('Match rejected. Original submission preserved; the report remains registered.')
  }
}
function addResponse(report: Report) {
  if (!responseText.value.trim()) return
  responses.value.unshift({ id: crypto.randomUUID(), reportId: report.id, author: `${role.value.replaceAll('_', ' ')} (demo)`, text: responseText.value.trim(), date: currentDate })
  responseText.value = ''
  if (report.status === 'Registered') report.status = 'Awaiting response'
  flash('Response recorded in this browser demo. An acknowledgement does not resolve a need.')
}
function addFinding(report: Report) {
  if (!findingText.value.trim()) return
  findings.value.unshift({ id: crypto.randomUUID(), reportId: report.id, text: findingText.value.trim(), classification: findingClass.value, date: currentDate })
  findingText.value = ''
  report.finding = 'Finding recorded — see evidence classification below.'
  report.status = 'Finding recorded'
  flash('Finding recorded with its evidence classification.')
}
function addAction(report: Report) {
  if (!actionText.value.trim()) return
  actions.value.unshift({ id: crypto.randomUUID(), reportId: report.id, title: actionText.value.trim(), status: 'OPEN' })
  actionText.value = ''
  flash('Corrective action recorded.')
}
function resetDemo() {
  if (!window.confirm('Reset this browser’s synthetic demo reports, responses, reviews and investigations?')) return
  for (const key of ['civicproof-reports','civicproof-responses','civicproof-findings','civicproof-actions','civicproof-reviews']) localStorage.removeItem(key)
  reports.value = demoItems.map(item => ({ ...item, matchCandidates: [...item.matchCandidates], matches: [...item.matches] }))
  responses.value = [{ id: 'response-demo-1', reportId: 'demo-report-001', author: 'Public Lighting Department (synthetic)', text: 'Acknowledged. A technical assessment has been requested; this is not a resolution.', date: '2026-11-16' }]
  findings.value = []; actions.value = []; reviews.value = []; activeReportId.value = null
  flash('Synthetic demo data reset in this browser only.')
}
function go(page: string) { activePage.value = page; activeReportId.value = null; search.value = '' }
function projectById(id: string) { return projects.find(item => item.id === id) }
</script>

<template>
  <div class="app-shell">
    <aside class="sidebar">
      <button class="brand" @click="go('Overview')"><span class="brand-mark">C</span><span class="brand-word">Civic<strong>Proof</strong><small>PUBLIC ACCOUNTABILITY</small></span></button>
      <div class="nav-caption">DEMO WORKSPACE</div>
      <nav aria-label="Main navigation">
        <button v-for="page in ['Overview','Community needs','Projects','Match review','Investigations','Map']" :key="page" :class="['nav-link',{active:activePage===page}]" @click="go(page)"><span>{{ ({Overview:'◈','Community needs':'◎',Projects:'▤','Match review':'⌕',Investigations:'◷',Map:'⌖'} as Record<string,string>)[page] }}</span>{{ page }}<b v-if="page==='Match review' && openMatches.length">{{ openMatches.length }}</b></button>
      </nav>
      <div class="sidebar-spacer"></div>
      <div class="side-note"><span>✦</span><strong>Community-led insight</strong><p>Residents report their reality. Project matches are suggestions, never proof.</p><button @click="newReport">＋ Share a need</button></div>
      <label class="role-select"><small>DEMO ROLE — NOT AUTHENTICATION</small><select v-model="role" aria-label="Switch demo role"><option v-for="item in roles" :key="item" :value="item">{{ item.replaceAll('_',' ') }}</option></select></label>
      <div class="side-user"><span class="avatar">{{ role==='COMMUNITY_MEMBER'?'CM':role.slice(0,2) }}</span><span><strong>{{ role.replaceAll('_',' ') }}</strong><small>Local demo session</small></span></div>
    </aside>
    <main class="main-area">
      <header class="topbar"><div><span class="muted">Workspace</span><span class="slash">/</span><strong>{{ activePage }}</strong></div><div class="top-right"><span class="synthetic-label"><i></i>SYNTHETIC DEMO DATA</span><button class="role-compact" @click="go('Admin')">{{ role.replaceAll('_',' ') }}</button></div></header>
      <div class="content">
        <template v-if="activePage==='Overview'">
          <div class="page-head"><div><div class="eyebrow">CAPE TOWN · DEMONSTRATION ONLY</div><h1>Your community, your voice.</h1><p>Connect reported needs with public project records and visible follow-up.</p></div><button class="primary-btn" @click="newReport">＋ Report a need</button></div>
          <div class="notice-banner"><strong>Demo dataset:</strong> every project, person, location detail and response here is synthetic—not City of Cape Town data.</div>
          <section class="stats"><article><span>Community reports</span><strong>{{ reports.length.toString().padStart(2,'0') }}</strong><small>Preserved as submitted</small></article><article><span>Projects in progress</span><strong>{{ projects.filter(p=>p.status==='IN_PROGRESS').length.toString().padStart(2,'0') }}</strong><small>Fictional demo records</small></article><article><span>Needs / investigations</span><strong>{{ investigations.length.toString().padStart(2,'0') }}</strong><small>{{ openMatches.length }} match(es) awaiting review</small></article></section>
          <div class="grid-two">
            <section class="panel"><div class="panel-head"><div><div class="eyebrow">COMMUNITY VOICE</div><h2>Recent reports</h2></div><button class="text-btn" @click="go('Community needs')">View all →</button></div>
              <button v-for="item in reports.slice(0,5)" :key="item.id" class="report-row" @click="openReport(item)"><span class="row-icon">{{ item.type==='COMMUNITY_NEED'?'＋':'◉' }}</span><span class="row-main"><strong>{{ item.title }}</strong><small>{{ item.area }} · {{ categoryLabel(item.category) }}</small></span><span class="status-tag">{{ item.status }}</span><span class="arrow">↗</span></button>
            </section>
            <section class="panel focus-panel"><div class="eyebrow">HOW CIVICPROOF WORKS</div><h2>Start with lived experience.</h2><p>Report a need or observation without a project ID. The report is registered first; potential matches are reviewed separately.</p><div class="flow"><span>Report</span><i>→</i><span>Suggest</span><i>→</i><span>Review</span><i>→</i><span>Follow up</span></div><div class="fineprint">No match found means no relevant record was identified in available data. It does not prove that no project exists.</div></section>
          </div>
          <section class="panel project-panel"><div class="panel-head"><div><div class="eyebrow">SYNTHETIC PROJECT REGISTER</div><h2>Projects in the demo</h2></div><button class="text-btn" @click="go('Projects')">Browse 18 projects →</button></div><div class="project-strip"><article v-for="project in projects.slice(0,4)" :key="project.id"><span class="project-type">{{ categoryLabel(project.category) }}</span><strong>{{ project.name }}</strong><small>{{ project.area }} · {{ project.status.replace('_',' ') }}</small><div class="progress"><i :style="{width:`${project.progress}%`}"></i></div></article></div></section>
        </template>
        <template v-else-if="activePage==='Community needs'">
          <div class="page-head"><div><div class="eyebrow">REGISTERED WITHOUT PROJECT APPROVAL</div><h1>Community needs & reports</h1><p>Each submission remains intact even when matches are rejected.</p></div><button class="primary-btn" @click="newReport">＋ New submission</button></div>
          <section v-if="reportDetail" class="panel detail-panel"><button class="text-btn back-btn" @click="activeReportId=null">← All reports</button><div class="detail-heading"><div><span class="evidence-badge">COMMUNITY REPORTED</span><span class="status-tag">{{ reportDetail.status }}</span><h2>{{ reportDetail.title }}</h2><p>{{ reportDetail.description }}</p></div><span class="detail-location">⌖ {{ reportDetail.area }} · {{ categoryLabel(reportDetail.category) }}</span></div>
            <div class="caution"><strong>Evidence note</strong> This is a community-reported claim, not an independently verified finding. “No matching public record found” is limited to the data currently available.</div>
            <div class="detail-grid"><div><h3>Suggested project records</h3><div v-if="reportDetail.matchCandidates.length" class="candidate-list"><article v-for="id in reportDetail.matchCandidates" :key="id" class="candidate"><template v-if="projectById(id)"><strong>{{ projectById(id)?.name }}</strong><small>{{ projectById(id)?.area }} · {{ categoryLabel(projectById(id)!.category) }} · {{ projectById(id)?.status.replace('_',' ') }}</small><p>Heuristic candidate based on category, area, text and approximate coordinates. Score is not a probability.</p></template><span v-else>Project record unavailable</span></article></div><p v-else class="muted-paragraph">No candidate identified in available synthetic records. The community report remains registered.</p></div>
              <div><h3>Responses</h3><article v-for="item in responses.filter(x=>x.reportId===reportDetail!.id)" :key="item.id" class="timeline-entry"><strong>{{ item.author }}</strong><p>{{ item.text }}</p><small>{{ item.date }} · Official response (demo)</small></article><p v-if="!responses.some(x=>x.reportId===reportDetail!.id)" class="muted-paragraph">No response recorded yet.</p><form v-if="officialRoles.includes(role)" class="inline-form" @submit.prevent="addResponse(reportDetail!)"><textarea v-model="responseText" required placeholder="Record an acknowledgement, referral or next step"></textarea><button class="primary-btn small-btn">Record response</button></form></div></div>
            <div v-if="reportDetail.investigationType" class="investigation-box"><div class="panel-head"><div><div class="eyebrow">{{ reportDetail.investigationType==='COMMUNITY_NEED'?'UNMATCHED COMMUNITY NEED':'CONFIRMED PROJECT RELATIONSHIP' }}</div><h3>{{ reportDetail.investigationType.replace('_',' ') }} investigation</h3></div><span class="status-tag">{{ reportDetail.status }}</span></div><p>Opening an investigation records a follow-up workflow; it does not determine whether an allegation is true.</p>
              <div v-for="finding in findings.filter(x=>x.reportId===reportDetail!.id)" :key="finding.id" class="timeline-entry"><strong>Finding · {{ finding.classification.replaceAll('_',' ') }}</strong><p>{{ finding.text }}</p><small>{{ finding.date }}</small></div>
              <form v-if="investigatorRoles.includes(role)" class="inline-form" @submit.prevent="addFinding(reportDetail!)"><select v-model="findingClass"><option>COMMUNITY_REPORTED</option><option>SYSTEM_IDENTIFIED</option><option>OFFICIALLY_RECORDED</option><option>HUMAN_REVIEWED</option><option>INDEPENDENTLY_VERIFIED</option><option>OFFICIALLY_CONFIRMED</option></select><textarea v-model="findingText" required placeholder="Record finding and the evidence basis"></textarea><button class="primary-btn small-btn">Record classified finding</button></form>
              <h4>Corrective actions</h4><div v-for="action in actions.filter(x=>x.reportId===reportDetail!.id)" :key="action.id" class="action-row"><span>{{ action.title }}</span><button class="status-tag" @click="action.status=action.status==='OPEN'?'COMPLETE':'OPEN'">{{ action.status }}</button></div><form v-if="investigatorRoles.includes(role)" class="inline-form action-form" @submit.prevent="addAction(reportDetail!)"><input v-model="actionText" required placeholder="Describe a follow-up action"/><button class="secondary-btn small-btn">＋ Add action</button></form>
            </div>
          </section>
          <section v-else class="panel list-panel"><div class="panel-head"><div><div class="eyebrow">ALL SUBMISSIONS</div><h2>{{ shownReports.length }} community reports</h2></div><input v-model="search" class="search" placeholder="Search reports"/></div><button v-for="item in shownReports" :key="item.id" class="report-row" @click="openReport(item)"><span class="row-icon">{{ item.type==='COMMUNITY_NEED'?'＋':'◉' }}</span><span class="row-main"><strong>{{ item.title }}</strong><small>{{ item.area }} · {{ categoryLabel(item.category) }} · {{ item.createdAt }}</small></span><span class="status-tag">{{ item.status }}</span><span class="arrow">↗</span></button></section>
        </template>
        <template v-else-if="activePage==='Projects'"><div class="page-head"><div><div class="eyebrow">FICTIONAL REGISTER · NOT MUNICIPAL DATA</div><h1>Public projects</h1><p>Approximate demo locations. These are not verified infrastructure boundaries.</p></div></div><section class="panel list-panel"><div class="panel-head filters"><input v-model="search" class="search" placeholder="Search project or area"/><select v-model="projectStatusFilter"><option value="ALL">All statuses</option><option value="PLANNED">Planned</option><option value="IN_PROGRESS">In progress</option><option value="COMPLETED">Completed</option></select><select v-model="projectCategoryFilter"><option value="ALL">All categories</option><option v-for="category in (['ROADS_TRANSPORT','PUBLIC_LIGHTING','WATER','SANITATION','STORMWATER','WASTE_MANAGEMENT','PUBLIC_FACILITIES'] as Category[])" :key="category" :value="category">{{ categoryLabel(category) }}</option></select></div><article v-for="project in shownProjects" :key="project.id" class="project-row"><div><strong>{{ project.name }}</strong><small>{{ project.area }} · {{ categoryLabel(project.category) }}</small><p>{{ project.description }} Scope: {{ project.scope }}.</p></div><div class="project-meta"><span class="status-tag">{{ project.status.replace('_',' ') }}</span><strong>{{ project.progress }}%</strong></div><div class="progress"><i :style="{width:`${project.progress}%`}"></i></div><small>Synthetic demo record · Estimated value R {{ project.budget?.toLocaleString('en-ZA') }} · source: SYNTHETIC_DEMO_DATA</small></article></section></template>
        <template v-else-if="activePage==='Match review'"><div class="page-head"><div><div class="eyebrow">AUTHORISED DEMO REVIEW</div><h1>Potential matches</h1><p>A suggested relationship is not confirmed, and does not prove the report’s allegation.</p></div></div><div v-if="!reviewerRoles.includes(role)" class="notice-banner">Switch the demo role to GOVERNMENT REVIEWER to access match decisions. This role selector is a demo convenience, not security.</div><section v-for="item in openMatches" :key="`${item.report.id}-${item.project!.id}`" class="panel review-card"><span class="evidence-badge">COMMUNITY REPORTED</span><h2>{{ item.report.title }}</h2><p>{{ item.report.description }}</p><div class="candidate"><strong>{{ item.project!.name }}</strong><small>{{ item.project!.area }} · {{ categoryLabel(item.project!.category) }} · {{ item.project!.status.replace('_',' ') }}</small><p>Reasons: {{ item.project!.category===item.report.category?'category match · ':'' }}area and approximate-location proximity; some report/project terms may overlap.</p></div><div v-if="reviewerRoles.includes(role)" class="review-buttons"><button class="secondary-btn" @click="review(item.report,item.project!,'REJECTED')">Reject suggestion</button><button class="primary-btn" @click="review(item.report,item.project!,'CONFIRMED')">Confirm relationship</button></div></section><div v-if="!openMatches.length" class="empty">No suggested matches awaiting a decision.</div><section v-if="reviews.length" class="panel"><h2>Review history</h2><article v-for="item in reviews" :key="item.id" class="history-row"><span>{{ item.status }}</span><strong>{{ reports.find(r=>r.id===item.reportId)?.title }}</strong><small>{{ item.reason }}</small></article></section></template>
        <template v-else-if="activePage==='Investigations'"><div class="page-head"><div><div class="eyebrow">FOLLOW-UP AND EVIDENCE</div><h1>Investigations</h1><p>Community-need follow-up is separate from project accountability investigation.</p></div></div><section v-if="investigations.length" class="panel list-panel"><button v-for="item in investigations" :key="item.id" class="report-row" @click="openReport(item)"><span class="row-icon">◷</span><span class="row-main"><strong>{{ item.title }}</strong><small>{{ item.investigationType?.replace('_',' ') }} · {{ item.area }} · evidence: community-reported</small></span><span class="status-tag">{{ item.status }}</span></button></section><div v-else class="empty">No investigations. A community need with no suggested project still qualifies for follow-up.</div></template>
        <template v-else-if="activePage==='Map'"><div class="page-head"><div><div class="eyebrow">APPROXIMATE SYNTHETIC LOCATIONS</div><h1>Community map</h1><p>Markers are illustrative, not verified infrastructure boundaries or official records.</p></div></div><section class="panel map-panel"><div class="map-legend"><span><i class="project-dot"></i> Synthetic project</span><span><i class="report-dot"></i> Community report</span></div><div class="map-canvas"><span v-for="(item,index) in projects" :key="item.id" class="map-marker project-marker" :title="item.name+' — synthetic'" :style="{left:`${7+(index*37%86)}%`,top:`${10+(index*53%76)}%`}">✦</span><span v-for="(item,index) in reports" :key="item.id" class="map-marker report-marker" :title="item.title+' — community reported'" :style="{left:`${10+(index*61%80)}%`,top:`${13+(index*43%72)}%`}">●</span><div class="map-label">CAPE TOWN<small>SYNTHETIC DEMO LOCATIONS</small></div></div><p class="muted-paragraph">Approximate fictional locations only. A map marker is not a verified project boundary.</p></section></template>
        <template v-else><div class="page-head"><div><div class="eyebrow">DEMO ADMINISTRATION</div><h1>Demo data & setup</h1><p>Use the role selector for demonstration only. Browser data is not shared across devices.</p></div></div><section class="panel admin-panel"><h2>Safety and data provenance</h2><p>All current projects and seeded submissions are synthetic. New reports entered in this offline demo are stored in this browser’s local storage and marked synthetic.</p><p>No Supabase project is configured automatically. The schema migrations are a starting point for a separately configured backend.</p><button v-if="role==='ADMIN'" class="danger-btn" @click="resetDemo">Reset synthetic data in this browser</button><div v-else class="notice-banner">Switch the demo role to ADMIN to reveal the local-only reset action.</div></section><section class="panel"><h2>Evidence classifications</h2><p>COMMUNITY_REPORTED · SYSTEM_IDENTIFIED · OFFICIALLY_RECORDED · HUMAN_REVIEWED · INDEPENDENTLY_VERIFIED · OFFICIALLY_CONFIRMED</p><p class="muted-paragraph">Classification is a recorded label, not automatic verification. A match confirmation does not verify the underlying claim.</p></section></template>
      </div>
    </main>
    <div v-if="modalOpen" class="overlay" @click.self="modalOpen=false"><section class="modal" role="dialog" aria-modal="true" aria-labelledby="report-title"><button class="close" aria-label="Close" @click="modalOpen=false">×</button><div class="eyebrow">COMMUNITY SUBMISSION · NO PROJECT ID REQUIRED</div><h2 id="report-title">Report a need or observation</h2><p>Government approval and proof of residence are not required to register a community concern.</p><form @submit.prevent="submitReport"><label>Report type<select v-model="form.type"><option value="COMMUNITY_NEED">Community need</option><option value="SERVICE_OBSERVATION">Service observation</option></select></label><label>Category<select v-model="form.category"><option v-for="category in (['PUBLIC_LIGHTING','ROADS_TRANSPORT','WATER','SANITATION','STORMWATER','WASTE_MANAGEMENT','PUBLIC_FACILITIES'] as Category[])" :key="category" :value="category">{{ categoryLabel(category) }}</option></select></label><label>Title<input v-model="form.title" required minlength="3" maxlength="160" placeholder="What is needed or observed?"/></label><label>Description<textarea v-model="form.description" required minlength="10" maxlength="10000" rows="4" placeholder="Describe the need or service concern"></textarea></label><label>Area<select v-model="form.area"><option v-for="area in [...new Set(projects.map(p=>p.area))]" :key="area">{{ area }}</option></select></label><label>Location details<input v-model="form.location" required placeholder="Street, landmark or nearby place"/></label><div class="caution">Evidence upload is not configured in this browser-only demo. You can submit without photos or video.</div><button class="primary-btn submit-btn">Register report</button></form></section></div>
    <div v-if="notice" class="toast" role="status">{{ notice }}<button aria-label="Dismiss" @click="notice=''">×</button></div>
    <footer class="app-footer">CivicProof is a hackathon demo, not an official government service. Synthetic data only. Irregular expenditure or delivery discrepancies are not proof of theft or corruption.</footer>
  </div>
</template>
