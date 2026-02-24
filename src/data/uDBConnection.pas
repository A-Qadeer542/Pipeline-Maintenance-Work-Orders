unit uDBConnection;

interface

uses
  System.SysUtils,
  System.IniFiles,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef,
  FireDAC.DApt;

type
  TDBConnectionFactory = class
  private
    class function ResolveConfigPath: string;
    class procedure ApplyConnectionParams(AConn: TFDConnection; AIni: TIniFile);
  public
    class function CreateConnection: TFDConnection;
  end;

implementation

class function TDBConnectionFactory.ResolveConfigPath: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'config\app.ini';
  if not FileExists(Result) then
    raise Exception.CreateFmt('Configuration file not found: %s', [Result]);
end;

class procedure TDBConnectionFactory.ApplyConnectionParams(AConn: TFDConnection; AIni: TIniFile);
var
  User: string;
begin
  AConn.LoginPrompt := False;
  AConn.Params.DriverID := 'MSSQL';
  AConn.Params.Database := AIni.ReadString('db', 'database', 'PipelineMaintenance');
  AConn.Params.Add('Server=' + AIni.ReadString('db', 'server', '(localdb)\MSSQLLocalDB'));

  User := AIni.ReadString('db', 'user', '');
  if User <> '' then
  begin
    AConn.Params.UserName := User;
    AConn.Params.Password := AIni.ReadString('db', 'password', '');
  end
  else
    AConn.Params.Add('OsAuthent=Yes');

  AConn.Params.Add('Encrypt=No');
end;

class function TDBConnectionFactory.CreateConnection: TFDConnection;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ResolveConfigPath);
  try
    Result := TFDConnection.Create(nil);
    try
      ApplyConnectionParams(Result, Ini);
      Result.Connected := True;
    except
      Result.Free;
      raise;
    end;
  finally
    Ini.Free;
  end;
end;

end.
