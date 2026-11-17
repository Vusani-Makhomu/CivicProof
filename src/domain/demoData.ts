export type ProjectStatus = 'PLANNED' | 'IN_PROGRESS' | 'COMPLETED'
export type SubmissionType = 'COMMUNITY_NEED' | 'SERVICE_OBSERVATION'
export type Category = 'PUBLIC_LIGHTING' | 'ROADS_TRANSPORT' | 'WATER' | 'SANITATION' | 'STORMWATER' | 'WASTE_MANAGEMENT' | 'PUBLIC_FACILITIES'
export type CivicSubmission = { id: string; type: SubmissionType; title: string; description: string; category: Category; area: string; latitude: number; longitude: number; createdAt: string; status: string; matches: string[]; synthetic: boolean }
export type CivicProject = { id: string; name: string; description: string; category: Category; status: ProjectStatus; area: string; latitude: number; longitude: number; scope: string; progress: number; budget: number | null; synthetic: true; start: string; end: string }

const areas = [
  ['Khayelitsha', -34.039, 18.677], ['Mitchells Plain', -34.050, 18.618], ['Gugulethu', -33.981, 18.573], ['Langa', -33.945, 18.529], ['Nyanga', -34.005, 18.581], ['Philippi', -34.015, 18.596], ['Delft', -33.974, 18.641], ['Athlone', -33.966, 18.503], ['Bonteheuwel', -33.929, 18.549], ['Manenberg', -33.990, 18.545], ['Woodstock', -33.927, 18.447], ['Bellville', -33.900, 18.630], ['Dunoon', -33.804, 18.523], ['Masiphumelele', -34.128, 18.375], ['Hout Bay', -34.047, 18.354], ['Khayelitsha', -34.050, 18.690], ['Philippi', -34.027, 18.611], ['Delft', -33.986, 18.655]
] as const
const categories: Category[] = ['ROADS_TRANSPORT', 'PUBLIC_LIGHTING', 'WATER', 'SANITATION', 'STORMWATER', 'WASTE_MANAGEMENT', 'PUBLIC_FACILITIES']
const statuses: ProjectStatus[] = ['COMPLETED', 'IN_PROGRESS', 'PLANNED']
const labels: Record<Category, string> = { PUBLIC_LIGHTING: 'Public lighting', ROADS_TRANSPORT: 'Roads & transport', WATER: 'Water', SANITATION: 'Sanitation', STORMWATER: 'Stormwater', WASTE_MANAGEMENT: 'Waste management', PUBLIC_FACILITIES: 'Public facilities' }
export const categoryLabel = (category: Category) => labels[category]
export const projects: CivicProject[] = areas.map(([area, latitude, longitude], index) => {
  const category = categories[index % categories.length]!
  const status = statuses[Math.floor(index / 6)]!
  const progress = status === 'COMPLETED' ? 100 : status === 'PLANNED' ? 0 : [28, 54, 72, 35, 81, 46][index % 6]!
  return { id: `demo-project-${String(index + 1).padStart(3, '0')}`, name: `${area} ${labels[category]} ${['renewal', 'upgrade', 'improvements'][index % 3]}`, description: `Fictional ${labels[category].toLowerCase()} works for demonstration only.`, category, status, area, latitude, longitude, scope: `${[450, 800, 1200, 650, 950, 500][index % 6]} metres of planned works`, progress, budget: [12000000, 3800000, 6700000][index % 3]!, synthetic: true, start: status === 'PLANNED' ? '2026-10-01' : '2025-03-01', end: status === 'COMPLETED' ? '2025-11-30' : '2027-03-31' }
})
export const demoSubmissions: CivicSubmission[] = [
  { id: 'demo-report-001', type: 'COMMUNITY_NEED', title: 'Streetlights needed near the community hall', description: 'Residents report several dark blocks and request a lighting assessment.', category: 'PUBLIC_LIGHTING', area: 'Manenberg', latitude: -33.990, longitude: 18.545, createdAt: '2026-11-13', status: 'Under investigation', matches: [], synthetic: true },
  { id: 'demo-report-002', type: 'SERVICE_OBSERVATION', title: 'Road works appear incomplete', description: 'Reported construction may have stopped before the full road scope was delivered.', category: 'ROADS_TRANSPORT', area: 'Philippi', latitude: -34.015, longitude: 18.596, createdAt: '2026-11-15', status: 'Match review', matches: ['demo-project-017'], synthetic: true },
  { id: 'demo-report-003', type: 'SERVICE_OBSERVATION', title: 'Water service interruption continues', description: 'Community reports unreliable water service after recently completed works.', category: 'WATER', area: 'Khayelitsha', latitude: -34.039, longitude: 18.677, createdAt: '2026-11-16', status: 'Match review', matches: ['demo-project-001'], synthetic: true },
  { id: 'demo-report-004', type: 'COMMUNITY_NEED', title: 'Drainage improvements requested', description: 'Residents request assessment of recurring stormwater pooling.', category: 'STORMWATER', area: 'Delft', latitude: -33.974, longitude: 18.641, createdAt: '2026-11-16', status: 'Awaiting response', matches: ['demo-project-007', 'demo-project-018'], synthetic: true },
  { id: 'demo-report-005', type: 'COMMUNITY_NEED', title: 'Safer pedestrian crossing', description: 'Request for a safe crossing near a busy local road.', category: 'ROADS_TRANSPORT', area: 'Dunoon', latitude: -33.804, longitude: 18.523, createdAt: '2026-11-17', status: 'Registered', matches: [], synthetic: true },
  { id: 'demo-report-006', type: 'SERVICE_OBSERVATION', title: 'Public facility maintenance concern', description: 'A reported maintenance concern at a local public facility.', category: 'PUBLIC_FACILITIES', area: 'Langa', latitude: -33.945, longitude: 18.529, createdAt: '2026-11-11', status: 'In progress', matches: ['demo-project-004'], synthetic: true },
  { id: 'demo-report-007', type: 'COMMUNITY_NEED', title: 'Waste collection point requested', description: 'Community asks for an assessment of waste collection access.', category: 'WASTE_MANAGEMENT', area: 'Hout Bay', latitude: -34.047, longitude: 18.354, createdAt: '2026-11-10', status: 'Registered', matches: [], synthetic: true },
  { id: 'demo-report-008', type: 'SERVICE_OBSERVATION', title: 'Sanitation service follow-up', description: 'Residents report a continuing sanitation issue for follow-up.', category: 'SANITATION', area: 'Gugulethu', latitude: -33.981, longitude: 18.573, createdAt: '2026-11-09', status: 'Under investigation', matches: ['demo-project-003'], synthetic: true }
]
