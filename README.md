# CivicProof

**Public money. Public evidence. Public accountability.**

CivicProof connects community needs and service observations with potentially relevant public projects, then makes human review and follow-up visible. Residents report what they experience; they do not need to know a government project ID.

> **Hackathon MVP / browser demo.** This is not an official City of Cape Town or government service. All included projects and seeded responses are synthetic. Reports created in the demo are stored in the browser's local storage and are not sent to a government institution.

## What the MVP demonstrates

- Register a community need or service observation without a project ID, proof of residence, or prior government approval.
- Deterministically suggest zero or more project matches using category, approximate distance, area and text overlap. Explanations are heuristic, not calibrated probabilities.
- Keep unmatched community needs registered and open a community-need follow-up automatically.
- Require a human reviewer to confirm a suggested project relationship before opening a project accountability investigation.
- Record department responses, evidence-classified findings and corrective actions in a local demo session.
- Browse 18 synthetic Cape Town-area project records, reports and approximate map markers.
- Switch demo roles to walk through community-member, reviewer, official, investigator, auditor and admin screens. This switch is for demonstrations only and is **not authentication or access control**.
- Reset local synthetic demo state from Demo data & setup (Admin demo role).

A confirmed match does not verify a resident's allegation. A discrepancy is a reason for investigation, not proof of fraud, theft or corruption. “No matching record found” means no relevant project was identified in the records available to the demo.

## Run locally

Requirements: Node.js LTS and npm.

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open the Vite URL (usually `http://localhost:5173`). The app works as a browser-only demo without Supabase credentials. Browser data is local to that browser/profile.

## Checks

```bash
npm run lint
npm run typecheck
npm run test
npm run build
```

Playwright configuration is included; run `npm run test:e2e` after browser dependencies and end-to-end specs are set up.

## Supabase groundwork

The repository includes an initial schema/RLS migration under `supabase/migrations`. It is groundwork only: the current browser demo does not use Supabase for its reports, roles, uploads, responses, review decisions or findings. Do not treat the role selector as a security boundary. Do not expose a Supabase service-role key in the browser or a `VITE_` variable. Configure a real project, apply and review migrations, and implement/test trusted RPCs and RLS before using real accounts or data.

`.env.example` contains placeholders for the Supabase project URL and public anon key. These are not required for the localStorage demo.

## Synthetic data and limitations

- Every seeded project is fictional and carries a synthetic marker in the source model.
- Coordinates are approximate demonstration locations, not surveyed positions or project boundaries.
- The current map is a stylized schematic, not an interactive geographic GIS map.
- Photo/video upload, identity checks, official municipal data feeds, real authentication, cross-device persistence, and real public-sector workflow integration are not implemented.
- Do not use this MVP for urgent service requests, emergency reporting, allegations about identifiable people, financial decisions, or official complaints.

## Source context

The product brief cites Auditor-General South Africa's 2024–25 local government reporting: [Consolidated Report](https://mfma-2025.agsa.co.za/), [Compliance and consequences](https://mfma-2025.agsa.co.za/pages/compliance-consequences), and [Financial performance and reporting](https://mfma-2025.agsa.co.za/pages/financial-performance-reporting). These are national figures, not a measure of CivicProof's impact or Cape Town-specific rates. Irregular expenditure is not automatically fraud, corruption or financial loss.

See [`IMPLEMENTATION_SPEC.txt`](IMPLEMENTATION_SPEC.txt) for the full execution brief and future requirements.
