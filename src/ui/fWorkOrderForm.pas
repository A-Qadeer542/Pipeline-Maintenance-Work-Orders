unit fWorkOrderForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Dialogs,
  uWorkOrder, uWorkOrderService;

type
  TWorkOrderForm = class(TForm)
    lblTitle: TLabel;
    lblLocation: TLabel;
    lblDescription: TLabel;
    lblPriority: TLabel;
    lblStatus: TLabel;
    edtTitle: TEdit;
    edtLocation: TEdit;
    memDescription: TMemo;
    cmbPriority: TComboBox;
    cmbStatus: TComboBox;
    btnSave: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FService: TWorkOrderService;
    FEditingId: Integer;
    procedure InitializeDropdowns;
    procedure PopulateFieldsFromWorkOrder(AId: Integer);
    procedure PersistWorkOrder;
    function  IsEditMode: Boolean;
  public
    class function ShowCreateDialog(AService: TWorkOrderService): Boolean;
    class function ShowEditDialog(AService: TWorkOrderService; AId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

{ --- public dialog entry points --- }

class function TWorkOrderForm.ShowCreateDialog(AService: TWorkOrderService): Boolean;
var
  Dlg: TWorkOrderForm;
begin
  Dlg := TWorkOrderForm.Create(nil);
  try
    Dlg.FService   := AService;
    Dlg.FEditingId := -1;
    Dlg.Caption    := 'New Work Order';
    Dlg.cmbStatus.Enabled := False;
    Result := (Dlg.ShowModal = mrOk);
  finally
    Dlg.Free;
  end;
end;

class function TWorkOrderForm.ShowEditDialog(AService: TWorkOrderService; AId: Integer): Boolean;
var
  Dlg: TWorkOrderForm;
begin
  Dlg := TWorkOrderForm.Create(nil);
  try
    Dlg.FService   := AService;
    Dlg.FEditingId := AId;
    Dlg.Caption    := Format('Edit Work Order #%d', [AId]);
    Dlg.PopulateFieldsFromWorkOrder(AId);
    Result := (Dlg.ShowModal = mrOk);
  finally
    Dlg.Free;
  end;
end;

{ --- form events --- }

procedure TWorkOrderForm.FormCreate(Sender: TObject);
begin
  InitializeDropdowns;
  cmbPriority.ItemIndex := Ord(woMedium);
  cmbStatus.ItemIndex   := Ord(woNew);
end;

procedure TWorkOrderForm.btnSaveClick(Sender: TObject);
begin
  try
    PersistWorkOrder;
    ModalResult := mrOk;
  except
    on E: EWorkOrderValidation do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

{ --- private helpers --- }

function TWorkOrderForm.IsEditMode: Boolean;
begin
  Result := FEditingId > 0;
end;

procedure TWorkOrderForm.InitializeDropdowns;
var
  P: TWorkOrderPriority;
  S: TWorkOrderStatus;
begin
  cmbPriority.Items.Clear;
  for P := Low(TWorkOrderPriority) to High(TWorkOrderPriority) do
    cmbPriority.Items.Add(WorkOrderPriorityLabels[P]);

  cmbStatus.Items.Clear;
  for S := Low(TWorkOrderStatus) to High(TWorkOrderStatus) do
    cmbStatus.Items.Add(WorkOrderStatusLabels[S]);
end;

procedure TWorkOrderForm.PopulateFieldsFromWorkOrder(AId: Integer);
var
  WorkOrder: TWorkOrder;
begin
  WorkOrder := FService.FetchWorkOrderById(AId);
  try
    edtTitle.Text          := WorkOrder.Title;
    edtLocation.Text       := WorkOrder.Location;
    memDescription.Text    := WorkOrder.Description;
    cmbPriority.ItemIndex  := Ord(WorkOrder.Priority);
    cmbStatus.ItemIndex    := Ord(WorkOrder.Status);
  finally
    WorkOrder.Free;
  end;
end;

procedure TWorkOrderForm.PersistWorkOrder;
var
  WorkOrder: TWorkOrder;
begin
  WorkOrder := TWorkOrder.Create;
  try
    WorkOrder.Id          := FEditingId;
    WorkOrder.Title       := edtTitle.Text;
    WorkOrder.Location    := edtLocation.Text;
    WorkOrder.Description := memDescription.Text;
    WorkOrder.Priority    := TWorkOrderPriority(cmbPriority.ItemIndex);

    if IsEditMode then
    begin
      WorkOrder.Status := TWorkOrderStatus(cmbStatus.ItemIndex);
      FService.UpdateWorkOrder(WorkOrder);
    end
    else
      FService.CreateWorkOrder(WorkOrder);
  finally
    WorkOrder.Free;
  end;
end;

end.
