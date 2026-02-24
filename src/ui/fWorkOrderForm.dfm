object WorkOrderForm: TWorkOrderForm
  Caption = 'Work Order'
  ClientHeight = 380
  ClientWidth = 520
  Position = poMainFormCenter
  OnCreate = FormCreate
  Font.Name = 'Segoe UI'
  Font.Size = 9
  object lblTitle: TLabel
    Left = 16
    Top = 18
    Caption = 'Title:'
  end
  object lblLocation: TLabel
    Left = 16
    Top = 60
    Caption = 'Location:'
  end
  object lblDescription: TLabel
    Left = 16
    Top = 102
    Caption = 'Description:'
  end
  object lblPriority: TLabel
    Left = 16
    Top = 258
    Caption = 'Priority:'
  end
  object lblStatus: TLabel
    Left = 272
    Top = 258
    Caption = 'Status:'
  end
  object edtTitle: TEdit
    Left = 96
    Top = 14
    Width = 400
    TabOrder = 0
  end
  object edtLocation: TEdit
    Left = 96
    Top = 56
    Width = 400
    TabOrder = 1
  end
  object memDescription: TMemo
    Left = 96
    Top = 98
    Width = 400
    Height = 140
    TabOrder = 2
    ScrollBars = ssVertical
  end
  object cmbPriority: TComboBox
    Left = 96
    Top = 254
    Width = 145
    Style = csDropDownList
    TabOrder = 3
  end
  object cmbStatus: TComboBox
    Left = 330
    Top = 254
    Width = 166
    Style = csDropDownList
    TabOrder = 4
  end
  object btnSave: TButton
    Left = 330
    Top = 320
    Width = 80
    Height = 28
    Caption = 'Save'
    Default = True
    TabOrder = 5
    OnClick = btnSaveClick
  end
  object btnCancel: TButton
    Left = 416
    Top = 320
    Width = 80
    Height = 28
    Caption = 'Cancel'
    Cancel = True
    ModalResult = 2
    TabOrder = 6
  end
end
