namespace Inprotech.Web.Accounting.Time
{
    public class TimeRecordingSettings
    {
        public bool DisplaySeconds { get; set; }
        public string LocalCurrencyCode { get; set; }
        public bool TimeEmptyForNewEntries { get; set; }
        public bool RestrictOnWip { get; set; }
        public bool AddEntryOnSave { get; set; }
        public bool TimeFormat12Hours { get; set; }
        public bool HideContinuedEntries { get; set; }
        public bool ContinueFromCurrentTime { get; set; }
        public int UnitsPerHour { get; set; }
        public bool RoundUpUnits { get; set; }
        public bool ConsiderSecsInUnitsCalc { get; set; }
        public bool EnableUnitsForContinuedTime { get; set; }
        public bool WipSplitMultiDebtor { get; set; }
        public bool ValueTimeOnEntry { get; set; }
        public int? TimePickerInterval { get; set; }
        public int? DurationPickerInterval { get; set; }
    }

    public class UserInfo
    {
        public int NameId { get; set; }
        public string DisplayName { get; set; }
        public bool CanAdjustValues { get; set; }
        public bool CanFunctionAsOtherStaff { get; set; }
        public bool MaintainPostedTimeEdit { get; set; }
        public bool MaintainPostedTimeDelete { get; set; }
        public bool IsStaff { get; set; }
    }

    public class DefaultInfo
    {
        public int CaseId { get; set; }
        public string CaseReference { get; set; }
    }

    public class TimeSheetEnquiryViewData
    {
        public TimeRecordingSettings Settings { get; set; }
        public bool CanViewCaseAttachments { get; set; }
        public bool CanPostForAllStaff { get; set; }
        public UserInfo UserInfo { get; set; }
        public DefaultInfo DefaultInfo { get; set; }
    }
}