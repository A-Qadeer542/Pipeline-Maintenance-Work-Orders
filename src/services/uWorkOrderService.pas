unit uWorkOrderService;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  uWorkOrder,
  uWorkOrderRepository;

type
  TWorkOrderService = class
  private
    FRepo: IWorkOrderRepository;
    procedure ValidateRequiredFields(AWorkOrder: TWorkOrder);
    procedure ValidateStatusTransition(ACurrentStatus, ANewStatus: TWorkOrderStatus);
  public
    constructor Create(ARepository: IWorkOrderRepository);

    function  FetchWorkOrders(const AFilter: TWorkOrderFilter): TObjectList<TWorkOrder>;
    function  FetchWorkOrderById(AId: Integer): TWorkOrder;
    function  CreateWorkOrder(AWorkOrder: TWorkOrder): Integer;
    procedure UpdateWorkOrder(AWorkOrder: TWorkOrder);
    procedure AdvanceWorkOrderStatus(AId: Integer);
  end;

implementation

constructor TWorkOrderService.Create(ARepository: IWorkOrderRepository);
begin
  inherited Create;
  FRepo := ARepository;
end;

{ --- validation --- }

procedure TWorkOrderService.ValidateRequiredFields(AWorkOrder: TWorkOrder);
begin
  if AWorkOrder = nil then
    raise EWorkOrderValidation.Create('No work order supplied.');

  if AWorkOrder.Title.Trim.IsEmpty then
    raise EWorkOrderValidation.Create('Title cannot be blank.');

  if AWorkOrder.Location.Trim.IsEmpty then
    raise EWorkOrderValidation.Create('Location cannot be blank.');

  if Length(AWorkOrder.Title) > MAX_TITLE_LENGTH then
    raise EWorkOrderValidation.CreateFmt(
      'Title must not exceed %d characters.', [MAX_TITLE_LENGTH]);

  if Length(AWorkOrder.Location) > MAX_LOCATION_LENGTH then
    raise EWorkOrderValidation.CreateFmt(
      'Location must not exceed %d characters.', [MAX_LOCATION_LENGTH]);
end;

procedure TWorkOrderService.ValidateStatusTransition(
  ACurrentStatus, ANewStatus: TWorkOrderStatus);
begin
  if not TWorkOrder.IsValidTransition(ACurrentStatus, ANewStatus) then
    raise EWorkOrderValidation.CreateFmt(
      'Cannot change status from "%s" to "%s".',
      [WorkOrderStatusLabels[ACurrentStatus], WorkOrderStatusLabels[ANewStatus]]);
end;

{ --- public API --- }

function TWorkOrderService.FetchWorkOrders(
  const AFilter: TWorkOrderFilter): TObjectList<TWorkOrder>;
begin
  Result := FRepo.FetchAll(AFilter);
end;

function TWorkOrderService.FetchWorkOrderById(AId: Integer): TWorkOrder;
begin
  Result := FRepo.FetchById(AId);
  if Result = nil then
    raise EWorkOrderValidation.CreateFmt('Work order #%d does not exist.', [AId]);
end;

function TWorkOrderService.CreateWorkOrder(AWorkOrder: TWorkOrder): Integer;
begin
  ValidateRequiredFields(AWorkOrder);
  AWorkOrder.Status    := woNew;
  AWorkOrder.CreatedAt := UtcNow;
  AWorkOrder.UpdatedAt := UtcNow;
  Result := FRepo.InsertWorkOrder(AWorkOrder);
end;

procedure TWorkOrderService.UpdateWorkOrder(AWorkOrder: TWorkOrder);
var
  Existing: TWorkOrder;
begin
  ValidateRequiredFields(AWorkOrder);

  Existing := FRepo.FetchById(AWorkOrder.Id);
  if Existing = nil then
    raise EWorkOrderValidation.CreateFmt('Work order #%d does not exist.', [AWorkOrder.Id]);

  try
    if Existing.IsCompleted then
      raise EWorkOrderValidation.Create('Completed work orders cannot be modified.');

    ValidateStatusTransition(Existing.Status, AWorkOrder.Status);
  finally
    Existing.Free;
  end;

  AWorkOrder.UpdatedAt := UtcNow;
  FRepo.UpdateWorkOrder(AWorkOrder);
end;

procedure TWorkOrderService.AdvanceWorkOrderStatus(AId: Integer);
var
  Existing: TWorkOrder;
begin
  Existing := FRepo.FetchById(AId);
  if Existing = nil then
    raise EWorkOrderValidation.CreateFmt('Work order #%d does not exist.', [AId]);

  try
    if not Existing.CanAdvanceStatus then
      raise EWorkOrderValidation.Create('This work order is already completed.');

    FRepo.UpdateWorkOrderStatus(Existing.Id, Existing.NextStatus);
  finally
    Existing.Free;
  end;
end;

end.
