import type { CivicSubmission } from './demoData'

/** Optional owner identifier for locally-created demo reports. Seeded reports have no owner. */
export type OwnedReport = CivicSubmission & { ownerId?: string | null }

/** Return only records explicitly owned by the active user. Missing owners are never treated as public. */
export function filterReportsForOwner<T extends { ownerId?: string | null }>(reports: T[], ownerId: string): T[] {
  return reports.filter(report => report.ownerId === ownerId)
}

/**
 * Backfill reports created by earlier browser-demo versions, which used `report-`
 * IDs before ownerId was stored. Seeded records use `demo-report-` IDs and stay
 * unowned, so they remain hidden from the community-member list.
 */
export function migrateLegacyReportOwners<T extends { id: string; ownerId?: string | null }>(reports: T[], ownerId: string): T[] {
  return reports.map(report => report.ownerId == null && report.id.startsWith('report-')
    ? { ...report, ownerId }
    : report)
}
