using System.Collections.Generic;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Picklists;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public class WorkflowEventControlModel
    {
        public WorkflowEventControlModel Parent { get; set; }
        public int CriteriaId { get; set; }
        public bool AllowDueDateCalcJurisdiction { get; set; } // enables jurisdiction picklist in add due date calc modal
        public int EventId { get; set; }
        public bool IsProtected { get; set; }
        public string InheritanceLevel { get; set; }
        public bool CanEdit { get; set; }
        public bool CanDelete { get; set; }
        public bool EditBlockedByDescendants { get; set; }
        public bool IsNonConfigurableEvent { get; set; }
        public bool IsInherited { get; set; }
        public bool HasChildren { get; set; }
        public bool HasDueDateOnCase { get; set; }
        public bool IsRenewalStatusSupported { get; set; }
        public bool CanResetInheritance { get; set; }
        public bool HasOffices { get; set; }
        public PtaDelayMode PtaDelay { get; set; }
        public EventControlOverview Overview { get; set; }
        public EventControlStandingInstruction StandingInstruction { get; set; }
        public EventControlDueDateCalcSettings DueDateCalcSettings { get; set; }
        public string DatesLogicComparisonType { get; set; }
        public EventControlDesignatedJurisdictions DesignatedJurisdictions { get; set; }
        public SyncedEventSettings SyncedEventSettings { get; set; }
        public Charges Charges { get; set; }
        public dynamic ChangeStatus { get; set; }
        public PicklistModel<short> ChangeRenewalStatus { get; set; }
        public string UserDefinedStatus { get; set; }
        public ChangeAction ChangeAction { get; set; }
        public ReportMode Report { get; set; }
        public NameChangeSettings NameChangeSettings { get; set; }
        public dynamic Characteristics { get; set; }
        public bool CanAddValidCombinations { get; set; }
        public EventOccurrence EventOccurrence { get; set; }
    }

    public enum DueDateRespTypes : short
    {
        NotApplicable = 0,
        Name = 1,
        NameType = 2
    }

    public class EventControlOverview
    {
        public string BaseDescription { get; set; }

        public IEnumerable<KeyValuePair<string, string>> ImportanceLevelOptions { get; set; }

        public EventControlOverviewData Data { get; set; }

        public class EventControlOverviewData
        {
            public string Description { get; set; }
            public short? MaxCycles { get; set; }
            public string Notes { get; set; }
            public string ImportanceLevel { get; set; }
            public dynamic NameType { get; set; }
            public dynamic Name { get; set; }
            public DueDateRespTypes DueDateRespType { get; set; }
        }
    }

    public class EventControlStandingInstruction
    {
        public Picklists.InstructionType InstructionType { get; set; }
        public IEnumerable<KeyValuePair<short, string>> CharacteristicsOptions { get; set; }
        public short? RequiredCharacteristic { get; set; }
        public IEnumerable<string> Instructions { get; set; }
    }

    public class EventControlDueDateCalcSettings
    {
        public string DateToUse { get; set; }
        public bool IsSaveDueDate { get; set; }
        public bool ExtendDueDate { get; set; }
        public DropDownGroup<short?> ExtendDueDateOptions { get; set; }
        public bool? RecalcEventDate { get; set; }
        public bool? DoNotCalculateDueDate { get; set; }
        public IEnumerable<KeyValuePair<string, string>> DateAdjustmentOptions { get; set; }
    }

    public class DropDownGroup<T>
    {
        public DropDownGroup(T value, string type)
        {
            Value = value;
            Type = type;
        }

        public T Value { get; set; }
        public string Type { get; set; }
    }

    public class EventControlDesignatedJurisdictions
    {
        public int? CountryFlagForStopReminders { get; set; }
        public IEnumerable<KeyValuePair<int, string>> CountryFlags { get; set; }
    }

    public class SyncedEventSettings
    {
        public string CaseOption { get; set; }
        public string UseCycle { get; set; }
        public PicklistModel<int> FromEvent { get; set; }
        public PicklistModel<string> FromRelationship { get; set; }
        public PicklistModel<string> LoadNumberType { get; set; }
        public string DateAdjustment { get; set; }
        public IEnumerable<KeyValuePair<string, string>> DateAdjustmentOptions { get; set; }
    }

    public class Charges
    {
        public Charge ChargeOne { get; set; }
        public Charge ChargeTwo { get; set; }
    }

    public class Charge
    {
        public bool IsPayFee { get; set; }
        public bool IsRaiseCharge { get; set; }
        public bool IsEstimate { get; set; }
        public bool? IsDirectPay { get; set; }
        public dynamic ChargeType { get; set; }
    }

    public class ChangeAction
    {
        public KeyValuePair<string, string> OpenAction { get; set; }
        public KeyValuePair<string, string> CloseAction { get; set; }
        public int? RelativeCycle { get; set; }
    }

    public class NameChangeSettings
    {
        public PicklistModel<int> ChangeNameType { get; set; }
        public PicklistModel<int> CopyFromNameType { get; set; }
        public PicklistModel<int> MoveOldNameToNameType { get; set; }
        public bool DeleteCopyFromName { get; set; }
    }

    public class EventOccurrence
    {
        public string DueDateOccurs { get; set; }

        public ValidatedCharacteristics Characteristics { get; set; }
        public bool MatchOffice { get; set; }
        public bool MatchJurisdiction { get; set; }
        public bool MatchPropertyType { get; set; }
        public bool MatchCaseCategory { get; set; }
        public bool MatchSubType { get; set; }
        public bool MatchBasis { get; set; }

        public IEnumerable<PicklistModel<int>> EventsExist { get; set; }
    }

    public enum SaveDueDate
    {
        None = 0,
        SaveDueDate = 1,
        Immediate = 2,
        WhenDue = 4,
        ExtendDueDate = 8
    }

    public enum ReportMode
    {
        NoChange = 0,
        On = 1,
        Off = 2
    }

    public enum PtaDelayMode : short
    {
        NotApplicable = 0,
        IpOfficeDelay = 1,
        ApplicantDelay = 2
    }
}