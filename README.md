# Pipeline Maintenance Work Orders

A production-style Delphi VCL desktop app for technicians/engineers to create, assign, and track pipeline maintenance work orders. Uses SQL Server and FireDAC with a clean, layered architecture (domain, data, services, UI).

## Project Structure
- `src/domain`: Domain entities (`uWorkOrder`, `uTechnician`).
- `src/data`: FireDAC connection factory and repositories.
- `src/services`: Business logic service (`uWorkOrderService`).
- `src/ui`: VCL forms (`fMain`, `fWorkOrderForm`).
- `sql/create_tables.sql`: DDL for SQL Server.
- `config/app.ini.example`: Connection settings template.

## Database Setup
1. Run `sql/create_tables.sql` on your SQL Server.
2. Copy `config/app.ini.example` to `config/app.ini` and set `server`, `database`, `user`, `password`.

## Build/Run (Delphi)
1. Open `PipelineMaintenanceWorkOrders.dpr` in Delphi (VCL, Windows).
2. Ensure FireDAC MSSQL driver is available.
3. Build and run. The main form lists work orders with filters and actions (create, edit, advance status).

## Notes
- SQL lives only in repositories; forms call services.
- Workflow: status advances `New -> InProgress -> Completed`.
- Forms use simple string grid population; swap to data-aware controls if desired.
