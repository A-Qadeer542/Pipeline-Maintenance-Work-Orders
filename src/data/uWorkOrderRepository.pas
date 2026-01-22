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
    function GetAll(const AStatus: TWorkOrderStatus; const APriority: TWorkOrderPriority;
      const AUseStatus, AUsePriority: Boolean): TObjectList<TWorkOrder>;
    function GetById(const AId: Integer): TWorkOrder;
    function Insert(const AWorkOrder: TWorkOrder): Integer;
    procedure Update(const AWorkOrder: TWorkOrder);
    procedure UpdateStatus(const AId: Integer; const AStatus: TWorkOrderStatus);
  end;

  TWorkOrderRepository = class(TInterfacedObject, IWorkOrderRepository)
  private
    FConn: TFDConnection;
    function StatusToDb(const AStatus: TWorkOrderStatus): string;
    function PriorityToDb(const APriority: TWorkOrderPriority): string;
    function DbToStatus(const AValue: string): TWorkOrderStatus;
    function DbToPriority(const AValue: string): TWorkOrderPriority;
    function MapQueryToWorkOrder(AQuery: TFDQuery): TWorkOrder;
  public
    constructor Create(AConn: TFDConnection);
    function GetAll(const AStatus: TWorkOrderStatus; const APriority: TWorkOrderPriority;
      const AUseStatus, AUsePriority: Boolean): TObjectList<TWorkOrder>;
    function GetById(const AId: Integer): TWorkOrder;
    function Insert(const AWorkOrder: TWorkOrder): Integer;
    procedure Update(const AWorkOrder: TWorkOrder);
    procedure UpdateStatus(const AId: Integer; const AStatus: TWorkOrderStatus);
  end;

implementation

{ TWorkOrderRepository }

