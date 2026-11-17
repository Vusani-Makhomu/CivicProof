<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const user = computed(() => {
  const raw = localStorage.getItem('civicproof-demo-user')
  return raw ? JSON.parse(raw) : null
})

function signOut() {
  localStorage.removeItem('civicproof-demo-user')
  router.push('/login')
}

const modules = [
  'Dashboard',
  'Community needs',
  'Projects',
  'Match review',
  'Investigations',
  'Map'
]
</script>

<template>
  <div class="dashboard-shell">
    <aside class="sidebar">
      <div class="brand">
        <div class="brand-mark">C</div>
        <div>
          <strong>CivicProof</strong>
          <small>Demo</small>
        </div>
      </div>

      <nav>
        <button v-for="module in modules" :key="module" class="nav-item">{{ module }}</button>
      </nav>

      <div class="session-card">
        <div class="role-pill">{{ user?.role || 'COMMUNITY_MEMBER' }}</div>
        <strong>{{ user?.name || 'Demo user' }}</strong>
        <button @click="signOut">Sign out</button>
      </div>
    </aside>

    <main class="main-panel">
      <header>
        <div>
          <div class="eyebrow">CAPE TOWN · SYNTHETIC DEMO DATA</div>
          <h1>Dashboard</h1>
        </div>
      </header>

      <section class="metrics">
        <article class="metric-card"><span>Reports</span><strong>08</strong></article>
        <article class="metric-card"><span>Needs routed</span><strong>03</strong></article>
        <article class="metric-card"><span>Match review</span><strong>02</strong></article>
      </section>

      <section class="content-grid">
        <article class="panel">
          <h2>Recent activity</h2>
          <ul>
            <li>Streetlight need registered without project approval.</li>
            <li>Road observation surfaced in-flight project suggestion.</li>
            <li>Department response logged to the assigned need.</li>
          </ul>
        </article>
        <article class="panel">
          <h2>Current focus</h2>
          <p>A suggested match is never a confirmed relationship. Human review is required before any project accountability investigation begins.</p>
        </article>
      </section>
    </main>
  </div>
</template>

<style scoped>
.dashboard-shell { display: grid; grid-template-columns: 240px 1fr; min-height: 100vh; background: #f5f7f5; }
.sidebar { background: #0e2a25; color: #f3f8f5; padding: 24px 18px; }
.brand { display: flex; align-items: center; gap: 12px; margin-bottom: 28px; }
.brand-mark { width: 36px; height: 36px; border-radius: 12px; display: grid; place-items: center; background: #d9f36b; color: #102b24; font-weight: 800; }
.brand strong { display: block; font-size: 18px; }
.brand small { color: #b7cdbd; }
.nav-item { width: 100%; text-align: left; border: 0; background: transparent; color: #dfeae4; padding: 10px 12px; border-radius: 8px; margin-bottom: 6px; cursor: pointer; }
.nav-item:hover { background: rgba(255,255,255,0.04); }
.session-card { background: rgba(255,255,255,0.04); border-radius: 10px; padding: 14px; margin-top: 30px; }
.role-pill { display: inline-block; background: #d9f36b; color: #0f2a24; font-size: 9px; padding: 4px 8px; border-radius: 999px; font-weight: 700; }
.session-card strong { display: block; margin: 10px 0; }
.session-card button { width: 100%; padding: 9px 12px; border: 1px solid rgba(255,255,255,0.1); background: transparent; color: white; border-radius: 8px; }
.main-panel { padding: 28px; }
header { margin-bottom: 24px; }
.eyebrow { color: #6b7b72; font-size: 9px; letter-spacing: 1.5px; font-weight: 700; }
h1 { margin: 8px 0 0; font-size: 36px; line-height: 1.1; }
.metrics { display: grid; grid-template-columns: repeat(3, minmax(160px, 1fr)); gap: 16px; }
.metric-card, .panel { background: #fff; border: 1px solid #e5ece7; border-radius: 12px; padding: 18px; }
.metric-card span { display: block; color: #62756d; font-size: 10px; margin-bottom: 10px; }
.metric-card strong { font-size: 32px; }
.content-grid { margin-top: 16px; display: grid; grid-template-columns: 1.2fr 1fr; gap: 16px; }
.panel h2 { margin: 0 0 12px; font-size: 18px; }
.panel ul { margin: 0; padding-left: 18px; color: #465b53; line-height: 1.8; }
.panel p { color: #465b53; line-height: 1.7; margin: 0; }
</style>
