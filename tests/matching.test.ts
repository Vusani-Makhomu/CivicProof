import { describe, expect, it } from 'vitest'
import { findMatches } from '../src/domain/matching'
import { projects } from '../src/domain/demoData'

describe('deterministic project matching', () => {
  it('suggests a nearby project with an explanation', () => {
    const result = findMatches({ type: 'SERVICE_OBSERVATION', category: 'ROADS_TRANSPORT', area: 'Philippi', latitude: -34.015, longitude: 18.596, description: 'road construction appears incomplete' }, projects)
    expect(result.status).toBe('SUGGESTED')
    expect(result.candidates[0]?.reasons.length).toBeGreaterThan(0)
  })
  it('returns NO_MATCH without claiming that no project exists', () => {
    const result = findMatches({ type: 'COMMUNITY_NEED', category: 'PUBLIC_LIGHTING', area: 'Woodstock', description: 'streetlights needed' }, projects.filter(project => project.category === 'WATER'))
    expect(result).toEqual({ status: 'NO_MATCH', candidates: [] })
  })
  it('supports missing coordinates using area and text signals', () => {
    const result = findMatches({ type: 'COMMUNITY_NEED', category: 'WATER', area: 'Khayelitsha', description: 'water service' }, projects)
    expect(result.status).toBe('SUGGESTED')
  })
  it('has six synthetic projects in each lifecycle status', () => {
    expect(projects.filter(project => project.status === 'COMPLETED')).toHaveLength(6)
    expect(projects.filter(project => project.status === 'IN_PROGRESS')).toHaveLength(6)
    expect(projects.filter(project => project.status === 'PLANNED')).toHaveLength(6)
    expect(projects.every(project => project.synthetic)).toBe(true)
  })
})
