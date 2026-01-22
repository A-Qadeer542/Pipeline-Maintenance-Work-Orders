program PipelineMaintenanceWorkOrders;

uses
  Vcl.Forms,
  fMain in 'src\ui\fMain.pas' {MainForm},
  fWorkOrderForm in 'src\ui\fWorkOrderForm.pas' {WorkOrderForm},
  uWorkOrder in 'src\domain\uWorkOrder.pas',
  uTechnician in 'src\domain\uTechnician.pas',
  uDBConnection in 'src\data\uDBConnection.pas',
  uWorkOrderRepository in 'src\data\uWorkOrderRepository.pas',
  uTechnicianRepository in 'src\data\uTechnicianRepository.pas',
  uWorkOrderService in 'src\services\uWorkOrderService.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
