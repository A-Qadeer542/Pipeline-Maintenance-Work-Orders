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
    procedure SetupGrid;
    procedure PopulateFilters;
    procedure RefreshGrid;
    function  SelectedId: Integer;
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

  PopulateFilters;
  SetupGrid;
  RefreshGrid;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FService);
  FreeAndNil(FConn);
end;

{ --- helpers --- }

procedure TMainForm.PopulateFilters;
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

procedure TMainForm.SetupGrid;
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

procedure TMainForm.RefreshGrid;
var
  List: TObjectList<TWorkOrder>;
  FilterStatus: Boolean;
  FilterPriority: Boolean;
  S: TWorkOrderStatus;
  P: TWorkOrderPriority;
  i: Integer;
begin
  FilterStatus   := cmbStatus.ItemIndex > 0;
  FilterPriority := cmbPriority.ItemIndex > 0;

  if FilterStatus then
    S := TWorkOrderStatus(cmbStatus.ItemIndex - 1)
  else
    S := woNew;

  if FilterPriority then
    P := TWorkOrderPriority(cmbPriority.ItemIndex - 1)
  else
    P := woLow;

  List := FService.List(S, P, FilterStatus, FilterPriority);
  try
    if List.Count = 0 then
    begin
      grdOrders.RowCount := 2;
      grdOrders.Rows[1].Clear;
    end
    else
      grdOrders.RowCount := List.Count + 1;

    for i := 0 to List.Count - 1 do
    begin
      grdOrders.Cells[0, i + 1] := IntToStr(List[i].Id);
      grdOrders.Cells[1, i + 1] := List[i].Title;
      grdOrders.Cells[2, i + 1] := List[i].Location;
      grdOrders.Cells[3, i + 1] := List[i].PriorityLabel;
      grdOrders.Cells[4, i + 1] := List[i].StatusLabel;
      grdOrders.Cells[5, i + 1] := List[i].AssignedTechnicianName;
    end;
  finally
    List.Free;
  end;
end;

function TMainForm.SelectedId: Integer;
begin
  if grdOrders.Row < 1 then
    Exit(-1);
  Result := StrToIntDef(grdOrders.Cells[0, grdOrders.Row], -1);
end;

{ --- event handlers --- }

procedure TMainForm.btnFilterClick(Sender: TObject);
begin
  RefreshGrid;
end;

procedure TMainForm.btnCreateClick(Sender: TObject);
begin
  if TWorkOrderForm.ExecuteNew(FService) then
    RefreshGrid;
end;

procedure TMainForm.btnEditClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := SelectedId;
  if Id < 1 then
  begin
    MessageDlg('Select a work order first.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if TWorkOrderForm.ExecuteEdit(FService, Id) then
    RefreshGrid;
end;

procedure TMainForm.btnAdvanceClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := SelectedId;
  if Id < 1 then
  begin
    MessageDlg('Select a work order first.', mtInformation, [mbOK], 0);
    Exit;
  end;
  try
    FService.AdvanceStatus(Id);
    RefreshGrid;
  except
    on E: EWorkOrderValidation do
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure TMainForm.grdOrdersDblClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

end.
