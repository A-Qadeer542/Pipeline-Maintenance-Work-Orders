unit uTechnician;

interface

type
  TTechnician = class
  private
    FId: Integer;
    FFullName: string;
    FEmail: string;
    FPhone: string;
    FIsActive: Boolean;
  public
    constructor Create;

    property Id: Integer read FId write FId;
    property FullName: string read FFullName write FFullName;
    property Email: string read FEmail write FEmail;
    property Phone: string read FPhone write FPhone;
    property IsActive: Boolean read FIsActive write FIsActive;
  end;

implementation

constructor TTechnician.Create;
begin
  inherited;
  FIsActive := True;
end;

end.
