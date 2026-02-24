object MainForm: TMainForm
  Caption = 'Pipeline Maintenance  -  Work Orders'
  ClientHeight = 520
  ClientWidth = 780
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  Font.Name = 'Segoe UI'
  Font.Size = 9
  object lblStatus: TLabel
    Left = 16
    Top = 14
    Caption = 'Status:'
  end
  object lblPriority: TLabel
    Left = 210
    Top = 14
    Caption = 'Priority:'
  end
  object cmbStatus: TComboBox
    Left = 16
    Top = 34
    Width = 170
    Style = csDropDownList
    TabOrder = 0
  end
  object cmbPriority: TComboBox
    Left = 210
    Top = 34
    Width = 170
    Style = csDropDownList
    TabOrder = 1
  end
  object btnFilter: TButton
    Left = 400
    Top = 32
    Width = 80
    Height = 25
    Caption = 'Apply Filter'
    TabOrder = 2
    OnClick = btnFilterClick
  end
  object btnCreate: TButton
    Left = 504
    Top = 32
    Width = 110
    Height = 25
    Caption = 'New Work Order'
    TabOrder = 3
    OnClick = btnCreateClick
  end
  object btnEdit: TButton
    Left = 624
    Top = 32
    Width = 65
    Height = 25
    Caption = 'Edit'
    TabOrder = 4
    OnClick = btnEditClick
  end
  object btnAdvance: TButton
    Left = 698
    Top = 32
    Width = 65
    Height = 25
    Caption = 'Advance'
    TabOrder = 5
    OnClick = btnAdvanceClick
  end
  object grdOrders: TStringGrid
    Left = 16
    Top = 72
    Width = 748
    Height = 432
    ColCount = 6
    FixedCols = 0
    RowCount = 2
    FixedRows = 1
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
    TabOrder = 6
    OnDblClick = grdOrdersDblClick
  end
end
