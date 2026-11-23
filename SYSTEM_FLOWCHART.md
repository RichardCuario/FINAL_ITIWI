# iTIWI Complete System Flowchart

The editable, single-page diagrams.net / draw.io source is [iTIWI_SYSTEM_FLOWCHART.drawio](docs/ITIWI_SYSTEM_FLOWCHART.drawio). Open it in draw.io / diagrams.net with **File > Open from > Device**. The matching monochrome [SVG preview](docs/ITIWI_SYSTEM_FLOWCHART.svg) uses standard flowchart shapes and connectors.

This is an execution-flow diagram, separate from the UML use-case model in [ITIWI_USE_CASE.drawio](docs/ITIWI_USE_CASE.drawio). The flow follows current app behavior: mobile sign-in uses Firebase; admin sign-in uses Supabase Auth; Didit decisions arrive through its signed webhook; and manual admin verification decisions are disabled. Dashboard feature visibility is role/permission based, while report visibility also checks category or assignment. Browser-side role checks do not replace Supabase row-level security.

For end-to-end interactions between the mobile app, admin dashboard, Firebase, Supabase, Didit, notifications and Android updates, see [ITIWI_SYSTEM_SEQUENCE.md](docs/ITIWI_SYSTEM_SEQUENCE.md).

The mobile service catalog currently exposes Birth Certificate, Marriage Certificate, Death Certificate, and CENODEATH appointments. CENOMAR and facility requests remain in legacy/admin code and are not represented as selectable current mobile services.

For the implementation scope and source references, see [USE_CASE_DIAGRAM.md](docs/USE_CASE_DIAGRAM.md), [USER_MANUAL.md](docs/USER_MANUAL.md), and [ADMIN_MANUAL.md](docs/ADMIN_MANUAL.md).