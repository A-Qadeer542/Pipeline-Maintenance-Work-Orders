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
    procedure PopulateCombos;
    procedure LoadFromWorkOrder(AId: Integer);
    procedure SaveToWorkOrder;
  public
    class function ExecuteNew(AService: TWorkOrderService): Boolean;
    class function ExecuteEdit(AService: TWorkOrderService; AId: Integer): Boolean;
  end;

implementation

{$R *.dfm}

{ --- static entry points --- }

class function TWorkOrderForm.ExecuteNew(AService: TWorkOrderService): Boolean;
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

class function TWorkOrderForm.ExecuteEdit(AService: TWorkOrderService; AId: Integer): Boolean;
var
  Dlg: TWorkOrderForm;
begin
  Dlg := TWorkOrderForm.Create(nil);
  try
    Dlg.FService   := AService;
    Dlg.FEditingId := AId;
    Dlg.Caption    := Format('Edit Work Order #%d', [AId]);
    Dlg.LoadFromWorkOrder(AId);
    Result := (Dlg.ShowModal = mrOk);
  finally
    Dlg.Free;
  end;
end;

{ --- form events --- }

procedure TWorkOrderForm.FormCreate(Sender: TObject);
begin
  PopulateCombos;
  cmbPriority.ItemIndex := Ord(woMedium);
  cmbStatus.ItemIndex   := Ord(woNew);
end;

procedure TWorkOrderForm.PopulateCombos;
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

procedure TWorkOrderForm.LoadFromWorkOrder(AId: Integer);
var
  WO: TWorkOrder;
begin
  WO := FService.GetById(AId);
  try
    edtTitle.Text          := WO.Title;
    edtLocation.Text       := WO.Location;
    memDescription.Text    := WO.Description;
    cmbPriority.ItemIndex  := Ord(WO.Priority);
    cmbStatus.ItemIndex    := Ord(WO.Status);
  finally
    WO.Free;
  end;
end;

procedure TWorkOrderForm.SaveToWorkOrder;
var
  WO: TWorkOrder;
begin
  WO := TWorkOrder.Create;
  try
    WO.Id          := FEditingId;
    WO.Title       := edtTitle.Text;
    WO.Location    := edtLocation.Text;
    WO.Description := memDescription.Text;
    WO.Priority    := TWorkOrderPriority(cmbPriority.ItemIndex);

    if FEditingId < 0 then
      FService.CreateWorkOrder(WO)
    else
    begin
      WO.Status := TWorkOrderStatus(cmbStatus.ItemIndex);
      FService.UpdateWorkOrder(WO);
    end;
  finally
    WO.Free;
  end;
end;

procedure TWorkOrderForm.btnSaveClick(Sender: TObject);
begin
  try
    SaveToWorkOrder;
    ModalResult := mrOk;
  except
    on E: EWorkOrderValidation do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

end.
