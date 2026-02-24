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
    function FetchAll(const AFilter: TWorkOrderFilter): TObjectList<TWorkOrder>;
    function FetchById(AId: Integer): TWorkOrder;
    function InsertWorkOrder(AWorkOrder: TWorkOrder): Integer;
    procedure UpdateWorkOrder(AWorkOrder: TWorkOrder);
    procedure UpdateWorkOrderStatus(AId: Integer; ANewStatus: TWorkOrderStatus);
  end;

  TWorkOrderRepository = class(TInterfacedObject, IWorkOrderRepository)
  private
    FConn: TFDConnection;
    function CreateQuery: TFDQuery;
    function MapRowToEntity(AQuery: TFDQuery): TWorkOrder;
    function ParseStatus(const ADbValue: string): TWorkOrderStatus;
    function ParsePriority(const ADbValue: string): TWorkOrderPriority;
    procedure BindWorkOrderParams(AQuery: TFDQuery; AWorkOrder: TWorkOrder);
  public
    constructor Create(AConnection: TFDConnection);

    function FetchAll(const AFilter: TWorkOrderFilter): TObjectList<TWorkOrder>;
    function FetchById(AId: Integer): TWorkOrder;
    function InsertWorkOrder(AWorkOrder: TWorkOrder): Integer;
    procedure UpdateWorkOrder(AWorkOrder: TWorkOrder);
    procedure UpdateWorkOrderStatus(AId: Integer; ANewStatus: TWorkOrderStatus);
  end;

implementation

const
  SELECT_COLUMNS =
    'wo.WorkOrderId, wo.Title, wo.[Description], wo.[Location], ' +
    'wo.Priority, wo.[Status], wo.AssignedTechnicianId, '          +
    'wo.CreatedAt, wo.UpdatedAt, t.FullName AS TechnicianName';

  FROM_CLAUSE =
    ' FROM WorkOrders wo' +
    ' LEFT JOIN Technicians t ON t.TechnicianId = wo.AssignedTechnicianId';

{ TWorkOrderRepository }

constructor TWorkOrderRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  FConn := AConnection;
end;

function TWorkOrderRepository.CreateQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConn;
end;

function TWorkOrderRepository.ParsePriority(const ADbValue: string): TWorkOrderPriority;
var
  P: TWorkOrderPriority;
begin
  for P := Low(TWorkOrderPriority) to High(TWorkOrderPriority) do
    if SameText(WorkOrderPriorityDbTokens[P], ADbValue) then
      Exit(P);
  Result := woMedium;
end;

function TWorkOrderRepository.ParseStatus(const ADbValue: string): TWorkOrderStatus;
var
  S: TWorkOrderStatus;
begin
  for S := Low(TWorkOrderStatus) to High(TWorkOrderStatus) do
    if SameText(WorkOrderStatusDbTokens[S], ADbValue) then
      Exit(S);
  Result := woNew;
end;

function TWorkOrderRepository.MapRowToEntity(AQuery: TFDQuery): TWorkOrder;
begin
  Result := TWorkOrder.Create;
  Result.Id                    := AQuery.FieldByName('WorkOrderId').AsInteger;
  Result.Title                 := AQuery.FieldByName('Title').AsString;
  Result.Description           := AQuery.FieldByName('Description').AsString;
  Result.Location              := AQuery.FieldByName('Location').AsString;
  Result.Priority              := ParsePriority(AQuery.FieldByName('Priority').AsString);
  Result.Status                := ParseStatus(AQuery.FieldByName('Status').AsString);
  Result.AssignedTechnicianId  := AQuery.FieldByName('AssignedTechnicianId').AsInteger;
  Result.AssignedTechnicianName:= AQuery.FieldByName('TechnicianName').AsString;
  Result.CreatedAt             := AQuery.FieldByName('CreatedAt').AsDateTime;
  Result.UpdatedAt             := AQuery.FieldByName('UpdatedAt').AsDateTime;
end;

procedure TWorkOrderRepository.BindWorkOrderParams(AQuery: TFDQuery; AWorkOrder: TWorkOrder);
begin
  AQuery.ParamByName('pTitle').AsString    := AWorkOrder.Title;
  AQuery.ParamByName('pDesc').AsString     := AWorkOrder.Description;
  AQuery.ParamByName('pLoc').AsString      := AWorkOrder.Location;
  AQuery.ParamByName('pPriority').AsString := WorkOrderPriorityDbTokens[AWorkOrder.Priority];
  AQuery.ParamByName('pStatus').AsString   := WorkOrderStatusDbTokens[AWorkOrder.Status];

  if AWorkOrder.AssignedTechnicianId > 0 then
    AQuery.ParamByName('pTechId').AsInteger := AWorkOrder.AssignedTechnicianId
  else
    AQuery.ParamByName('pTechId').Clear;
