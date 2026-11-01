# Chapter process (v0, draft before the Chapter 1 retro)

How one chapter of Kingdom of Numbers goes from idea to a playable, tested build.
This version is the plan used for Chapter 1. The retro after each chapter updates it;
see the changelog at the end.

## Roles

| Role | Owns | Signs off on |
|---|---|---|
| Product manager (PM) | Chapter brief, scope, acceptance criteria | Story problem = math problem; scope delivered; ACs met |
| Child learning expert | Skills, CPA ladder, hint and praise scripts, home tips | Pedagogy in the built app matches the brief |
| UX and graphic designer | Mocks per screen, art list, placeholder art | Screens match the mocks |
| Developers | Content data, new activity kinds, engine changes, unit tests | Unit tests green; content validation green |
| QA | Play-through in the iPad simulator, screenshot review, QA report | Every scene playable end to end; every AC checked |

## Stages

1. **Brief (PM).** Story problem, math goal, skills (3 to 5), scenes (4 to 6), new ACs.
2. **Pedagogy (learning expert).** For each skill: what concrete, pictorial and abstract look like; the three hint steps; praise that names what she did; one off-screen home tip.
3. **Design (UX and graphic).** One mock per scene plus any new shared screens, at 1180 x 820 landscape, with spoken lines in notes.
4. **Build (developers).** Add skills, scenes, items and lines to `content.json`. Add any new activity kind (core answer rule plus one SwiftUI view). Write unit tests for every new rule.
5. **QA play-through.** Extend the QA tests to play every new scene, with one wrong-answer path per activity kind, and save a screenshot of each step. Review screenshots against the mocks and ACs. File findings.
6. **Fix.** Developers fix findings; QA re-runs.
7. **Retro.** PM, learning expert and QA each sign off or raise gaps. Gaps become learnings, and learnings update this document before the next chapter starts.

## Changelog

- v0 (2026-11-01): first draft, used for Chapter 1.
