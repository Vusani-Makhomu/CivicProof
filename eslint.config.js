import { defineConfig } from 'eslint/config'
import vue from 'eslint-plugin-vue'

export default defineConfig([...vue.configs['flat/recommended'], { ignores: ['dist/**', 'node_modules/**', 'coverage/**'] }])
