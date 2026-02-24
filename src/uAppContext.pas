unit uAppContext;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  uWorkOrderRepository,
  uTechnicianRepository,
  uWorkOrderService,
  uDBConnection;

type
  TAppContext = class
  private
    FConnection: TFDConnection;
    FWorkOrderRepo: IWorkOrderRepository;
    FTechnicianRepo: ITechnicianRepository;
    FWorkOrderService: TWorkOrderService;
  public
    constructor Create;
    destructor Destroy; override;

    property WorkOrderService: TWorkOrderService read FWorkOrderService;
  end;

implementation

constructor TAppContext.Create;
begin
  inherited;
  FConnection       := TDBConnectionFactory.CreateConnection;
  FWorkOrderRepo    := TWorkOrderRepository.Create(FConnection);
  FTechnicianRepo   := TTechnicianRepository.Create(FConnection);
  FWorkOrderService := TWorkOrderService.Create(FWorkOrderRepo, FTechnicianRepo);
end;

destructor TAppContext.Destroy;
begin
  FreeAndNil(FWorkOrderService);
  FWorkOrderRepo  := nil;
  FTechnicianRepo := nil;
  FreeAndNil(FConnection);
  inherited;
end;

end.
