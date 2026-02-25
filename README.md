# Pipeline Maintenance Work Orders

A Delphi VCL desktop app I built for managing pipeline maintenance work orders. Technicians use it to log jobs, track status, and keep tabs on what's assigned where across a pipeline network.

Each work order has a title, description, physical location along the pipeline, a priority level, and an assigned technician. Status follows a strict forward-only workflow: **New → In Progress → Completed**. You can't skip steps or go backwards, which keeps the audit trail honest.

## Why this structure

I wanted the code to be easy to reason about and extend, so I split it into four layers with a strict dependency direction:

```
  UI  →  Service  →  Repository  →  Domain
```

The **domain** layer (`uWorkOrder`, `uTechnician`) has zero dependencies: just plain classes, enums, and constants. Everything else points inward toward it.

**Repositories** own all the SQL. Parameterised queries, enum-to-string mapping, row-to-object hydration, it all lives here. The rest of the app never sees a `TFDQuery`.

**The service** (`TWorkOrderService`) handles validation and workflow rules. It checks required fields, enforces length limits that match the DB schema, and guards status transitions so you can't, say, edit a completed order or jump from New straight to Completed.

**Forms** are deliberately thin. They collect input from the user, hand it to the service, and display results. No business logic, no SQL.

A **composition root** (`TAppContext`) wires everything together: connection, repositories, services. The UI only ever talks to the service through that single entry point. The main form doesn't know or care how the database connection is created.

## Design decisions worth mentioning

- **`TWorkOrderFilter` record** instead of passing four loose parameters (`AStatus`, `APriority`, `AFilterStatus`, `AFilterPriority`) around. Cleaner signatures, and the record has factory methods like `ByStatus(...)`, `ByPriority(...)`, `ByStatusAndPriority(...)` and `None`.

- **`UtcNow` helper**: the DB defaults use `SYSUTCDATETIME()`, so the Delphi side also stamps UTC via `TTimeZone.Local.ToUniversalTime(Now)`. Mixing local and UTC timestamps is a subtle bug I've seen in production before.

- **`TWorkOrder.IsValidTransition` class method**: status workflow rules live on the entity itself, not buried in the service. The service calls it, the form could call it too for UI hints. Single source of truth.

- **`EWorkOrderValidation` custom exception**: the service raises these; the UI catches them specifically and shows a dialog. Generic exceptions bubble up normally. This keeps the error handling intentional rather than catch-all.

- **Connection factory with proper cleanup**: if `Connected := True` fails, the `TFDConnection` is freed before the exception propagates. Sounds obvious, but it's an easy resource leak to miss.

- **Interface-based repositories** (`IWorkOrderRepository`, `ITechnicianRepository`): makes it straightforward to swap in a mock or a different storage backend without touching the service or UI.

- **`TStringGrid` over `TDBGrid`**: I deliberately avoided data-aware controls. `TDBGrid` ties the form to a dataset, which means the UI layer ends up knowing about the data layer. With a plain `TStringGrid`, the form just receives a list of objects from the service and populates cells. No `TDataSource`, no `TDataSet` on the form, no implicit coupling. The forms stay thin and testable.

- **Raw SQL over an ORM**: I went with hand-written FireDAC queries instead of Aurelius. No commercial dependency, full visibility into every query, and the repository interfaces still give me the same decoupling an ORM would if I ever need to swap the storage backend.

- **Minimal DFMs**: I stripped out the IDE-generated noise (`PixelsPerInch`, `TextHeight`, default property values) so the committed DFM files only contain what actually matters for the layout. Easier to diff, easier to review.

## Project layout

```
PipelineMaintenanceWorkOrders.dpr     Entry point
src/
  domain/
    uWorkOrder.pas          Entity, enums, filter record, validation exception
    uTechnician.pas         Technician entity
  data/
    uDBConnection.pas       Reads config/app.ini, builds TFDConnection
    uWorkOrderRepository.pas    IWorkOrderRepository + FireDAC implementation
    uTechnicianRepository.pas   ITechnicianRepository + FireDAC implementation
  services/
    uWorkOrderService.pas   Validation, timestamps, status workflow
  ui/
    fMain.pas / .dfm        Main grid, filters, action buttons
    fWorkOrderForm.pas / .dfm   Modal create/edit dialog
  uAppContext.pas           Composition root, owns connection + services
sql/
  create_tables.sql         DDL (idempotent, uses IF NOT EXISTS)
  seed_data.sql             Sample technicians and work orders
config/
  app.ini.example           Connection template (copy to app.ini)
```

## Getting started

**Database**: spin up LocalDB or any SQL Server instance, create a database called `PipelineMaintenance`, then run `sql/create_tables.sql` followed by `sql/seed_data.sql`.

**Config**: copy `config/app.ini.example` to `config/app.ini`. For LocalDB with Windows auth, the defaults work as-is (leave user/password blank; the factory detects this and uses OS authentication).

**Build**: open `PipelineMaintenanceWorkOrders.dpr` in Delphi (Community Edition works fine), target Win32, hit F9.

## What you can do in the app

- Filter the work order list by status, priority, or both
- Create a new work order (status is locked to New)
- Edit an existing order (status can only move forward)
- Advance status with one click (New → In Progress → Completed)
- Double-click any row to open the edit dialog
