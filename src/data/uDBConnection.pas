unit uDBConnection;

interface

uses
  System.SysUtils,
  System.IniFiles,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef,
  FireDAC.DApt;

type
  TDBConnectionFactory = class
  public
    class function CreateConnection: TFDConnection;
  end;

implementation

class function TDBConnectionFactory.CreateConnection: TFDConnection;
var
  Conn: TFDConnection;
  Ini: TIniFile;
  IniPath, User: string;
begin
  IniPath := ExtractFilePath(ParamStr(0)) + 'config\app.ini';

  if not FileExists(IniPath) then
    raise Exception.CreateFmt('Configuration file not found: %s', [IniPath]);

  Ini := TIniFile.Create(IniPath);
  Conn := TFDConnection.Create(nil);
  try
    Conn.LoginPrompt := False;
    Conn.Params.DriverID := 'MSSQL';
    Conn.Params.Database := Ini.ReadString('db', 'database', 'PipelineMaintenance');
    Conn.Params.Add('Server=' + Ini.ReadString('db', 'server', '(localdb)\MSSQLLocalDB'));

    User := Ini.ReadString('db', 'user', '');
    if User <> '' then
    begin
      Conn.Params.UserName := User;
      Conn.Params.Password := Ini.ReadString('db', 'password', '');
    end
    else
      Conn.Params.Add('OsAuthent=Yes');

    Conn.Params.Add('Encrypt=No');
    Conn.Connected := True;
    Result := Conn;
  finally
    Ini.Free;
  end;
end;

end.
