unit fMain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Grids, Vcl.Dialogs,
  FireDAC.Comp.Client,
  uWorkOrder, uWorkOrderService, uWorkOrderRepository, uDBConnection;

type
  TMainForm = class(TForm)
    lblStatus: TLabel;
    lblPriority: TLabel;
    cmbStatus: TComboBox;
    cmbPriority: TComboBox;
    btnFilter: TButton;
    btnCreate: TButton;
    btnEdit: TButton;
    btnAdvance: TButton;
    grdOrders: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnFilterClick(Sender: TObject);
    procedure btnCreateClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnAdvanceClick(Sender: TObject);
    procedure grdOrdersDblClick(Sender: TObject);
  private
    FConn: TFDConnection;
    FRepo: IWorkOrderRepository;
    FService: TWorkOrderService;
    procedure InitializeGridColumns;
    procedure InitializeFilterDropdowns;
    procedure ReloadWorkOrderGrid;
    function  BuildFilterFromUI: TWorkOrderFilter;
    function  GetSelectedWorkOrderId: Integer;
    procedure OpenEditDialog(AWorkOrderId: Integer);
    procedure ShowValidationMessage(const AMessage: string);
  end;

var
  MainForm: TMainForm;

implementation

uses
  fWorkOrderForm;

{$R *.dfm}

{ --- lifecycle --- }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  try
    FConn := TDBConnectionFactory.CreateConnection;
  except
    on E: Exception do
    begin
      MessageDlg('Could not connect to the database.' + sLineBreak +
                 E.Message, mtError, [mbOK], 0);
      Application.Terminate;
      Exit;
    end;
  end;

  FRepo    := TWorkOrderRepository.Create(FConn);
  FService := TWorkOrderService.Create(FRepo);

  InitializeFilterDropdowns;
  InitializeGridColumns;
  ReloadWorkOrderGrid;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FService);
  FreeAndNil(FConn);
end;

{ --- UI initialisation --- }

procedure TMainForm.InitializeFilterDropdowns;
var
  S: TWorkOrderStatus;
  P: TWorkOrderPriority;
begin
  cmbStatus.Items.Clear;
  cmbStatus.Items.Add('(any)');
  for S := Low(TWorkOrderStatus) to High(TWorkOrderStatus) do
    cmbStatus.Items.Add(WorkOrderStatusLabels[S]);
  cmbStatus.ItemIndex := 0;

  cmbPriority.Items.Clear;
  cmbPriority.Items.Add('(any)');
  for P := Low(TWorkOrderPriority) to High(TWorkOrderPriority) do
    cmbPriority.Items.Add(WorkOrderPriorityLabels[P]);
  cmbPriority.ItemIndex := 0;
end;

procedure TMainForm.InitializeGridColumns;
begin
  grdOrders.FixedRows := 1;
  grdOrders.FixedCols := 0;
  grdOrders.ColCount  := 6;
  grdOrders.RowCount  := 2;
  grdOrders.Options   := grdOrders.Options + [goRowSelect];

  grdOrders.Cells[0, 0] := '#';
  grdOrders.Cells[1, 0] := 'Title';
  grdOrders.Cells[2, 0] := 'Location';
  grdOrders.Cells[3, 0] := 'Priority';
  grdOrders.Cells[4, 0] := 'Status';
  grdOrders.Cells[5, 0] := 'Assigned To';

  grdOrders.ColWidths[0] := 40;
  grdOrders.ColWidths[1] := 200;
  grdOrders.ColWidths[2] := 150;
  grdOrders.ColWidths[3] := 70;
  grdOrders.ColWidths[4] := 90;
  grdOrders.ColWidths[5] := 120;
end;

{ --- data loading --- }

function TMainForm.BuildFilterFromUI: TWorkOrderFilter;
begin
  Result := TWorkOrderFilter.None;

  if cmbStatus.ItemIndex > 0 then
  begin
    Result.Status          := TWorkOrderStatus(cmbStatus.ItemIndex - 1);
    Result.HasStatusFilter := True;
  end;

  if cmbPriority.ItemIndex > 0 then
  begin
    Result.Priority          := TWorkOrderPriority(cmbPriority.ItemIndex - 1);
    Result.HasPriorityFilter := True;
  end;
end;

procedure TMainForm.ReloadWorkOrderGrid;
var
  WorkOrders: TObjectList<TWorkOrder>;
  i: Integer;
begin
  WorkOrders := FService.FetchWorkOrders(BuildFilterFromUI);
  try
    if WorkOrders.Count = 0 then
    begin
      grdOrders.RowCount := 2;
      grdOrders.Rows[1].Clear;
    end
    else
      grdOrders.RowCount := WorkOrders.Count + 1;

    for i := 0 to WorkOrders.Count - 1 do
    begin
      grdOrders.Cells[0, i + 1] := IntToStr(WorkOrders[i].Id);
      grdOrders.Cells[1, i + 1] := WorkOrders[i].Title;
      grdOrders.Cells[2, i + 1] := WorkOrders[i].Location;
      grdOrders.Cells[3, i + 1] := WorkOrders[i].PriorityLabel;
      grdOrders.Cells[4, i + 1] := WorkOrders[i].StatusLabel;
      grdOrders.Cells[5, i + 1] := WorkOrders[i].AssignedTechnicianName;
    end;
  finally
    WorkOrders.Free;
  end;
end;

function TMainForm.GetSelectedWorkOrderId: Integer;
begin
  if grdOrders.Row < 1 then
    Exit(-1);
  Result := StrToIntDef(grdOrders.Cells[0, grdOrders.Row], -1);
end;

{ --- shared helpers --- }

procedure TMainForm.OpenEditDialog(AWorkOrderId: Integer);
begin
  if TWorkOrderForm.ShowEditDialog(FService, AWorkOrderId) then
    ReloadWorkOrderGrid;
end;

procedure TMainForm.ShowValidationMessage(const AMessage: string);
begin
  MessageDlg(AMessage, mtWarning, [mbOK], 0);
end;

{ --- event handlers --- }

procedure TMainForm.btnFilterClick(Sender: TObject);
begin
  ReloadWorkOrderGrid;
end;

procedure TMainForm.btnCreateClick(Sender: TObject);
begin
  if TWorkOrderForm.ShowCreateDialog(FService) then
    ReloadWorkOrderGrid;
end;

procedure TMainForm.btnEditClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := GetSelectedWorkOrderId;
  if Id < 1 then
  begin
    ShowValidationMessage('Select a work order first.');
    Exit;
  end;
  OpenEditDialog(Id);
end;

procedure TMainForm.btnAdvanceClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := GetSelectedWorkOrderId;
  if Id < 1 then
  begin
    ShowValidationMessage('Select a work order first.');
    Exit;
  end;
  try
    FService.AdvanceWorkOrderStatus(Id);
    ReloadWorkOrderGrid;
  except
    on E: EWorkOrderValidation do
      ShowValidationMessage(E.Message);
  end;
end;

procedure TMainForm.grdOrdersDblClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := GetSelectedWorkOrderId;
  if Id > 0 then
    OpenEditDialog(Id);
end;

end.
