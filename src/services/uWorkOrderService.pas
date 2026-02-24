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
    procedure Validate(AWO: TWorkOrder);
  public
    constructor Create(ARepo: IWorkOrderRepository);

    function  List(AStatus: TWorkOrderStatus; APriority: TWorkOrderPriority;
                   AFilterStatus, AFilterPriority: Boolean): TObjectList<TWorkOrder>;
    function  GetById(AId: Integer): TWorkOrder;
    function  CreateWorkOrder(AWO: TWorkOrder): Integer;
    procedure UpdateWorkOrder(AWO: TWorkOrder);
    procedure AdvanceStatus(AId: Integer);
  end;

implementation

constructor TWorkOrderService.Create(ARepo: IWorkOrderRepository);
begin
  inherited Create;
  FRepo := ARepo;
end;

procedure TWorkOrderService.Validate(AWO: TWorkOrder);
begin
  if AWO = nil then
    raise EWorkOrderValidation.Create('No work order supplied.');

  if AWO.Title.Trim.IsEmpty then
    raise EWorkOrderValidation.Create('Title cannot be blank.');

  if AWO.Location.Trim.IsEmpty then
    raise EWorkOrderValidation.Create('Location cannot be blank.');

  if (Length(AWO.Title) > 200) then
    raise EWorkOrderValidation.Create('Title must not exceed 200 characters.');
end;

function TWorkOrderService.List(AStatus: TWorkOrderStatus;
  APriority: TWorkOrderPriority;
  AFilterStatus, AFilterPriority: Boolean): TObjectList<TWorkOrder>;
begin
  Result := FRepo.GetAll(AStatus, APriority, AFilterStatus, AFilterPriority);
end;

function TWorkOrderService.GetById(AId: Integer): TWorkOrder;
begin
  Result := FRepo.GetById(AId);
  if Result = nil then
    raise EWorkOrderValidation.CreateFmt('Work order #%d does not exist.', [AId]);
end;

function TWorkOrderService.CreateWorkOrder(AWO: TWorkOrder): Integer;
begin
  Validate(AWO);
  AWO.Status    := woNew;
  AWO.CreatedAt := Now;
  AWO.UpdatedAt := Now;
  Result := FRepo.Insert(AWO);
end;

procedure TWorkOrderService.UpdateWorkOrder(AWO: TWorkOrder);
begin
  Validate(AWO);
  AWO.UpdatedAt := Now;
  FRepo.Update(AWO);
end;

procedure TWorkOrderService.AdvanceStatus(AId: Integer);
var
  WO: TWorkOrder;
begin
  WO := FRepo.GetById(AId);
  if WO = nil then
    raise EWorkOrderValidation.CreateFmt('Work order #%d does not exist.', [AId]);

  try
    case WO.Status of
      woNew:        WO.Status := woInProgress;
      woInProgress: WO.Status := woCompleted;
      woCompleted:
        raise EWorkOrderValidation.Create('This work order is already completed.');
    end;
    FRepo.UpdateStatus(WO.Id, WO.Status);
  finally
    WO.Free;
  end;
end;

end.
