unit uWorkOrderRepository;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  uWorkOrder;

type
  IWorkOrderRepository = interface
    ['{E8A1A6EF-0C1C-4B77-B6CE-7A2BBF76A3A4}']
    function GetAll(AStatus: TWorkOrderStatus; APriority: TWorkOrderPriority;
      AFilterStatus, AFilterPriority: Boolean): TObjectList<TWorkOrder>;
    function GetById(AId: Integer): TWorkOrder;
    function Insert(AWO: TWorkOrder): Integer;
    procedure Update(AWO: TWorkOrder);
    procedure UpdateStatus(AId: Integer; ANewStatus: TWorkOrderStatus);
  end;

  TWorkOrderRepository = class(TInterfacedObject, IWorkOrderRepository)
  private
    FConn: TFDConnection;
    function RowToWorkOrder(Q: TFDQuery): TWorkOrder;
    function DbToStatus(const S: string): TWorkOrderStatus;
    function DbToPriority(const S: string): TWorkOrderPriority;
  public
    constructor Create(AConn: TFDConnection);

    function GetAll(AStatus: TWorkOrderStatus; APriority: TWorkOrderPriority;
      AFilterStatus, AFilterPriority: Boolean): TObjectList<TWorkOrder>;
    function GetById(AId: Integer): TWorkOrder;
    function Insert(AWO: TWorkOrder): Integer;
    procedure Update(AWO: TWorkOrder);
    procedure UpdateStatus(AId: Integer; ANewStatus: TWorkOrderStatus);
  end;

implementation

const
  SQL_BASE_COLUMNS =
    'wo.WorkOrderId, wo.Title, wo.[Description], wo.[Location], ' +
    'wo.Priority, wo.[Status], wo.AssignedTechnicianId, '          +
    'wo.CreatedAt, wo.UpdatedAt, t.FullName AS TechnicianName';

  SQL_BASE_FROM =
    ' FROM WorkOrders wo' +
    ' LEFT JOIN Technicians t ON t.TechnicianId = wo.AssignedTechnicianId';

{ TWorkOrderRepository }

