
using System;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public class BulkCaseUpdatesArgs
    {
        public int ProcessId { get; set; }

        public int[] CaseIds { get; set; }

        public BulkUpdateData SaveData { get; set; }

        public string TextType { get; set; }
        public string Notes { get; set; }

        public string CaseAction { get; set; }
    }

    public class BulkUpdateData
    {
        public BulkSaveData CaseOffice { get; set; }
        public BulkSaveData ProfitCentre { get; set; }
        public BulkSaveData EntitySize { get; set; }
        public BulkSaveData PurchaseOrder { get; set; }
        public BulkSaveData TitleMark { get; set; }
        public BulkSaveData CaseFamily { get; set; }
        public BulkSaveData TypeOfMark { get; set; }
        public BulkCaseTextUpdate CaseText { get; set; }
        public BulkFileLocationUpdate FileLocation { get; set; }
        public BulkCaseNameReferenceUpdate CaseNameReference { get; set; }
        public BulkCaseStatusUpdate CaseStatus { get; set; }
        public BulkCaseStatusUpdate RenewalStatus { get; set; }
    }

    public class BulkCaseTextUpdate
    {
        public string Language { get; set; }
        public string TextType { get; set; }
        public string Notes { get; set; }
        public bool ToRemove { get; set; }
        public bool CanAppend { get; set; }
        public string Class { get; set; }
    }

    public class BulkCaseNameReferenceUpdate
    {
        public string Reference { get; set; }
        public string NameType { get; set; }
        public bool ToRemove { get; set; }
    }

    public class BulkFileLocationUpdate
    {
        public int? FileLocation { get; set; }
        public int? MovedBy { get; set; }
        public string BayNumber { get; set; }
        public DateTime WhenMoved { get; set; }
        public bool ToRemove { get; set; }
    }

    public class BulkSaveData
    {
        public string Key { get; set; }
        public string Value { get; set; }
        public bool ToRemove { get; set; }
    }

    public class BulkCaseStatusUpdate
    {
        public string StatusCode { get; set; }
        public bool IsRenewal { get; set; }
        public bool ToRemove { get; set; }
        public string Password { get; set; }
    }
}
