Report 56011 "Red Picking List Track"
{
    Caption = 'Picking List Item Tracking';
    UsageCategory = ReportsAndAnalysis;
    WordLayout = '.\Layouts\Red Picking List Track.docx';
    DefaultLayout = Word;

    dataset
    {
        dataitem(Header; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = CONST(Order));
            RequestFilterFields = "No.";
            column(ReportForNavId_2; 2) { } // Autogenerated by ForNav - Do not delete
            column(ReportForNav_Header; ReportForNavWriteDataItem('Header', Header)) { }
            dataitem(Line; "Sales Line")
            {
                DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where(Type = CONST(2));
                column(ReportForNavId_3; 3) { } // Autogenerated by ForNav - Do not delete
                column(ReportForNav_Line; ReportForNavWriteDataItem('Line', Line)) { }
                dataitem(TrackingSpecification; "Tracking Specification")
                {
                    UseTemporary = true;
                    column(ReportForNavId_4; 4) { } // Autogenerated by ForNav - Do not delete
                    column(ReportForNav_TrackingSpecification; ReportForNavWriteDataItem('TrackingSpecification', TrackingSpecification)) { }
                    dataitem(LotAttrValueMappingFDW; Integer)
                    {
                        column(ReportForNavId_6; 6) { } // Autogenerated by ForNav - Do not delete
                        column(ReportForNav_LotAttrValueMappingFDW; ReportForNavWriteDataItem('LotAttrValueMappingFDW', LotAttrValueMappingFDW)) { }
                        column(LotAttributeValue; LotAttributeValue)
                        {
                            IncludeCaption = false;
                        }
                        column(LotAttributeName; LotAttributeName)
                        {
                            IncludeCaption = false;
                        }
                        trigger OnPreDataItem();
                        begin
                            if TempLotAttrValueMappingFDW.IsEmpty() then
                                LotAttrValueMappingFDW.SetRange(Number, 0)
                            else
                                LotAttrValueMappingFDW.SetRange(Number, 1, TempLotAttrValueMappingFDW.Count);
                            ReportForNav.OnPreDataItem('LotAttrValueMappingFDW', LotAttrValueMappingFDW);
                        end;

                        trigger OnAfterGetRecord();
                        begin
                            GetLotAttribute();
                        end;

                    }
                    trigger OnPreDataItem();
                    begin
                        ReportForNav.OnPreDataItem('TrackingSpecification', TrackingSpecification);
                    end;

                    trigger OnAfterGetRecord();
                    begin
                        GetLotAttrValueMappingFDW();
                    end;

                }
                trigger OnPreDataItem();
                begin
                    GetTrackingSpecification();
                    ReportForNav.OnPreDataItem('Line', Line);
                end;

            }
            trigger OnPreDataItem();
            begin
                ReportForNav.OnPreDataItem('Header', Header);
            end;

            trigger OnAfterGetRecord();
            begin
                ChangeLanguage("Language Code");
            end;

        }
    }

    requestpage
    {

        SaveValues = false;
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies the number of copies.';
                    }
                    field(ForNavOpenDesigner; ReportForNavOpenDesigner)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Design';
                        ToolTip = 'Opens the report in the ForNAV designer.';
                        Visible = ReportForNavAllowDesign;
                        trigger OnValidate()
                        begin
                            ReportForNav.LaunchDesigner(ReportForNavOpenDesigner);
                            CurrReport.RequestOptionsPage.Close();
                        end;

                    }
                }
            }
        }

        actions
        {
        }
        trigger OnOpenPage()
        begin
            ReportForNavOpenDesigner := false;
        end;
    }

    trigger OnInitReport()
    begin
        ;
        ReportsForNavInit;

    end;

    trigger OnPostReport()
    begin







    end;

    trigger OnPreReport()
    begin
        ;
        ReportsForNavPre;
        ReportForNav.SetCopies('Header', NoOfCopies);
    end;

    var
        TempLotAttrValueMappingFDW: Record LotAttrValueMappingFDW temporary;
        NoOfCopies: Integer;
        LotAttributeValue: Text;
        LotAttributeName: Text;

    local procedure ChangeLanguage(LanguageCode: Code[10])
    var
        ForNAVSetup: Record "ForNAV Setup";
    begin
        ForNAVSetup.Get();
        if ForNAVSetup."Inherit Language Code" then
            CurrReport.Language(ReportForNav.GetLanguageID(LanguageCode));
    end;

    local procedure GetTrackingSpecification()
    var
        RedGetTracking: Codeunit "Red Get Tracking";
        RecRef: RecordRef;
    begin
        TrackingSpecification.DeleteAll();
        if Line.Type <> Line.Type::Item then
            exit;

        RecRef.GetTable(Line);
        RedGetTracking.GetTrackingSpecification(TrackingSpecification, RecRef);
    end;

    local procedure GetLotAttrValueMappingFDW()
    var
        RedGetTracking: Codeunit "Red Get Tracking";
    begin
        TempLotAttrValueMappingFDW.DeleteAll();

        RedGetTracking.GetLotAttrValueMappingFDW(TrackingSpecification, TempLotAttrValueMappingFDW);
    end;

    local procedure GetLotAttribute()
    var
        LotAttributeValueFDW: Record LotAttributeValueFDW;
    begin
        if LotAttrValueMappingFDW.Number = 1 then
            TempLotAttrValueMappingFDW.FindFirst()
        else
            TempLotAttrValueMappingFDW.Next();

        LotAttributeValue := '';
        if LotAttributeValueFDW.Get(TempLotAttrValueMappingFDW."Lot Attribute ID", TempLotAttrValueMappingFDW."Lot Attribute Value ID") then begin
            LotAttributeValueFDW.CalcFields("Attribute Name");
            LotAttributeValue := LotAttributeValueFDW.Value;
            LotAttributeName := LotAttributeValueFDW."Attribute Name";
        end;
    end;

    // --> Reports ForNAV Autogenerated code - do not delete or modify
    var
        ReportForNavInitialized: Boolean;
        ReportForNavShowOutput: Boolean;
        ReportForNavTotalsCausedBy: Integer;
        ReportForNavOpenDesigner: Boolean;
        [InDataSet]
        ReportForNavAllowDesign: Boolean;
        ReportForNav: Codeunit "ForNAV Report Management";

    local procedure ReportsForNavInit()
    var
        id: Integer;
    begin
        Evaluate(id, CopyStr(CurrReport.ObjectId(false), StrPos(CurrReport.ObjectId(false), ' ') + 1));
        ReportForNav.OnInit(id, ReportForNavAllowDesign);
    end;

    local procedure ReportsForNavPre()
    begin
        if ReportForNav.LaunchDesigner(ReportForNavOpenDesigner) then CurrReport.Quit();
    end;

    local procedure ReportForNavSetTotalsCausedBy(value: Integer)
    begin
        ReportForNavTotalsCausedBy := value;
    end;

    local procedure ReportForNavSetShowOutput(value: Boolean)
    begin
        ReportForNavShowOutput := value;
    end;

    local procedure ReportForNavInit(jsonObject: JsonObject)
    begin
        ReportForNav.Init(jsonObject, CurrReport.ObjectId);
    end;

    local procedure ReportForNavWriteDataItem(dataItemId: Text; rec: Variant): Text
    var
        values: Text;
        jsonObject: JsonObject;
        currLanguage: Integer;
    begin
        if not ReportForNavInitialized then begin
            ReportForNavInit(jsonObject);
            ReportForNavInitialized := true;
        end;

        case (dataItemId) of
            'Header':
                begin
                    jsonObject.Add('CurrReport$Language$Integer', CurrReport.Language);
                end;
            'TrackingSpecification':
                begin
                    currLanguage := GlobalLanguage;
                    GlobalLanguage := 1033;
                    jsonObject.Add('DataItem$TrackingSpecification$CurrentKey$Text', TrackingSpecification.CurrentKey);
                    GlobalLanguage := currLanguage;
                end;
            'LotAttrValueMappingFDW':
                begin
                    currLanguage := GlobalLanguage;
                    GlobalLanguage := 1033;
                    jsonObject.Add('DataItem$LotAttrValueMappingFDW$CurrentKey$Text', LotAttrValueMappingFDW.CurrentKey);
                    GlobalLanguage := currLanguage;
                end;
        end;
        ReportForNav.AddDataItemValues(jsonObject, dataItemId, rec);
        jsonObject.WriteTo(values);
        exit(values);
    end;
    // Reports ForNAV Autogenerated code - do not delete or modify -->
}
