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
    function FetchActiveTechnicians: TObjectList<TTechnician>;
    function FetchTechnicianById(AId: Integer): TTechnician;
  end;

  TTechnicianRepository = class(TInterfacedObject, ITechnicianRepository)
  private
    FConn: TFDConnection;
    function CreateQuery: TFDQuery;
    function MapRowToEntity(AQuery: TFDQuery): TTechnician;
  public
    constructor Create(AConnection: TFDConnection);
    function FetchActiveTechnicians: TObjectList<TTechnician>;
    function FetchTechnicianById(AId: Integer): TTechnician;
  end;

implementation

constructor TTechnicianRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  FConn := AConnection;
end;

function TTechnicianRepository.CreateQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConn;
end;

function TTechnicianRepository.MapRowToEntity(AQuery: TFDQuery): TTechnician;
begin
  Result := TTechnician.Create;
  Result.Id       := AQuery.FieldByName('TechnicianId').AsInteger;
  Result.FullName := AQuery.FieldByName('FullName').AsString;
  Result.Email    := AQuery.FieldByName('Email').AsString;
  Result.Phone    := AQuery.FieldByName('Phone').AsString;
  Result.IsActive := AQuery.FieldByName('IsActive').AsBoolean;
end;

function TTechnicianRepository.FetchActiveTechnicians: TObjectList<TTechnician>;
var
  Query: TFDQuery;
begin
  Result := TObjectList<TTechnician>.Create(True);
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT TechnicianId, FullName, Email, Phone, IsActive ' +
      'FROM Technicians WHERE IsActive = 1 ORDER BY FullName';
    Query.Open;
    while not Query.Eof do
    begin
      Result.Add(MapRowToEntity(Query));
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TTechnicianRepository.FetchTechnicianById(AId: Integer): TTechnician;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := CreateQuery;
  try
    Query.SQL.Text :=
      'SELECT TechnicianId, FullName, Email, Phone, IsActive ' +
      'FROM Technicians WHERE TechnicianId = :pId';
    Query.ParamByName('pId').AsInteger := AId;
    Query.Open;
    if not Query.Eof then
      Result := MapRowToEntity(Query);
  finally
    Query.Free;
  end;
end;

end.
