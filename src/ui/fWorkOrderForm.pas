unit fWorkOrderForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Dialogs,
  uWorkOrder, uTechnician, uWorkOrderService;

type
  TWorkOrderForm = class(TForm)
    lblTitle: TLabel;
    lblLocation: TLabel;
    lblDescription: TLabel;
    lblPriority: TLabel;
    lblStatus: TLabel;
    lblTechnician: TLabel;
    edtTitle: TEdit;
    edtLocation: TEdit;
    memDescription: TMemo;
    cmbPriority: TComboBox;
    cmbStatus: TComboBox;
    cmbTechnician: TComboBox;
    btnSave: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FService: TWorkOrderService;
    FEditingId: Integer;
    procedure InitializeDropdowns;
    procedure LoadTechnicians;
    procedure SelectTechnicianById(ATechnicianId: Integer);
    procedure PopulateFieldsFromWorkOrder(AId: Integer);
    procedure PersistWorkOrder;
    function  IsEditMode: Boolean;
    function  GetSelectedTechnicianId: Integer;
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
    Dlg.LoadTechnicians;
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
    Dlg.LoadTechnicians;
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

procedure TWorkOrderForm.LoadTechnicians;
var
  Technicians: TObjectList<TTechnician>;
  i: Integer;
begin
  cmbTechnician.Items.Clear;
  cmbTechnician.Items.AddObject('(none)', TObject(0));

  Technicians := FService.FetchActiveTechnicians;
  try
    for i := 0 to Technicians.Count - 1 do
      cmbTechnician.Items.AddObject(Technicians[i].FullName,
        TObject(Technicians[i].Id));
  finally
    Technicians.Free;
  end;

  cmbTechnician.ItemIndex := 0;
end;

procedure TWorkOrderForm.SelectTechnicianById(ATechnicianId: Integer);
var
  i: Integer;
begin
  for i := 0 to cmbTechnician.Items.Count - 1 do
    if Integer(cmbTechnician.Items.Objects[i]) = ATechnicianId then
    begin
      cmbTechnician.ItemIndex := i;
      Exit;
    end;
  cmbTechnician.ItemIndex := 0;
end;

function TWorkOrderForm.GetSelectedTechnicianId: Integer;
begin
  if cmbTechnician.ItemIndex > 0 then
    Result := Integer(cmbTechnician.Items.Objects[cmbTechnician.ItemIndex])
  else
    Result := 0;
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
    SelectTechnicianById(WorkOrder.AssignedTechnicianId);
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
    WorkOrder.Id                   := FEditingId;
    WorkOrder.Title                := edtTitle.Text;
    WorkOrder.Location             := edtLocation.Text;
    WorkOrder.Description          := memDescription.Text;
    WorkOrder.Priority             := TWorkOrderPriority(cmbPriority.ItemIndex);
    WorkOrder.AssignedTechnicianId := GetSelectedTechnicianId;

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
