import type { Category, CivicProject } from './demoData'

export type MatchCandidate = { project: CivicProject; score: number; reasons: string[] }
export type MatchResult = { status: 'SUGGESTED' | 'NO_MATCH'; candidates: MatchCandidate[] }
export type MatchInput = { category: Category; description: string; area?: string; latitude?: number | null; longitude?: number | null; type: 'COMMUNITY_NEED' | 'SERVICE_OBSERVATION' }

export function distanceKm(aLat: number, aLon: number, bLat: number, bLon: number): number {
  const rad = (value: number) => value * Math.PI / 180
  const dLat = rad(bLat - aLat), dLon = rad(bLon - aLon)
  const value = Math.sin(dLat / 2) ** 2 + Math.cos(rad(aLat)) * Math.cos(rad(bLat)) * Math.sin(dLon / 2) ** 2
  return 6371 * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value))
}

export function findMatches(input: MatchInput, records: CivicProject[], radiusKm = 12): MatchResult {
  const words = new Set(input.description.toLowerCase().split(/[^a-z0-9]+/).filter(word => word.length > 3))
  const candidates = records.map(project => {
    const reasons: string[] = []
    let score = 0
    if (project.category === input.category) { score += 0.48; reasons.push('Category matches the report') }
    const sameArea = input.area?.toLowerCase() === project.area.toLowerCase()
    const distance = input.latitude != null && input.longitude != null ? distanceKm(input.latitude, input.longitude, project.latitude, project.longitude) : null
    if (sameArea) { score += 0.24; reasons.push(`Same area: ${project.area}`) }
    if (distance != null && distance <= radiusKm) { score += Math.max(0, 0.24 * (1 - distance / radiusKm)); reasons.push(`Approx. ${distance.toFixed(1)} km away`) }
    const haystack = `${project.name} ${project.description} ${project.scope} ${project.area}`.toLowerCase()
    const overlap = [...words].filter(word => haystack.includes(word)).length
    if (overlap) { score += Math.min(0.18, overlap * 0.06); reasons.push('Some report terms overlap project details') }
    if (project.status === 'IN_PROGRESS') { score += 0.04; reasons.push('Project is in progress') }
    else if (project.status === 'COMPLETED' && input.type === 'SERVICE_OBSERVATION') { score += 0.02; reasons.push('Completed project may be relevant to a continuing service issue') }
    return { project, score: Math.min(score, 0.99), reasons }
  }).filter(item => item.score >= 0.38).sort((a, b) => b.score - a.score).slice(0, 5)
  return candidates.length ? { status: 'SUGGESTED', candidates } : { status: 'NO_MATCH', candidates: [] }
}
