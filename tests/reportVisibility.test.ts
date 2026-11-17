import { describe, expect, it } from 'vitest'
import { filterReportsForOwner } from '../src/domain/reportVisibility'

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
})
