# Community data visibility change

The community-member screen is intentionally limited to the **Report a need** action and a **Your existing needs** panel containing only submissions explicitly owned by the active demo member. Seeded records and reports with a missing owner are not shown in that panel. Selecting one of your reports reveals only the submitted title, category, area, date, description and status—not candidate project matches, staff responses, investigation records, findings or internal notes.

This is presentation-level filtering for the browser demo, not a security boundary: demo reports are stored in localStorage, the role picker is not authentication, and a user can inspect or alter browser data. For real deployments, enforce per-user access with Supabase Row Level Security and authenticated identity; never rely on frontend filtering to protect sensitive information.
