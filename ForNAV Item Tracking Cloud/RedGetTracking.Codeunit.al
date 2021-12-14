codeunit 56000 "Red Get Tracking"
{
    // Copyright (c) 2020 Red and Bundle - All Rights Reserved
    // The intellectual work and technical concepts contained in this file are proprietary to Red and Bundle.
    // Unauthorized reverse engineering, distribution or copying of this file, parts hereof, or derived work, via any medium is strictly prohibited without written permission from Red and Bundle.
    // This source code is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

    procedure GetTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; Rec: Variant)
    var
        RecRef: RecordRef;
    begin
        case true of
            Rec.IsRecord:
                RecRef.GetTable(Rec);
            rec.IsRecordRef:
                RecRef := Rec;
            else
                exit;
        end;

        case RecRef.Number of
            Database::"Sales Line",
            Database::"Purchase Line":
                begin
                    GetReservationEntries(TrackingSpecification, RecRef);
                    GetItemLedgerEntries(TrackingSpecification, RecRef);
                end;
            Database::"Sales Invoice Line",
            Database::"Purch. Inv. Line":
                GetFromInvoiceDocument(TrackingSpecification, RecRef);
            Database::"Sales Shipment Line",
            Database::"Purch. Rcpt. Line",
            Database::"Transfer Shipment Line",
            Database::"Transfer Receipt Line":
                GetItemLedgerEntries(TrackingSpecification, RecRef);
            Database::"Prod. Order Line":
                GetReservationEntries(TrackingSpecification, RecRef);
            Database::"Posted Whse. Receipt Line",
            Database::"Posted Whse. Shipment Line":
                GetFromWarehouseDocument(TrackingSpecification, RecRef);
        end;
    end;

    local procedure GetFromInvoiceDocument(var TrackingSpecification: Record "Tracking Specification"; RecRef: RecordRef)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        FldRef: FieldRef;
    begin
        ValueEntry.SetCurrentKey("Document No.");
        FldRef := RecRef.Field(3); // Document No
        ValueEntry.SetRange("Document No.", FldRef.Value);
        FldRef := RecRef.Field(4); // Line No
        ValueEntry.SetRange("Document Line No.", FldRef.Value);

        case RecRef.Number of
            Database::"Sales Invoice Line":
                ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
            Database::"Purch. Inv. Line":
                ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        end;

        if ValueEntry.FindSet() then
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
                    if ItemLedgerEntry.TrackingExists() then
                        InsertTrackingSpecFromItemLedgerEntry(TrackingSpecification, ItemLedgerEntry);
            until ValueEntry.Next() = 0;
    end;

    local procedure GetFromWarehouseDocument(var TrackingSpecification: Record "Tracking Specification"; RecRef: RecordRef)
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SourceDocRecRef: RecordRef;
    begin
        case RecRef.Number of
            Database::"Posted Whse. Receipt Line":
                begin
                    RecRef.SetTable(PostedWhseReceiptLine);
                    case PostedWhseReceiptLine."Posted Source Document" of
                        PostedWhseReceiptLine."Posted Source Document"::"Posted Receipt":
                            begin
                                PurchRcptLine.Get(PostedWhseReceiptLine."Posted Source No.", PostedWhseReceiptLine."Source Line No.");
                                SourceDocRecRef.GetTable(PurchRcptLine);
                            end;
                        PostedWhseReceiptLine."Posted Source Document"::"Posted Transfer Receipt":
                            begin
                                TransferReceiptLine.Get(PostedWhseReceiptLine."Posted Source No.", PostedWhseReceiptLine."Source Line No.");
                                SourceDocRecRef.GetTable(TransferReceiptLine);
                            end;
                    end;
                end;
            Database::"Posted Whse. Shipment Line":
                begin
                    RecRef.SetTable(PostedWhseShipmentLine);
                    case PostedWhseShipmentLine."Posted Source Document" of
                        PostedWhseShipmentLine."Posted Source Document"::"Posted Shipment":
                            begin
                                SalesShipmentLine.Get(PostedWhseShipmentLine."Posted Source No.", PostedWhseShipmentLine."Source Line No.");
                                SourceDocRecRef.GetTable(SalesShipmentLine);
                            end;
                        PostedWhseShipmentLine."Posted Source Document"::"Posted Transfer Shipment":
                            begin
                                TransferShipmentLine.Get(PostedWhseShipmentLine."Posted Source No.", PostedWhseShipmentLine."Source Line No.");
                                SourceDocRecRef.GetTable(TransferShipmentLine);
                            end;
                    end;
                end;
            else
                exit;
        end;
        GetTrackingSpecification(TrackingSpecification, SourceDocRecRef);
    end;

    local procedure GetReservationEntries(var TrackingSpecification: Record "Tracking Specification"; RecRef: RecordRef)
    var
        ReservationEntry: Record "Reservation Entry";
        FldRef: FieldRef;
    begin
        ReservationEntry.SetRange("Source Type", RecRef.Number);
        ReservationEntry.SetFilter("Item Tracking", '> %1', ReservationEntry."Item Tracking"::None);
        case RecRef.Number of
            Database::"Prod. Order Line":
                begin
                    FldRef := RecRef.Field(2); // Document No
                    ReservationEntry.SetRange("Source ID", FldRef.Value);
                    FldRef := RecRef.Field(3); // Line No
                    ReservationEntry.SetRange("Source Ref. No.", FldRef.Value);
                    FldRef := RecRef.Field(11); // Item No.
                    ReservationEntry.SetRange("Item No.", FldRef.Value);
                    FldRef := RecRef.Field(1); // Status
                    ReservationEntry.SetRange("Source Subtype", FldRef.Value);
                end;
            else
                FldRef := RecRef.Field(3); // Document No
                ReservationEntry.SetRange("Source ID", FldRef.Value);
                FldRef := RecRef.Field(4); // Line No
                ReservationEntry.SetRange("Source Prod. Order Line", FldRef.Value);
                FldRef := RecRef.Field(6); // No.
                ReservationEntry.SetRange("Item No.", FldRef.Value);
                FldRef := RecRef.Field(1); // Doc Type
                ReservationEntry.SetRange("Source Subtype", FldRef.Value);
        end;
        if ReservationEntry.FindSet() then
            repeat
                InsertTrackingSpecFromReservationEntry(TrackingSpecification, ReservationEntry);
            until ReservationEntry.Next() = 0;
    end;

    local procedure GetItemLedgerEntries(var TrackingSpecification: Record "Tracking Specification"; RecRef: RecordRef)
    var
        ShippingRef: RecordRef;
    begin
        if not GetShippingRef(ShippingRef, RecRef) then
            exit;
        GetItemLedgerEntriesFromShippingRef(TrackingSpecification, ShippingRef);
    end;

    local procedure GetShippingRef(var ShippingRef: RecordRef; RecRef: RecordRef): Boolean;
    var
        FldRef: FieldRef;
        ShippingFldRef: FieldRef;
    begin
        case RecRef.Number of
            Database::"Sales Line",
            Database::"Purchase Line":
                begin
                    case RecRef.Number of
                        Database::"Sales Line":
                            ShippingRef.Open(Database::"Sales Shipment Line");
                        Database::"Purchase Line":
                            ShippingRef.Open(Database::"Purch. Rcpt. Line");
                    end;
                    ShippingFldRef := ShippingRef.Field(65);
                    FldRef := RecRef.Field(3); // Document No
                    ShippingFldRef.SetRange(FldRef.Value);
                    ShippingFldRef := ShippingRef.Field(66);
                    FldRef := RecRef.Field(4); // Line No
                    ShippingFldRef.SetRange(FldRef.Value);
                end;
            Database::"Sales Shipment Line",
            Database::"Purch. Rcpt. Line",
            Database::"Transfer Shipment Line",
            Database::"Transfer Receipt Line":
                ShippingRef := RecRef;
            else
                exit(false);
        end;
        exit(not ShippingRef.IsEmpty());
    end;

    local procedure GetItemLedgerEntriesFromShippingRef(var TrackingSpecification: Record "Tracking Specification"; ShippingRef: RecordRef)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        FldRef: FieldRef;
    begin
        ShippingRef.SetRecFilter();
        if ShippingRef.FindSet() then
            repeat
                case ShippingRef.Number of
                    Database::"Sales Shipment Line",
                    Database::"Purch. Rcpt. Line":
                        begin
                            FldRef := ShippingRef.Field(3); // Document No
                            ItemLedgerEntry.SetRange("Document No.", FldRef.Value);
                            FldRef := ShippingRef.Field(4); // Line No
                            ItemLedgerEntry.SetRange("Document Line No.", FldRef.Value);
                            FldRef := ShippingRef.Field(6); // No
                            ItemLedgerEntry.SetRange("Item No.", FldRef.Value);
                        end;
                    Database::"Transfer Shipment Line",
                    Database::"Transfer Receipt Line":
                        begin
                            FldRef := ShippingRef.Field(1); // Document No
                            ItemLedgerEntry.SetRange("Document No.", FldRef.Value);
                            FldRef := ShippingRef.Field(2); // Line No
                            ItemLedgerEntry.SetRange("Document Line No.", FldRef.Value);
                            FldRef := ShippingRef.Field(3); // Item No
                            ItemLedgerEntry.SetRange("Item No.", FldRef.Value);
                        end;
                end;
                case ShippingRef.Number of
                    Database::"Sales Shipment Line":
                        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
                    Database::"Purch. Rcpt. Line":
                        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
                    Database::"Transfer Shipment Line":
                        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Transfer Shipment");
                    Database::"Transfer Receipt Line":
                        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Transfer Receipt");
                end;
                ItemLedgerEntry.SetFilter("Item Tracking", '>%1', ItemLedgerEntry."Item Tracking"::None);
                if ItemLedgerEntry.FindSet() then
                    repeat
                        InsertTrackingSpecFromItemLedgerEntry(TrackingSpecification, ItemLedgerEntry);
                    until ItemLedgerEntry.Next() = 0;
            until ShippingRef.Next() = 0;
    end;

    local procedure InsertTrackingSpecFromReservationEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
        TrackingSpecification.Init();
        TrackingSpecification."Entry No." += 1;
        TrackingSpecification."Item No." := ReservationEntry."Item No.";
        TrackingSpecification."Serial No." := ReservationEntry."Serial No.";
        TrackingSpecification."Lot No." := ReservationEntry."Lot No.";
        TrackingSpecification."Quantity (Base)" := Abs(ReservationEntry.Quantity);
        TrackingSpecification."Expiration Date" := ReservationEntry."Expiration Date";
        TrackingSpecification."Warranty Date" := ReservationEntry."Warranty Date";
        TrackingSpecification."Location Code" := ReservationEntry."Location Code";
        TrackingSpecification.Positive := ReservationEntry.Positive;
        TrackingSpecification."Qty. per Unit of Measure" := ReservationEntry."Qty. per Unit of Measure";
        TrackingSpecification."Variant Code" := ReservationEntry."Variant Code";
        TrackingSpecification.Correction := ReservationEntry.Correction;
        TrackingSpecification.Insert();
    end;

    local procedure InsertTrackingSpecFromItemLedgerEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TrackingSpecification.Init();
        TrackingSpecification."Entry No." := TrackingSpecification."Entry No." + 1;
        TrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
        TrackingSpecification."Serial No." := ItemLedgerEntry."Serial No.";
        TrackingSpecification."Lot No." := ItemLedgerEntry."Lot No.";
        TrackingSpecification."Quantity (Base)" := Abs(ItemLedgerEntry.Quantity);
        TrackingSpecification."Expiration Date" := ItemLedgerEntry."Expiration Date";
        TrackingSpecification."Warranty Date" := ItemLedgerEntry."Warranty Date";
        TrackingSpecification."Location Code" := ItemLedgerEntry."Location Code";
        TrackingSpecification.Positive := ItemLedgerEntry.Positive;
        TrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
        TrackingSpecification."Variant Code" := ItemLedgerEntry."Variant Code";
        TrackingSpecification.Correction := ItemLedgerEntry.Correction;
        TrackingSpecification.Insert();
    end;
}