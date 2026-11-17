import { createRouter, createWebHistory } from 'vue-router'
import LoginView from './views/LoginView.vue'
import DashboardView from './views/DashboardView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/login' },
    { path: '/login', component: LoginView },
    { path: '/dashboard', component: DashboardView, meta: { requiresAuth: true } }
  ]
})

router.beforeEach((to, from, next) => {
  const stored = localStorage.getItem('civicproof-demo-user')
  const authed = Boolean(stored)
  if (to.meta.requiresAuth && !authed) {
    next('/login')
    return
  }
  next()
})

export default router
