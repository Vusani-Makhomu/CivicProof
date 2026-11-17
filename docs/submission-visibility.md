# Submission visibility troubleshooting

The community-member demo view lists reports owned by the current local demo profile. Reports created by older versions of the browser demo used `report-` IDs before ownership was recorded; the app now backfills the current demo owner for those locally saved records on load. Seeded examples use `demo-report-` IDs and remain hidden from the community member's “My needs” panel. This migration affects only localStorage in the current browser and does not provide real authentication or server-side access control.
