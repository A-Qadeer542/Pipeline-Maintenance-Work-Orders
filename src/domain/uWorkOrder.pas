unit uWorkOrder;

interface

uses
  System.SysUtils;

type
  TWorkOrderStatus   = (woNew, woInProgress, woCompleted);
  TWorkOrderPriority = (woLow, woMedium, woHigh);

const
  WorkOrderStatusLabels: array[TWorkOrderStatus] of string = (
    'New', 'In Progress', 'Completed'
  );
  WorkOrderPriorityLabels: array[TWorkOrderPriority] of string = (
    'Low', 'Medium', 'High'
  );

  WorkOrderStatusDbTokens: array[TWorkOrderStatus] of string = (
    'New', 'InProgress', 'Completed'
  );
  WorkOrderPriorityDbTokens: array[TWorkOrderPriority] of string = (
    'Low', 'Medium', 'High'
  );

type
  TWorkOrderFilter = record
    Status: TWorkOrderStatus;
    Priority: TWorkOrderPriority;
    HasStatusFilter: Boolean;
    HasPriorityFilter: Boolean;
    class function None: TWorkOrderFilter; static;
    class function ByStatus(AStatus: TWorkOrderStatus): TWorkOrderFilter; static;
    class function ByPriority(APriority: TWorkOrderPriority): TWorkOrderFilter; static;
  end;

  TWorkOrder = class
  private
    FId: Integer;
    FTitle: string;
    FDescription: string;
    FLocation: string;
    FPriority: TWorkOrderPriority;
    FStatus: TWorkOrderStatus;
    FAssignedTechnicianId: Integer;
    FAssignedTechnicianName: string;
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
  public
    constructor Create; overload;
    constructor Create(const ATitle, ALocation: string;
      APriority: TWorkOrderPriority); overload;

    function IsNewRecord: Boolean;
    function IsCompleted: Boolean;
    function CanAdvanceStatus: Boolean;
    function NextStatus: TWorkOrderStatus;
    function StatusLabel: string;
    function PriorityLabel: string;

    property Id: Integer read FId write FId;
    property Title: string read FTitle write FTitle;
    property Description: string read FDescription write FDescription;
    property Location: string read FLocation write FLocation;
    property Priority: TWorkOrderPriority read FPriority write FPriority;
    property Status: TWorkOrderStatus read FStatus write FStatus;
    property AssignedTechnicianId: Integer read FAssignedTechnicianId write FAssignedTechnicianId;
    property AssignedTechnicianName: string read FAssignedTechnicianName write FAssignedTechnicianName;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
  end;

  EWorkOrderValidation = class(Exception);

implementation

{ TWorkOrderFilter }

class function TWorkOrderFilter.None: TWorkOrderFilter;
begin
  Result.HasStatusFilter   := False;
  Result.HasPriorityFilter := False;
end;

class function TWorkOrderFilter.ByStatus(AStatus: TWorkOrderStatus): TWorkOrderFilter;
begin
  Result := None;
  Result.Status          := AStatus;
  Result.HasStatusFilter := True;
end;

class function TWorkOrderFilter.ByPriority(APriority: TWorkOrderPriority): TWorkOrderFilter;
begin
  Result := None;
  Result.Priority          := APriority;
  Result.HasPriorityFilter := True;
end;

{ TWorkOrder }

constructor TWorkOrder.Create;
begin
  inherited;
  FId       := -1;
  FStatus   := woNew;
  FPriority := woMedium;
end;

constructor TWorkOrder.Create(const ATitle, ALocation: string;
  APriority: TWorkOrderPriority);
begin
  Create;
  FTitle    := ATitle;
  FLocation := ALocation;
  FPriority := APriority;
end;

function TWorkOrder.IsNewRecord: Boolean;
begin
  Result := FId < 1;
end;

function TWorkOrder.IsCompleted: Boolean;
begin
  Result := FStatus = woCompleted;
end;

function TWorkOrder.CanAdvanceStatus: Boolean;
begin
  Result := FStatus <> woCompleted;
end;

function TWorkOrder.NextStatus: TWorkOrderStatus;
begin
  case FStatus of
    woNew:        Result := woInProgress;
    woInProgress: Result := woCompleted;
  else
    Result := FStatus;
  end;
end;

function TWorkOrder.StatusLabel: string;
begin
  Result := WorkOrderStatusLabels[FStatus];
end;

function TWorkOrder.PriorityLabel: string;
begin
  Result := WorkOrderPriorityLabels[FPriority];
end;

end.
