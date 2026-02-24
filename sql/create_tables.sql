-- ============================================================
-- Pipeline Maintenance Work Orders  -  Database Schema
-- Target: SQL Server 2019+ / LocalDB
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Technicians')
BEGIN
  CREATE TABLE Technicians (
      TechnicianId  INT           IDENTITY(1,1) PRIMARY KEY,
      FullName      NVARCHAR(100) NOT NULL,
      Email         NVARCHAR(255) NULL,
      Phone         NVARCHAR(50)  NULL,
      IsActive      BIT           NOT NULL DEFAULT 1
  );

  CREATE UNIQUE INDEX UX_Technicians_Email
      ON Technicians (Email)
      WHERE Email IS NOT NULL;
END;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WorkOrders')
BEGIN
  CREATE TABLE WorkOrders (
      WorkOrderId         INT            IDENTITY(1,1) PRIMARY KEY,
      Title               NVARCHAR(200)  NOT NULL,
      [Description]       NVARCHAR(MAX)  NULL,
      [Location]          NVARCHAR(200)  NOT NULL,
      Priority            NVARCHAR(10)   NOT NULL
                          CONSTRAINT CK_WorkOrders_Priority
                          CHECK (Priority IN ('Low', 'Medium', 'High')),
      [Status]            NVARCHAR(15)   NOT NULL
                          CONSTRAINT CK_WorkOrders_Status
                          CHECK ([Status] IN ('New', 'InProgress', 'Completed')),
      AssignedTechnicianId INT           NULL,
      CreatedAt           DATETIME2(3)   NOT NULL DEFAULT SYSUTCDATETIME(),
      UpdatedAt           DATETIME2(3)   NOT NULL DEFAULT SYSUTCDATETIME(),

      CONSTRAINT FK_WorkOrders_Technicians
          FOREIGN KEY (AssignedTechnicianId) REFERENCES Technicians (TechnicianId)
  );

  CREATE INDEX IX_WorkOrders_Status     ON WorkOrders ([Status]);
  CREATE INDEX IX_WorkOrders_Priority   ON WorkOrders (Priority);
  CREATE INDEX IX_WorkOrders_Technician ON WorkOrders (AssignedTechnicianId);
END;
GO
