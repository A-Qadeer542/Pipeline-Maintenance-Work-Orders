unit uAppContext;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  uWorkOrderRepository,
  uWorkOrderService,
  uDBConnection;

type
  TAppContext = class
  private
    FConnection: TFDConnection;
    FWorkOrderRepo: IWorkOrderRepository;
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
  FWorkOrderService := TWorkOrderService.Create(FWorkOrderRepo);
end;

destructor TAppContext.Destroy;
begin
  FreeAndNil(FWorkOrderService);
  FWorkOrderRepo := nil;
  FreeAndNil(FConnection);
  inherited;
end;

end.
