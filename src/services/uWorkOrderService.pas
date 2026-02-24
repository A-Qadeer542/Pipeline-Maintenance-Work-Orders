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
    procedure StampTimestampsForCreate(AWorkOrder: TWorkOrder);
    procedure StampTimestampForUpdate(AWorkOrder: TWorkOrder);
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

  if Length(AWorkOrder.Title) > 200 then
    raise EWorkOrderValidation.Create('Title must not exceed 200 characters.');
end;

procedure TWorkOrderService.StampTimestampsForCreate(AWorkOrder: TWorkOrder);
begin
  AWorkOrder.Status    := woNew;
  AWorkOrder.CreatedAt := Now;
  AWorkOrder.UpdatedAt := Now;
end;

procedure TWorkOrderService.StampTimestampForUpdate(AWorkOrder: TWorkOrder);
begin
  AWorkOrder.UpdatedAt := Now;
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
  StampTimestampsForCreate(AWorkOrder);
  Result := FRepo.InsertWorkOrder(AWorkOrder);
end;

procedure TWorkOrderService.UpdateWorkOrder(AWorkOrder: TWorkOrder);
begin
  ValidateRequiredFields(AWorkOrder);
  StampTimestampForUpdate(AWorkOrder);
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
