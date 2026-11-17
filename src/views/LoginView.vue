<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

type DemoRole = 'COMMUNITY_MEMBER' | 'GOVERNMENT_REVIEWER' | 'DEPARTMENT_OFFICIAL' | 'INVESTIGATOR' | 'ADMIN'

const router = useRouter()
const demoUsers: Array<{ id: string; name: string; role: DemoRole }> = [
  { id: 'community', name: 'Community member', role: 'COMMUNITY_MEMBER' },
  { id: 'reviewer', name: 'Government reviewer', role: 'GOVERNMENT_REVIEWER' },
  { id: 'official', name: 'Department official', role: 'DEPARTMENT_OFFICIAL' },
  { id: 'investigator', name: 'Investigator', role: 'INVESTIGATOR' },
  { id: 'admin', name: 'Admin', role: 'ADMIN' }
]

const selected = ref(demoUsers[0])
const roleSummary = computed(() => ({
  COMMUNITY_MEMBER: 'Create reports, upload evidence, and view your own submissions.',
  GOVERNMENT_REVIEWER: 'Review project matches and confirm or reject them with reasons.',
  DEPARTMENT_OFFICIAL: 'Respond to routed community needs and assigned investigations.',
  INVESTIGATOR: 'Track accountability investigations and document findings.',
  ADMIN: 'Manage admin-only demo actions and synthetic reset operations.'
}[selected.value.role]))

function signIn() {
  localStorage.setItem('civicproof-demo-user', JSON.stringify(selected.value))
  router.push('/dashboard')
}
</script>

<template>
  <div class="auth-shell">
    <div class="auth-card">
      <div class="brand-row">
        <div class="brand-mark">C</div>
        <div>
          <div class="eyebrow">CIVICPROOF</div>
          <h1>Public money. Public evidence.</h1>
        </div>
      </div>

      <p class="intro">
        Demo-only sign-in. This app is synthetic and should never be mistaken for official municipal data.
      </p>

      <label class="field-label">Choose a role</label>
      <select v-model="selected" class="field input">
        <option v-for="user in demoUsers" :key="user.id" :value="user">{{ user.name }}</option>
      </select>

      <div class="role-panel">
        <div class="role-tag">{{ selected.role }}</div>
        <p>{{ roleSummary }}</p>
      </div>

      <button class="primary-btn" @click="signIn">Continue as {{ selected.name }}</button>
    </div>
  </div>
</template>

<style scoped>
.auth-shell {
  min-height: 100vh; display: grid; place-items: center; background: linear-gradient(140deg, #0e2a25 0%, #1d3b33 42%, #f4f7f3 42%, #f4f7f3 100%);
  padding: 24px;
}
.auth-card {
  width: min(520px, 100%); background: #ffffff; border: 1px solid #dfe7e0; border-radius: 18px; padding: 28px; box-shadow: 0 20px 60px rgba(13, 28, 24, 0.14);
}
.brand-row { display: flex; align-items: center; gap: 14px; margin-bottom: 12px; }
.brand-mark { width: 42px; height: 42px; border-radius: 12px; display: grid; place-items: center; background: #d9f36b; color: #0d2d24; font-weight: 800; }
.eyebrow { color: #6d8177; font-size: 10px; letter-spacing: 1.8px; font-weight: 700; }
h1 { margin: 6px 0 0; font-size: 26px; line-height: 1.1; }
.intro { color: #5d6c65; font-size: 12px; line-height: 1.5; margin: 14px 0 18px; }
.field-label { display: block; font-size: 10px; font-weight: 700; color: #64766c; letter-spacing: 0.7px; margin-bottom: 7px; }
.input { width: 100%; border: 1px solid #e0e8e0; border-radius: 8px; padding: 12px 14px; font-size: 13px; margin-bottom: 16px; }
.role-panel { background: #f4f8ef; border: 1px solid #e3ebd8; border-radius: 10px; padding: 12px 14px; margin-bottom: 18px; }
.role-tag { display: inline-block; color: #244f39; background: #d9f36b; border-radius: 999px; padding: 5px 9px; font-size: 10px; font-weight: 700; text-transform: uppercase; }
.role-panel p { margin: 10px 0 0; color: #495d54; line-height: 1.5; font-size: 12px; }
.primary-btn { width: 100%; border: 0; border-radius: 9px; padding: 13px 16px; background: #1c4133; color: #fff; font-weight: 600; cursor: pointer; }
</style>
