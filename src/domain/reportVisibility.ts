import type { CivicSubmission } from './demoData'

/** Optional owner identifier for locally-created demo reports. Seeded reports have no owner. */
export type OwnedReport = CivicSubmission & { ownerId?: string | null }

/** Return only records explicitly owned by the active user. Missing owners are never treated as public. */
export function filterReportsForOwner<T extends { ownerId?: string | null }>(reports: T[], ownerId: string): T[] {
  return reports.filter(report => report.ownerId === ownerId)
}