end;

{ --- queries --- }

function TWorkOrderRepository.FetchAll(const AFilter: TWorkOrderFilter): TObjectList<TWorkOrder>;
var
  Query: TFDQuery;
  WhereParts: string;
begin
  Result := TObjectList<TWorkOrder>.Create(True);
  Query := CreateQuery;
  try
    WhereParts := ' WHERE 1=1';
    if AFilter.HasStatusFilter then
      WhereParts := WhereParts + ' AND wo.[Status] = :pStatus';
    if AFilter.HasPriorityFilter then
      WhereParts := WhereParts + ' AND wo.Priority = :pPriority';

    Query.SQL.Text := 'SELECT ' + SELECT_COLUMNS + FROM_CLAUSE +
                      WhereParts + ' ORDER BY wo.CreatedAt DESC';

    if AFilter.HasStatusFilter then
      Query.ParamByName('pStatus').AsString := WorkOrderStatusDbTokens[AFilter.Status];
    if AFilter.HasPriorityFilter then
      Query.ParamByName('pPriority').AsString := WorkOrderPriorityDbTokens[AFilter.Priority];

    Query.Open;
    while not Query.Eof do
    begin
      Result.Add(MapRowToEntity(Query));
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TWorkOrderRepository.FetchById(AId: Integer): TWorkOrder;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := CreateQuery;
  try
    Query.SQL.Text := 'SELECT ' + SELECT_COLUMNS + FROM_CLAUSE +
                      ' WHERE wo.WorkOrderId = :pId';
    Query.ParamByName('pId').AsInteger := AId;
    Query.Open;
    if not Query.Eof then
      Result := MapRowToEntity(Query);
  finally
    Query.Free;
  end;
end;

function TWorkOrderRepository.InsertWorkOrder(AWorkOrder: TWorkOrder): Integer;
var
  Query: TFDQuery;
begin
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'INSERT INTO WorkOrders '                                              +
      '(Title, [Description], [Location], Priority, [Status], '             +
      ' AssignedTechnicianId, CreatedAt, UpdatedAt) '                        +
      'OUTPUT INSERTED.WorkOrderId '                                         +
      'VALUES (:pTitle, :pDesc, :pLoc, :pPriority, :pStatus, '              +
      ' :pTechId, :pCreated, :pUpdated)';

    BindWorkOrderParams(Query, AWorkOrder);
    Query.ParamByName('pCreated').AsDateTime := AWorkOrder.CreatedAt;
    Query.ParamByName('pUpdated').AsDateTime := AWorkOrder.UpdatedAt;
    Query.Open;

    Result := Query.Fields[0].AsInteger;
  finally
    Query.Free;
  end;
end;

procedure TWorkOrderRepository.UpdateWorkOrder(AWorkOrder: TWorkOrder);
var
  Query: TFDQuery;
begin
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'UPDATE WorkOrders SET '                          +
      '  Title = :pTitle, '                             +
      '  [Description] = :pDesc, '                      +
      '  [Location] = :pLoc, '                           +
      '  Priority = :pPriority, '                       +
      '  [Status] = :pStatus, '                          +
      '  AssignedTechnicianId = :pTechId, '             +
      '  UpdatedAt = :pUpdated '                        +
      'WHERE WorkOrderId = :pId';

    Query.ParamByName('pId').AsInteger := AWorkOrder.Id;
    BindWorkOrderParams(Query, AWorkOrder);
    Query.ParamByName('pUpdated').AsDateTime := AWorkOrder.UpdatedAt;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

procedure TWorkOrderRepository.UpdateWorkOrderStatus(AId: Integer; ANewStatus: TWorkOrderStatus);
var
  Query: TFDQuery;
begin
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'UPDATE WorkOrders SET [Status] = :pStatus, UpdatedAt = SYSUTCDATETIME() ' +
      'WHERE WorkOrderId = :pId';
    Query.ParamByName('pId').AsInteger    := AId;
    Query.ParamByName('pStatus').AsString := WorkOrderStatusDbTokens[ANewStatus];
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

end.