constructor TWorkOrderRepository.Create(AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
end;

function TWorkOrderRepository.DbToPriority(const S: string): TWorkOrderPriority;
var
  P: TWorkOrderPriority;
begin
  for P := Low(TWorkOrderPriority) to High(TWorkOrderPriority) do
    if SameText(WorkOrderPriorityDbTokens[P], S) then
      Exit(P);
  Result := woMedium;
end;

function TWorkOrderRepository.DbToStatus(const S: string): TWorkOrderStatus;
var
  St: TWorkOrderStatus;
begin
  for St := Low(TWorkOrderStatus) to High(TWorkOrderStatus) do
    if SameText(WorkOrderStatusDbTokens[St], S) then
      Exit(St);
  Result := woNew;
end;

function TWorkOrderRepository.RowToWorkOrder(Q: TFDQuery): TWorkOrder;
begin
  Result := TWorkOrder.Create;
  Result.Id                    := Q.FieldByName('WorkOrderId').AsInteger;
  Result.Title                 := Q.FieldByName('Title').AsString;
  Result.Description           := Q.FieldByName('Description').AsString;
  Result.Location              := Q.FieldByName('Location').AsString;
  Result.Priority              := DbToPriority(Q.FieldByName('Priority').AsString);
  Result.Status                := DbToStatus(Q.FieldByName('Status').AsString);
  Result.AssignedTechnicianId  := Q.FieldByName('AssignedTechnicianId').AsInteger;
  Result.AssignedTechnicianName:= Q.FieldByName('TechnicianName').AsString;
  Result.CreatedAt             := Q.FieldByName('CreatedAt').AsDateTime;
  Result.UpdatedAt             := Q.FieldByName('UpdatedAt').AsDateTime;
end;

{ ---------- queries ---------- }

function TWorkOrderRepository.GetAll(AStatus: TWorkOrderStatus;
  APriority: TWorkOrderPriority;
  AFilterStatus, AFilterPriority: Boolean): TObjectList<TWorkOrder>;
var
  Q: TFDQuery;
  WhereClause: string;
begin
  Result := TObjectList<TWorkOrder>.Create(True);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;

    WhereClause := ' WHERE 1=1';
    if AFilterStatus then
      WhereClause := WhereClause + ' AND wo.[Status] = :pStatus';
    if AFilterPriority then
      WhereClause := WhereClause + ' AND wo.Priority = :pPriority';

    Q.SQL.Text := 'SELECT ' + SQL_BASE_COLUMNS + SQL_BASE_FROM +
                  WhereClause + ' ORDER BY wo.CreatedAt DESC';

    if AFilterStatus then
      Q.ParamByName('pStatus').AsString := WorkOrderStatusDbTokens[AStatus];
    if AFilterPriority then
      Q.ParamByName('pPriority').AsString := WorkOrderPriorityDbTokens[APriority];

    Q.Open;
    while not Q.Eof do
    begin
      Result.Add(RowToWorkOrder(Q));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TWorkOrderRepository.GetById(AId: Integer): TWorkOrder;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'SELECT ' + SQL_BASE_COLUMNS + SQL_BASE_FROM +
                  ' WHERE wo.WorkOrderId = :pId';
    Q.ParamByName('pId').AsInteger := AId;
    Q.Open;
    if not Q.Eof then
      Result := RowToWorkOrder(Q);
  finally
    Q.Free;
  end;
end;

function TWorkOrderRepository.Insert(AWO: TWorkOrder): Integer;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'INSERT INTO WorkOrders '                                              +
      '(Title, [Description], [Location], Priority, [Status], '             +
      ' AssignedTechnicianId, CreatedAt, UpdatedAt) '                        +
      'OUTPUT INSERTED.WorkOrderId '                                         +
      'VALUES (:pTitle, :pDesc, :pLoc, :pPriority, :pStatus, '              +
      ' :pTechId, :pCreated, :pUpdated)';

    Q.ParamByName('pTitle').AsString    := AWO.Title;
    Q.ParamByName('pDesc').AsString     := AWO.Description;
    Q.ParamByName('pLoc').AsString      := AWO.Location;
    Q.ParamByName('pPriority').AsString := WorkOrderPriorityDbTokens[AWO.Priority];
    Q.ParamByName('pStatus').AsString   := WorkOrderStatusDbTokens[AWO.Status];

    if AWO.AssignedTechnicianId > 0 then
      Q.ParamByName('pTechId').AsInteger := AWO.AssignedTechnicianId
    else
      Q.ParamByName('pTechId').Clear;

    Q.ParamByName('pCreated').AsDateTime := AWO.CreatedAt;
    Q.ParamByName('pUpdated').AsDateTime := AWO.UpdatedAt;
    Q.Open;

    Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TWorkOrderRepository.Update(AWO: TWorkOrder);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'UPDATE WorkOrders SET '                          +
      '  Title = :pTitle, '                             +
      '  [Description] = :pDesc, '                      +
      '  [Location] = :pLoc, '                           +
      '  Priority = :pPriority, '                       +
      '  [Status] = :pStatus, '                          +
      '  AssignedTechnicianId = :pTechId, '             +
      '  UpdatedAt = :pUpdated '                        +
      'WHERE WorkOrderId = :pId';

    Q.ParamByName('pId').AsInteger      := AWO.Id;
    Q.ParamByName('pTitle').AsString    := AWO.Title;
    Q.ParamByName('pDesc').AsString     := AWO.Description;
    Q.ParamByName('pLoc').AsString      := AWO.Location;
    Q.ParamByName('pPriority').AsString := WorkOrderPriorityDbTokens[AWO.Priority];
    Q.ParamByName('pStatus').AsString   := WorkOrderStatusDbTokens[AWO.Status];

    if AWO.AssignedTechnicianId > 0 then
      Q.ParamByName('pTechId').AsInteger := AWO.AssignedTechnicianId
    else
      Q.ParamByName('pTechId').Clear;

    Q.ParamByName('pUpdated').AsDateTime := AWO.UpdatedAt;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWorkOrderRepository.UpdateStatus(AId: Integer; ANewStatus: TWorkOrderStatus);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'UPDATE WorkOrders SET [Status] = :pStatus, UpdatedAt = SYSUTCDATETIME() ' +
      'WHERE WorkOrderId = :pId';
    Q.ParamByName('pId').AsInteger    := AId;
    Q.ParamByName('pStatus').AsString := WorkOrderStatusDbTokens[ANewStatus];
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
