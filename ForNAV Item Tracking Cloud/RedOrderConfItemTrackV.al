Report 56000 "Red Order Conf Item Track V"
{
    Caption = 'Order Item Tracking';
    UsageCategory = ReportsAndAnalysis;
    WordLayout = '.\Layouts\ForNAV Order Conf Item Track V.docx';
    DefaultLayout = Word;

    dataset
    {
        dataitem(Header; "Sales Header")
        {
            CalcFields = "Amount Including VAT", Amount;
            DataItemTableView = sorting("No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Posting Date";
            column(ReportForNavId_2; 2) { } // Autogenerated by ForNav - Do not delete
            column(ReportForNav_Header; ReportForNavWriteDataItem('Header', Header)) { }
            column(HasDiscount; ForNAVCheckDocumentDiscount.HasDiscount(Header))
            {
                IncludeCaption = false;
            }
            dataitem(Line; "Sales Line")
            {
                DataItemLinkReference = Header;
                DataItemLink = "Document No." = FIELD("No."), "Document Type" = FIELD("Document Type");
                DataItemTableView = sorting("Document No.", "Line No.");
                column(ReportForNavId_3; 3) { } // Autogenerated by ForNav - Do not delete
                column(ReportForNav_Line; ReportForNavWriteDataItem('Line', Line)) { }
                dataitem(TrackingSpecification; "Tracking Specification")
                {
                    UseTemporary = true;
                    column(ReportForNavId_1000000003; 1000000003) { } // Autogenerated by ForNav - Do not delete
                    column(ReportForNav_TrackingSpecification; ReportForNavWriteDataItem('TrackingSpecification', TrackingSpecification)) { }
                    dataitem(LotAttrValueMappingFDW; LotAttrValueMappingFDW)
                    {
                        DataItemLinkReference = TrackingSpecification;
                        DataItemLink = "Item No." = field("Item No."), "Lot No." = field("Lot No."), "Variant Code" = field("Variant Code");
                        column(ReportForNavId_1000000005; 1000000005) { } // Autogenerated by ForNav - Do not delete
                        column(ReportForNav_LotAttrValueMappingFDW; ReportForNavWriteDataItem('LotAttrValueMappingFDW', LotAttrValueMappingFDW)) { }
                        trigger OnPreDataItem();
                        begin
                            ReportForNav.OnPreDataItem('LotAttrValueMappingFDW', LotAttrValueMappingFDW);
                        end;

                    }
                    trigger OnPreDataItem();
                    begin
                        ReportForNav.OnPreDataItem('TrackingSpecification', TrackingSpecification);
                    end;

                }
                trigger OnPreDataItem();
                begin
                    ReportForNav.OnPreDataItem('Line', Line);
                end;

                trigger OnAfterGetRecord();
                begin
                    GetTrackingSpecification();
                end;

            }
            dataitem(VATAmountLine; "VAT Amount Line")
            {
                UseTemporary = true;
                DataItemTableView = sorting("VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", Positive);
                column(ReportForNavId_1000000001; 1000000001) { } // Autogenerated by ForNav - Do not delete
                column(ReportForNav_VATAmountLine; ReportForNavWriteDataItem('VATAmountLine', VATAmountLine)) { }
                trigger OnPreDataItem();
                begin
                    if not PrintVATAmountLines then
                        CurrReport.Break;
                    ReportForNav.OnPreDataItem('VATAmountLine', VATAmountLine);
                end;

            }
            dataitem(VATClause; "VAT Clause")
            {
                UseTemporary = true;
                DataItemTableView = sorting(Code);
                column(ReportForNavId_1000000002; 1000000002) { } // Autogenerated by ForNav - Do not delete
                column(ReportForNav_VATClause; ReportForNavWriteDataItem('VATClause', VATClause)) { }
                trigger OnPreDataItem();
                begin
                    ReportForNav.OnPreDataItem('VATClause', VATClause);
                end;

            }
            trigger OnPreDataItem();
            begin
                ReportForNav.OnPreDataItem('Header', Header);
            end;

            trigger OnAfterGetRecord();
            begin

                ChangeLanguage("Language Code");
                GetVatAmountLines;
                GetVATClauses;
                UpdateNoPrinted;
            end;

        }
    }


    requestpage
    {

        SaveValues = true;

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
                    }
                    field(ForNavOpenDesigner; ReportForNavOpenDesigner)
                    {
                        ApplicationArea = Basic;
                        Caption = 'Design';
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
        Codeunit.Run(Codeunit::"ForNAV First Time Setup");
    end;

    trigger OnPostReport()
    begin







    end;

    trigger OnPreReport()
    begin
        ;

        ReportForNav.SetCopies('Header', NoOfCopies);
        LoadWatermark;
        ;
        ReportsForNavPre;

    end;

    var
        ForNAVCheckDocumentDiscount: Codeunit "ForNAV Check Document Discount";
        NoOfCopies: Integer;

    local procedure ChangeLanguage(LanguageCode: Code[10])
    var
        ForNAVSetup: Record "ForNAV Setup";
    begin
        ForNAVSetup.Get;
        if ForNAVSetup."Inherit Language Code" then
            CurrReport.Language(ReportForNav.GetLanguageID(LanguageCode));
    end;

    local procedure GetVatAmountLines()
    var
        ForNAVGetVatAmountLines: Codeunit "ForNAV Get Vat Amount Lines";
    begin
        VATAmountLine.DeleteAll;
        ForNAVGetVatAmountLines.GetVatAmountLines(Header, VATAmountLine);
    end;

    local procedure GetVATClauses()
    var
        ForNAVGetVatClause: Codeunit "ForNAV Get Vat Clause";
    begin
        VATClause.DeleteAll;
        ForNAVGetVatClause.GetVATClauses(VATAmountLine, VATClause, Header."Language Code");
    end;

    local procedure PrintVATAmountLines(): Boolean
    var
        ForNAVSetup: Record "ForNAV Setup";
    begin
        ForNAVSetup.Get;
        case ForNAVSetup."VAT Report Type" of
            ForNAVSetup."vat report type"::Always:
                exit(true);
            ForNAVSetup."vat report type"::"Multiple Lines":
                exit(VATAmountLine.Count > 1);
            ForNAVSetup."vat report type"::Never:
                exit(false);
        end;
    end;

    local procedure UpdateNoPrinted()
    var
        ForNAVUpdateNoPrinted: Codeunit "ForNAV Update No. Printed";
    begin
        ForNAVUpdateNoPrinted.UpdateNoPrinted(Header, CurrReport.Preview);
    end;

    local procedure LoadWatermark()
    var
        ForNAVSetup: Record "ForNAV Setup";
        OutStream: OutStream;
    begin
        ForNAVSetup.Get;
        if not PrintLogo(ForNAVSetup) then
            exit;
        ForNAVSetup.CalcFields("Document Watermark");
        if not ForNAVSetup."Document Watermark".Hasvalue then
            exit;

        ReportForNav.LoadWatermarkImage(ForNAVSetup.GetDocumentWatermark);
    end;

    procedure PrintLogo(ForNAVSetup: Record "ForNAV Setup"): Boolean
    begin
        if not ForNAVSetup."Use Preprinted Paper" then
            exit(true);
        if 'Pdf' = 'PDF' then
            exit(true);
        if 'Pdf' = 'Preview' then
            exit(true);
        exit(false);
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
