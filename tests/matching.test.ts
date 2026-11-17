import { describe, expect, it } from 'vitest'
import { findMatches, distanceKm } from '../src/domain/matching'
import { projects } from '../src/domain/demoData'

describe('matching suggestions', () => {
  it('returns explainable nearby candidates for road observations', () => {
    const result = findMatches({ type: 'SERVICE_OBSERVATION', category: 'ROADS_TRANSPORT', area: 'Philippi', latitude: -34.015, longitude: 18.596, description: 'road construction incomplete' }, projects)
    expect(result.status).toBe('SUGGESTED')
    expect(result.candidates[0]?.reasons.length).toBeGreaterThan(0)
  })
  it('returns NO_MATCH when available project data has no relevant records', () => {
    const result = findMatches({ type: 'COMMUNITY_NEED', category: 'PUBLIC_LIGHTING', area: 'Woodstock', description: 'streetlights needed' }, projects.filter(project => project.category === 'WATER'))
    expect(result).toEqual({ status: 'NO_MATCH', candidates: [] })
  })
  it('uses area/text fallback when coordinates are missing', () => {
    const result = findMatches({ type: 'COMMUNITY_NEED', category: 'WATER', area: 'Khayelitsha', description: 'water service interruption' }, projects)
    expect(result.status).toBe('SUGGESTED')
  })
  it('calculates zero distance for identical coordinates', () => {
    expect(distanceKm(-34, 18, -34, 18)).toBe(0)
  })
  it('includes all three required synthetic project statuses', () => {
    expect(projects.filter(item => item.status === 'COMPLETED')).toHaveLength(6)
    expect(projects.filter(item => item.status === 'IN_PROGRESS')).toHaveLength(6)
    expect(projects.filter(item => item.status === 'PLANNED')).toHaveLength(6)
    expect(projects.every(item => item.synthetic)).toBe(true)
  })
})
