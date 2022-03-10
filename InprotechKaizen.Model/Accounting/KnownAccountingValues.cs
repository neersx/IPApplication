namespace InprotechKaizen.Model.Accounting
{
    public enum ItemType
    {
        Unknown = 0,
        CreditJournal = 522,
        CreditNote = 511,
        DebitJournal = 521,
        DebitNote = 510,
        InternalCreditNote = 514,
        InternalDebitNote = 513,
        Prepayment = 523,
        UnallocatedCash = 520
    }

    public enum TransactionType : short
    {
        OpeningBalance = 0,
        Timesheet = 400,
        WipRecording = 402,
        ExternalDisbursement = 404,
        GeneratedWip = 406,
        ExternalWip = 408,
        Disbursement = 410,
        DebitWorkInProgress = 500,
        CreditWorkInProgress = 501,
        Bill = 510,
        CreditFullBill = 511,
        BillReversal = 512,
        CreditFullBillReversal = 513,
        GeneratedBill = 514,
        CreditNoteReversal = 515,
        CreditNote = 516,
        InternalBill = 517,
        InternalBillReversal = 518,
        InternalCreditNote = 519,
        Remittance = 520,
        RemittanceReversal = 521,
        DebitJournal = 522,
        DebitJournalReversal = 523,
        CreditJournal = 524,
        CreditJournalReversal = 525,
        CreditAllocation = 526,
        CreditAllocationReversal = 527,
        DebtorsWriteOff = 528,
        DebtorsWriteOffReversal = 529,
        Prepayment = 530,
        PrepaymentReversal = 531,
        InternalCreditNoteReversal = 532,
        DebtorsTransfer = 533,
        DebtorsTransferReversal = 534,
        Receipt = 560,
        ReceiptReversal = 561,
        Deposit = 562,
        DepositReversal = 563,
        ManualBankEntry = 564,
        ManualBankEntryReversal = 565,
        DishonourReceipt = 566,
        DishonourReceiptReversal = 567,
        BankTransfer = 568,
        BankTransferReversal = 569,
        FeesListEntry = 570,
        FeesListEntryReversal = 571,
        InterEntityTransfer = 600,
        Purchase = 700,
        PurchaseReversal = 701,
        ManualPayment = 702,
        ManualPaymentReversal = 703,
        AutomaticPayment = 704,
        AutomaticPaymentReversal = 705,
        CreditNoteReceived = 706,
        CreditNoteReceivedReversal = 707,
        CreditAllocationAP = 708,
        CreditAllocationReversalAP = 709,
        ARAPOffset = 710,
        ARAPOffsetReversal = 711,
        CreditCardPayment = 712,
        CreditCardPaymentReversal = 713,
        ClientPayment = 714,
        ClientPaymentReversal = 715,
        ManualJournalEntry = 810,
        ManualJournalEntryReversal = 811,
        PLAccountClearing = 812,
        TrustReceipt = 900,
        TrustReceiptReversal = 901,
        TrustReleasedtoFirm = 902,
        TrustReleasedtoFirmReversal = 903,
        TrustPayment = 904,
        TrustPaymentReversal = 905,
        TrustTransfer = 906,
        TrustTransferReversal = 907,
        DebitWipAdjustment = 1000,
        CreditWipAdjustment = 1001,
        StaffWipTransfer = 1002,
        CaseWipTransfer = 1003,
        DebtorWipTransfer = 1004,
        QuotationWipTransfer = 1005,
        WipWriteDown = 1006,
        ProductWipTransfer = 1007,
        WipSplit = 1008,
        WipRecalculation = 1009,
        ActivityWipTransfer = 1010,
        CreditWipAllocation = 1020,
        CreditWipRounding = 1021,
        ClosingBalance = 9999
    }

    public static class WipCategory
    {
        public const string ServiceCharge = "SC";
        public const string Disbursements = "PD";
        public const string Recoverables = "OR";
    }

    /// <summary>
    /// Indicates to the accounting modules what the current status of a transaction is.
    /// This determines how the transaction may be further processed, or whether it is included in various reports or enquiries.
    /// </summary>
    public enum TransactionStatus : short
    {
        /// <summary>
        /// Transaction is still in draft mode
        /// </summary>
        Draft = 0,

        /// <summary>
        /// Finalised or Posted
        /// </summary>
        Active = 1,

        /// <summary>
        /// Locked on another Draft transaction
        /// </summary>
        Locked = 2,

        /// <summary>
        /// Has been reversed by another transaction
        /// </summary>
        Reversed = 9
    }

    public enum MovementClass : short
    {
        Entered = 1,
        Billed = 2,
        AdjustUp = 4,
        AdjustDown = 5
    }

    public enum CommandId : short
    {
        Generate = 1,
        NewConsume = 2,
        Consume = 3,
        Dispose = 4,
        AdjustUp = 5,
        AdjustDown = 6,
        Equalise = 7,
        GenerateBalance = 8,
        NewAdjustUp = 9,
        NewAdjustDown = 10,
        InverseBalance = 11, /* Dishonour Receipt */
        Reverse = 99
    }

    public enum ItemImpact : short
    {
        Created = 1,
        Reversed = 9
    }

    public enum ConsolidationType : int
    {
        NoConsolidation = 0,

        /// <summary>
        /// Multiple Cases may appear on the one debit note even if the Owner of the Case is different however the Debtor must be the same.
        /// </summary>
        CaseConsolidationDebtorSame = 1,

        /// <summary>
        /// Multiple Cases may appear on the one debit note however both the Owner and the Debtor must be the same.
        /// </summary>
        CaseConsolidationDebtorOwnerSame = 3,

        /// <summary>
        /// Multiple Cases may appear on the one debit note however the Debtor, Billing Attention Name and Address must be the same.
        /// </summary>
        CaseConsolidationDebtorAttnAddressSame = 5,

        /// <summary>
        /// Multiple Cases may appear on the one debit note however the Debtor, Owner, Billing Attention Name and Address must be the same.
        /// </summary>
        CaseConsolidationDebtorOwnerAttnAddressSame = 7
    }

    public enum PaymentMethod : int
    {
        Cheque = -1,
        BankDraft = -2,
        CreditCard = -3,
        Cash = -4,
        ElectronicTransfer = -5
    }
    
    public enum BillReversalTypeAllowed : int
    {
        /// <summary>
        /// any bill can be reversed
        /// </summary>
        ReversalAllowed = 0,
        /// <summary>
        /// the user will not be able to reverse a bill. 
        /// </summary>
        ReversalNotAllowed = 1,
        /// <summary>
        /// the user will not be able to reverse a bill posted into a period that is closed for Time and Billing.
        /// </summary>
        CurrentPeriodReversalAllowed = 2
    }
    
    public enum BillRuleType : int
    {
        /// <summary>
        /// TableCodes type 63
        /// </summary>
        MinimumNetBill = 21,
        BillingEntity = 22,
        MinimumWipValue = 23
    }

    public enum OpenItemXmlType : byte
    {
        FullElectronicBillXml = 0,
        ElectronicBillMappedValueXmlOnly = 1
    }
}