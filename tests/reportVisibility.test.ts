import { describe, expect, it } from 'vitest'
import { filterReportsForOwner, migrateLegacyReportOwners } from '../src/domain/reportVisibility'

describe('community report visibility', () => {
  const reports = [
    { id: 'mine', ownerId: 'member-a' },
    { id: 'theirs', ownerId: 'member-b' },
    { id: 'legacy-seed' }
  ]

  it('only returns reports explicitly owned by the current member', () => {
    expect(filterReportsForOwner(reports, 'member-a').map(report => report.id)).toEqual(['mine'])
  })

  it('does not expose seeded or unowned reports as a member’s own', () => {
    expect(filterReportsForOwner(reports, 'member-c')).toEqual([])
  })

  it('restores visibility of locally-created reports saved before owner IDs existed', () => {
    const stored = [
      { id: 'report-1700000000000', ownerId: null },
      { id: 'report-f7cae8', ownerId: undefined },
      { id: 'demo-report-001', ownerId: null },
      { id: 'report-other-member', ownerId: 'member-b' }
    ]
    const migrated = migrateLegacyReportOwners(stored, 'member-a')
    expect(filterReportsForOwner(migrated, 'member-a').map(report => report.id)).toEqual([
      'report-1700000000000', 'report-f7cae8'
    ])
    expect(migrated.find(report => report.id === 'demo-report-001')?.ownerId).toBeNull()
    expect(migrated.find(report => report.id === 'report-other-member')?.ownerId).toBe('member-b')
  })
})
