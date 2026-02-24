# Pipeline Maintenance Work Orders

Desktop application for managing pipeline maintenance work orders — built with Delphi (Object Pascal), VCL, and SQL Server via FireDAC.

Technicians and engineers use this to create, assign, and track maintenance jobs on oil/gas pipeline infrastructure. Each work order carries a title, description, location, priority, assigned technician, and follows a simple status workflow: **New → In Progress → Completed**.

## Architecture

The project follows a layered architecture to keep concerns separated:

```
src/
  domain/      Entities and enums (TWorkOrder, TTechnician)
  data/        FireDAC connection factory + repository classes
  services/    Business logic, validation, workflow rules
  ui/          VCL forms (main list + create/edit dialog)
sql/           DDL and seed scripts for SQL Server
config/        INI-based connection settings (not committed)
```

- **Domain** — plain data classes with no dependencies on the database or UI.
- **Repositories** — all SQL lives here; parameterised queries, enum ↔ string mapping.
- **Service** — validation (required fields, length limits) and status-advancement logic. Raises `EWorkOrderValidation` on bad input.
- **Forms** — thin UI layer; collects user input, calls the service, displays results.

## Prerequisites

| Tool | Version |
|------|---------|
| Delphi (Community or higher) | 11+ recommended |
| SQL Server | 2019+ / LocalDB / Express |
| SSMS or Azure Data Studio | any recent version |

## Getting Started

### 1. Database

```sql
-- connect to your SQL Server instance, then:
CREATE DATABASE PipelineMaintenance;
```

Switch to the new database and run the two scripts in order:

- `sql/create_tables.sql` — creates `Technicians` and `WorkOrders` with constraints and indexes.
- `sql/seed_data.sql` — inserts a handful of sample technicians and work orders for testing.

### 2. Configuration

Copy the template and fill in your connection details:

```
copy config\app.ini.example config\app.ini
```

For a typical LocalDB setup the defaults in the template already work — just leave `user` and `password` blank (the app falls back to Windows authentication automatically).

### 3. Build & Run

Open `PipelineMaintenanceWorkOrders.dpr` in Delphi, target **Win32**, and hit **F9**.

The main form shows a filterable grid of work orders. From there you can:

- **New Work Order** — opens a dialog to fill in title, location, description, and priority.
- **Edit** (or double-click a row) — modify an existing work order.
- **Advance** — moves the selected order to the next status step.

## Project Files

| File | Purpose |
|------|---------|
| `PipelineMaintenanceWorkOrders.dpr` | Project entry point |
| `src/domain/uWorkOrder.pas` | `TWorkOrder` entity, status/priority enums and display labels |
| `src/domain/uTechnician.pas` | `TTechnician` entity |
| `src/data/uDBConnection.pas` | Reads `config/app.ini`, creates a `TFDConnection` |
| `src/data/uWorkOrderRepository.pas` | `IWorkOrderRepository` + SQL implementation |
| `src/data/uTechnicianRepository.pas` | `ITechnicianRepository` + SQL implementation |
| `src/services/uWorkOrderService.pas` | Validation, create/update/advance-status logic |
| `src/ui/fMain.pas` | Main form — grid, filters, action buttons |
| `src/ui/fWorkOrderForm.pas` | Modal dialog for creating / editing a work order |

## License

Internal / private use.
