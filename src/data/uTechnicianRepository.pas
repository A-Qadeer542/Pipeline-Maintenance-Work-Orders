unit uTechnicianRepository;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  uTechnician;

type
  ITechnicianRepository = interface
    ['{7A1B2A0E-78E1-4FA6-8C4A-B0BC9B3D10A9}']
    function GetActive: TObjectList<TTechnician>;
    function GetById(AId: Integer): TTechnician;
  end;

  TTechnicianRepository = class(TInterfacedObject, ITechnicianRepository)
  private
    FConn: TFDConnection;
    function RowToTechnician(Q: TFDQuery): TTechnician;
  public
    constructor Create(AConn: TFDConnection);
    function GetActive: TObjectList<TTechnician>;
    function GetById(AId: Integer): TTechnician;
  end;

implementation

constructor TTechnicianRepository.Create(AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
end;

function TTechnicianRepository.RowToTechnician(Q: TFDQuery): TTechnician;
begin
  Result := TTechnician.Create;
  Result.Id       := Q.FieldByName('TechnicianId').AsInteger;
  Result.FullName := Q.FieldByName('FullName').AsString;
  Result.Email    := Q.FieldByName('Email').AsString;
  Result.Phone    := Q.FieldByName('Phone').AsString;
  Result.IsActive := Q.FieldByName('IsActive').AsBoolean;
end;

function TTechnicianRepository.GetActive: TObjectList<TTechnician>;
var
  Q: TFDQuery;
begin
  Result := TObjectList<TTechnician>.Create(True);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT TechnicianId, FullName, Email, Phone, IsActive ' +
      'FROM Technicians WHERE IsActive = 1 ORDER BY FullName';
    Q.Open;
    while not Q.Eof do
    begin
      Result.Add(RowToTechnician(Q));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TTechnicianRepository.GetById(AId: Integer): TTechnician;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT TechnicianId, FullName, Email, Phone, IsActive ' +
      'FROM Technicians WHERE TechnicianId = :pId';
    Q.ParamByName('pId').AsInteger := AId;
    Q.Open;
    if not Q.Eof then
      Result := RowToTechnician(Q);
  finally
    Q.Free;
  end;
end;

end.
