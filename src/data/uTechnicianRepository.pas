unit uTechnicianRepository;

interface

uses
  System.Generics.Collections,
  FireDAC.Comp.Client,
  uTechnician;

type
  ITechnicianRepository = interface
    ['{7A1B2A0E-78E1-4FA6-8C4A-B0BC9B3D10A9}']
    function GetActive: TObjectList<TTechnician>;
    function GetById(const AId: Integer): TTechnician;
  end;

  TTechnicianRepository = class(TInterfacedObject, ITechnicianRepository)
  private
    FConn: TFDConnection;
    function MapQueryToTechnician(AQuery: TFDQuery): TTechnician;
  public
    constructor Create(AConn: TFDConnection);
    function GetActive: TObjectList<TTechnician>;
    function GetById(const AId: Integer): TTechnician;
  end;

implementation

{ TTechnicianRepository }

constructor TTechnicianRepository.Create(AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
end;

function TTechnicianRepository.GetActive: TObjectList<TTechnician>;
var
  Q: TFDQuery;
begin
  Result := TObjectList<TTechnician>.Create(True);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'SELECT TechnicianId, Name, Email, Phone, IsActive FROM Technicians WHERE IsActive = 1';
    Q.Open;
    while not Q.Eof do
    begin
      Result.Add(MapQueryToTechnician(Q));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TTechnicianRepository.GetById(const AId: Integer): TTechnician;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'SELECT TechnicianId, Name, Email, Phone, IsActive FROM Technicians WHERE TechnicianId = :Id';
    Q.ParamByName('Id').AsInteger := AId;
    Q.Open;
    if not Q.Eof then
      Result := MapQueryToTechnician(Q);
  finally
    Q.Free;
  end;
end;

function TTechnicianRepository.MapQueryToTechnician(AQuery: TFDQuery): TTechnician;
begin
  Result := TTechnician.Create;
  Result.Id := AQuery.FieldByName('TechnicianId').AsInteger;
  Result.Name := AQuery.FieldByName('Name').AsString;
  Result.Email := AQuery.FieldByName('Email').AsString;
  Result.Phone := AQuery.FieldByName('Phone').AsString;
  Result.IsActive := AQuery.FieldByName('IsActive').AsBoolean;
end;

end.
