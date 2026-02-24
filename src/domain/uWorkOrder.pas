unit uWorkOrder;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.TimeSpan;

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

  MAX_TITLE_LENGTH    = 200;
  MAX_LOCATION_LENGTH = 200;

type
  TWorkOrderFilter = record
    Status: TWorkOrderStatus;
    Priority: TWorkOrderPriority;
    HasStatusFilter: Boolean;
    HasPriorityFilter: Boolean;
    class function None: TWorkOrderFilter; static;
    class function ByStatus(AStatus: TWorkOrderStatus): TWorkOrderFilter; static;
    class function ByPriority(APriority: TWorkOrderPriority): TWorkOrderFilter; static;
    class function ByStatusAndPriority(AStatus: TWorkOrderStatus;
      APriority: TWorkOrderPriority): TWorkOrderFilter; static;
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
    function HasTechnician: Boolean;
    function CanAdvanceStatus: Boolean;
    function NextStatus: TWorkOrderStatus;
    class function IsValidTransition(AFrom, ATo: TWorkOrderStatus): Boolean; static;
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

function UtcNow: TDateTime;

implementation

function UtcNow: TDateTime;
begin
  Result := TTimeZone.Local.ToUniversalTime(Now);
end;

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

class function TWorkOrderFilter.ByStatusAndPriority(AStatus: TWorkOrderStatus;
  APriority: TWorkOrderPriority): TWorkOrderFilter;
begin
  Result.Status            := AStatus;
  Result.Priority          := APriority;
  Result.HasStatusFilter   := True;
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

function TWorkOrder.HasTechnician: Boolean;
begin
  Result := FAssignedTechnicianId > 0;
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

class function TWorkOrder.IsValidTransition(AFrom, ATo: TWorkOrderStatus): Boolean;
begin
  if AFrom = ATo then
    Exit(True);

  case AFrom of
    woNew:        Result := ATo = woInProgress;
    woInProgress: Result := ATo = woCompleted;
  else
    Result := False;
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
