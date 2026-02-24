-- ============================================================
-- Seed data for local / demo testing
-- Run after create_tables.sql
-- ============================================================

SET NOCOUNT ON;

-- Technicians
IF NOT EXISTS (SELECT 1 FROM Technicians)
BEGIN
  INSERT INTO Technicians (FullName, Email, Phone)
  VALUES
    ('James Mwangi',  'j.mwangi@pipelinecorp.co',  '+254-700-111222'),
    ('Sarah Oduya',   's.oduya@pipelinecorp.co',   '+254-700-333444'),
    ('Rashid Farah',  'r.farah@pipelinecorp.co',   '+254-700-555666');
END;

-- Sample work orders
IF NOT EXISTS (SELECT 1 FROM WorkOrders)
BEGIN
  INSERT INTO WorkOrders (Title, [Description], [Location], Priority, [Status], AssignedTechnicianId)
  VALUES
    ('Valve replacement - KM 42',
     'Replace corroded gate valve on trunk line segment B. Isolate section first.',
     'Mombasa Rd, KM 42', 'High', 'New', 1),

    ('Cathodic protection check',
     'Annual CP reading on buried segment near pump station 7.',
     'Pump Station 7, Naivasha', 'Medium', 'InProgress', 2),

    ('Weld inspection - flange joint',
     'NDT inspection of flange weld reported as suspect during last pigging run.',
     'Tank Farm, Kisumu', 'High', 'New', NULL),

    ('Routine pressure test',
     'Hydrostatic test on newly laid 6-inch lateral.',
     'Eldoret Depot', 'Low', 'Completed', 3);
END;
GO
