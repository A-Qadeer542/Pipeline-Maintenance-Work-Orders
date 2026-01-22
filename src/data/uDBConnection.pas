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
  LConn: TFDConnection;
  Ini: TIniFile;
  BasePath: string;
begin
  BasePath := ExtractFilePath(ParamStr(0));
  Ini := TIniFile.Create(BasePath + 'config\app.ini');
  LConn := TFDConnection.Create(nil);
  try
    LConn.LoginPrompt := False;
    LConn.Params.DriverID := 'MSSQL';
    LConn.Params.Database := Ini.ReadString('db', 'database', '');
    LConn.Params.UserName := Ini.ReadString('db', 'user', '');
    LConn.Params.Password := Ini.ReadString('db', 'password', '');
    LConn.Params.Add('Server=' + Ini.ReadString('db', 'server', ''));
    LConn.Params.Add('Trusted_Connection=Yes');
    LConn.Params.Add('Encrypt=No'); // Adjust to match security requirements
    LConn.Connected := True;
    Result := LConn;
  finally
    Ini.Free;
  end;
end;

end.
