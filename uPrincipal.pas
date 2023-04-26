unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Horse, Horse.Commons,  Horse.Core, web.WebBroker, System.IOUtils,
  System.NetEncoding, Web.HTTPApp, System.Net.Mime, Vcl.StdCtrls, Vcl.Buttons, System.Typinfo, System.JSON, Winapi.ShellAPI, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls;

type
  TfrmPrincipal = class(TForm)
    BitBtn1: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure StartServer;
    function StrExtFile_Base64Type(PFileName: String): String;
    { Private declarations }
  public
    { Public declarations }
    Port : integer;
  end;

type
  TSendFile_Image = (Tsf_Jpg=0, Tsf_Jpeg=1, Tsf_Tif=2, Tsf_Ico=3, Tsf_Bmp=4, Tsf_Png=5, Tsf_Raw=6, Tsf_webP=7);

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

procedure TfrmPrincipal.StartServer;
begin
  THorse.Get('/arquivo/:nomearquivo',
    procedure (req: THorseRequest; res: THorseResponse; next: TProc)
    var
      bytes: TBytes;
      filename: string;
      mimeType: string;
      base64: string;
    begin
      filename := TPath.Combine(ExtractFilePath(ParamStr(0)) + '\TWPPConnectAnexos', req.Params['nomearquivo']);
      if not TFile.Exists(filename) then
      begin
        res.Status(THTTPStatus.NotFound).Send('Arquivo não encontrado');
        Exit;
      end;

      try
        bytes := TFile.ReadAllBytes(filename);
      except
        on E: Exception do
        begin
          res.Status(THTTPStatus.InternalServerError).Send('Erro ao ler o arquivo: ' + E.Message);
          Exit;
        end;
      end;

      base64 := TNetEncoding.Base64.EncodeBytesToString(bytes);
      Res.ContentType('text/html');
      Res.RawWebResponse.Content := '' + StrExtFile_Base64Type(filename) + ''  + '' + Base64 + '';
      Res.Status(200);
    end);

 THorse.Post('/upload/:nomearquivo',
  procedure (req: THorseRequest; res: THorseResponse; next: TProc)
  var
    bytes: TBytes;
    filename: string;
    mimeType: string;
    base64: string;
    jsonObj: TJSONObject;
  begin

    base64 := '';
    jsonObj := TJSONObject.ParseJSONValue(req.Body) as TJSONObject;

    if Assigned(jsonObj) then
    begin
      base64 := jsonObj.GetValue('base64').Value;
    end;

    if base64 = '' then
    begin
      res.Status(THTTPStatus.BadRequest).Send('Corpo da requisição inválido');
      Exit;
    end;

    bytes := TNetEncoding.Base64.DecodeStringToBytes(base64); // decodificar a string base64 para bytes
    filename := TPath.Combine(ExtractFilePath(ParamStr(0)) + '\TWPPConnectAnexos', req.Params['nomearquivo']); // obter o valor do parâmetro da URL e concatenar com o caminho da pasta
    TFile.WriteAllBytes(filename, bytes); // escrever os bytes no arquivo
    res.Send('Arquivo salvo com sucesso'); // enviar resposta de sucesso
    Res.Status(200);
  end);

  if Port = 0 then
    Port := 8020;

  THorse.Port := Port;
  THorse.Listen;
end;

function TfrmPrincipal.StrExtFile_Base64Type(PFileName: String): String;
var
  I: Integer;
  LExt: String;
  Ltmp: String;
begin
  LExt   := LowerCase(Copy(ExtractFileExt(PFileName),2,50));

  if (LExt = 'mp3') then
    begin
      result := 'data:audio/mpeg;base64,';
      exit;
    end;

  if (LExt = 'ogg') then
    begin
      result := 'data:audio/ogg;base64,';
      exit;
    end;

  if (LExt = 'mp4') then
    begin
      result := 'data:video/mp4;base64,';
      exit;
    end;

  if (LExt = 'avi') then
    begin
      result := 'data:video/avi;base64,';
      exit;
    end;

  if (LExt = 'mpeg') then
    begin
      result := 'data:video/mpeg;base64,';
      exit;
    end;

  Result := 'data:application/';
  try
    for I := 0 to 10 do
    begin
      Ltmp := LowerCase(Copy(GetEnumName(TypeInfo(TSendFile_Image), ord(TSendFile_Image(i))), 3, 50));
      if pos(LExt, Ltmp) > 0 Then
      Begin
        Result := 'data:image/';
        Exit;
      end
    end;
  finally
     Result := Result + LExt + ';base64,' ;
  end;
end;

procedure TfrmPrincipal.BitBtn1Click(Sender: TObject);
begin
  ShellExecute(handle,'open',PChar('http://localhost:8020/arquivo/test.png'), '','',SW_SHOWNORMAL);
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  Port := 8020; //Criar Configuração da Porta padrão
  StartServer;
end;

end.