constructor TWorkOrderRepository.Create(AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
end;

function TWorkOrderRepository.DbToPriority(const AValue: string): TWorkOrderPriority;
begin
  if SameText(AValue, 'Low') then
    Result := woLow
  else if SameText(AValue, 'Medium') then
    Result := woMedium
  else
    Result := woHigh;
end;

function TWorkOrderRepository.DbToStatus(const AValue: string): TWorkOrderStatus;
begin
  if SameText(AValue, 'New') then
    Result := woNew
  else if SameText(AValue, 'InProgress') then
    Result := woInProgress
  else
    Result := woCompleted;
end;

function TWorkOrderRepository.GetAll(const AStatus: TWorkOrderStatus;
  const APriority: TWorkOrderPriority; const AUseStatus, AUsePriority: Boolean): TObjectList<TWorkOrder>;
var
  Q: TFDQuery;
  SQL: TStringList;
begin
  Result := TObjectList<TWorkOrder>.Create(True);
  Q := TFDQuery.Create(nil);
  SQL := TStringList.Create;
  try
    Q.Connection := FConn;
    SQL.Add('SELECT WorkOrderId, Title, Description, Location, Priority, Status,');
    SQL.Add('       AssignedTechnicianId, CreatedAt, UpdatedAt');
    SQL.Add('FROM WorkOrders');
    SQL.Add('WHERE 1 = 1');
    if AUseStatus then
      SQL.Add('  AND Status = :Status');
    if AUsePriority then
      SQL.Add('  AND Priority = :Priority');
    SQL.Add('ORDER BY CreatedAt DESC');
    Q.SQL.Text := SQL.Text;
    if AUseStatus then
      Q.ParamByName('Status').AsString := StatusToDb(AStatus);
    if AUsePriority then
      Q.ParamByName('Priority').AsString := PriorityToDb(APriority);
    Q.Open;
    while not Q.Eof do
    begin
      Result.Add(MapQueryToWorkOrder(Q));
      Q.Next;
    end;
  finally
    SQL.Free;
    Q.Free;
  end;
end;

function TWorkOrderRepository.GetById(const AId: Integer): TWorkOrder;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT WorkOrderId, Title, Description, Location, Priority, Status,' +
      ' AssignedTechnicianId, CreatedAt, UpdatedAt' +
      ' FROM WorkOrders WHERE WorkOrderId = :Id';
    Q.ParamByName('Id').AsInteger := AId;
    Q.Open;
    if not Q.Eof then
      Result := MapQueryToWorkOrder(Q);
  finally
    Q.Free;
  end;
end;

function TWorkOrderRepository.Insert(const AWorkOrder: TWorkOrder): Integer;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'INSERT INTO WorkOrders (Title, Description, Location, Priority, Status,' +
      ' AssignedTechnicianId, CreatedAt, UpdatedAt) ' +
      'OUTPUT INSERTED.WorkOrderId ' +
      'VALUES (:Title, :Description, :Location, :Priority, :Status,' +
      ' :AssignedTechnicianId, :CreatedAt, :UpdatedAt)';
    Q.ParamByName('Title').AsString := AWorkOrder.Title;
    Q.ParamByName('Description').AsString := AWorkOrder.Description;
    Q.ParamByName('Location').AsString := AWorkOrder.Location;
    Q.ParamByName('Priority').AsString := PriorityToDb(AWorkOrder.Priority);
    Q.ParamByName('Status').AsString := StatusToDb(AWorkOrder.Status);
    if AWorkOrder.AssignedTechnicianId = 0 then
      Q.ParamByName('AssignedTechnicianId').Clear
    else
      Q.ParamByName('AssignedTechnicianId').AsInteger := AWorkOrder.AssignedTechnicianId;
    Q.ParamByName('CreatedAt').AsDateTime := AWorkOrder.CreatedAt;
    Q.ParamByName('UpdatedAt').AsDateTime := AWorkOrder.UpdatedAt;
    Q.Open;
    Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

function TWorkOrderRepository.MapQueryToWorkOrder(AQuery: TFDQuery): TWorkOrder;
begin
  Result := TWorkOrder.Create;
  Result.Id := AQuery.FieldByName('WorkOrderId').AsInteger;
  Result.Title := AQuery.FieldByName('Title').AsString;
  Result.Description := AQuery.FieldByName('Description').AsString;
  Result.Location := AQuery.FieldByName('Location').AsString;
  Result.Priority := DbToPriority(AQuery.FieldByName('Priority').AsString);
  Result.Status := DbToStatus(AQuery.FieldByName('Status').AsString);
  Result.AssignedTechnicianId := AQuery.FieldByName('AssignedTechnicianId').AsInteger;
  Result.CreatedAt := AQuery.FieldByName('CreatedAt').AsDateTime;
  Result.UpdatedAt := AQuery.FieldByName('UpdatedAt').AsDateTime;
end;

function TWorkOrderRepository.PriorityToDb(const APriority: TWorkOrderPriority): string;
begin
  case APriority of
    woLow: Result := 'Low';
    woMedium: Result := 'Medium';
  else
    Result := 'High';
  end;
end;

function TWorkOrderRepository.StatusToDb(const AStatus: TWorkOrderStatus): string;
begin
  case AStatus of
    woNew: Result := 'New';
    woInProgress: Result := 'InProgress';
  else
    Result := 'Completed';
  end;
end;

procedure TWorkOrderRepository.Update(const AWorkOrder: TWorkOrder);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'UPDATE WorkOrders ' +
      'SET Title = :Title,' +
      ' Description = :Description,' +
      ' Location = :Location,' +
      ' Priority = :Priority,' +
      ' Status = :Status,' +
      ' AssignedTechnicianId = :AssignedTechnicianId,' +
      ' UpdatedAt = :UpdatedAt ' +
      'WHERE WorkOrderId = :Id';
    Q.ParamByName('Id').AsInteger := AWorkOrder.Id;
    Q.ParamByName('Title').AsString := AWorkOrder.Title;
    Q.ParamByName('Description').AsString := AWorkOrder.Description;
    Q.ParamByName('Location').AsString := AWorkOrder.Location;
    Q.ParamByName('Priority').AsString := PriorityToDb(AWorkOrder.Priority);
    Q.ParamByName('Status').AsString := StatusToDb(AWorkOrder.Status);
    if AWorkOrder.AssignedTechnicianId = 0 then
      Q.ParamByName('AssignedTechnicianId').Clear
    else
      Q.ParamByName('AssignedTechnicianId').AsInteger := AWorkOrder.AssignedTechnicianId;
    Q.ParamByName('UpdatedAt').AsDateTime := AWorkOrder.UpdatedAt;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TWorkOrderRepository.UpdateStatus(const AId: Integer; const AStatus: TWorkOrderStatus);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'UPDATE WorkOrders SET Status = :Status, UpdatedAt = SYSUTCDATETIME() WHERE WorkOrderId = :Id';
    Q.ParamByName('Id').AsInteger := AId;
    Q.ParamByName('Status').AsString := StatusToDb(AStatus);
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
