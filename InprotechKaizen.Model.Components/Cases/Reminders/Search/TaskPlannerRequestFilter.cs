using System.Collections.Generic;
using System.Xml.Serialization;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Cases.Reminders.Search
{
    public class TaskPlannerRequestFilter : SearchRequestFilter
    {
        public TaskPlannerRequest SearchRequest { get; set; }
        public int[] DeselectedIds { get; set; }
    }

    [XmlRoot("FilterCriteria")]
    public class TaskPlannerRequest
    {
        public Include Include { get; set; }
        public BelongsTo BelongsTo { get; set; }
        public Dates Dates { get; set; }
        public ImportanceLevel ImportanceLevel { get; set; }
        public SearchElement CaseReference { get; set; }
        public SearchElement CaseKeys { get; set; }
        public OfficialNumberElement OfficialNumber { get; set; }
        public FamilyKeyList FamilyKeyList { get; set; }
        public SearchElement CaseList { get; set; }
        public SearchElement OfficeKeys { get; set; }
        public SearchElement CountryKeys { get; set; }
        public SearchElement CaseTypeKeys { get; set; }
        public SearchElement CategoryKey { get; set; }
        public SearchElement SubTypeKey { get; set; }
        public SearchElement BasisKey { get; set; }
        public SearchElement PropertyTypeKeys { get; set; }
        public SearchElement OwnerKeys { get; set; }
        public SearchElement InstructorKeys { get; set; }
        public SearchElement StatusKeys { get; set; }
        public SearchElement EventKeys { get; set; }
        public SearchElement EventCategoryKeys { get; set; }
        public SearchElement EventGroupKeys { get; set; }
        public SearchElement EventNoteTypeKeys { get; set; }
        public SearchElement EventNoteText { get; set; }
        public Actions Actions { get; set; }
        public SearchElement ReminderMessage { get; set; }
        public short? IsReminderOnHold { get; set; }
        public short? IsReminderRead { get; set; }
        public OtherNameTypeKeysElement OtherNameTypeKeys { get; set; }
        public StatusFlags StatusFlags { get; set; }
        public SearchElement StatusKey { get; set; }
        public SearchElement RenewalStatusKey { get; set; }
        public SearchElement AdHocReference { get; set; }
        public SearchElement NameReferenceKeys { get; set; }
        public SearchElement AdHocMessage { get; set; }
        public SearchElement AdHocEmailSubject { get; set; }
        public SearchElement RowKeys { get; set; }
        public bool ShouldSerializeIsReminderOnHold()
        {
            return IsReminderOnHold.HasValue;
        }
        public bool ShouldSerializeIsReminderRead()
        {
            return IsReminderRead.HasValue;
        }
    }
    public class Include
    {
        public short IsReminders { get; set; }
        public short IsDueDates { get; set; }
        public short IsAdHocDates { get; set; }
        public short HasCase { get; set; }
        public short HasName { get; set; }
        public short IsGeneral { get; set; }
        public short IncludeFinalizedAdHocDates { get; set; }
    }

    public class BelongsTo
    {
        public NameKeyElement NameKey { get; set; }
        public SearchElement NameKeys { get; set; }
        public NameKeyElement MemberOfGroupKey { get; set; }
        public SearchElement MemberOfGroupKeys { get; set; }
        public ActingAs ActingAs { get; set; }
    }

    public class NameKeyElement
    {
        [XmlAttribute]
        public short Operator { get; set; }

        [XmlAttribute]
        public short IsCurrentUser { get; set; }
    }

    public class ActingAs
    {
        [XmlAttribute]
        public short IsReminderRecipient { get; set; }
        [XmlAttribute]
        public short IsResponsibleStaff { get; set; }

        [XmlElement(ElementName = "NameTypeKey")]
        public List<string> NameTypeKey { get; set; }
    }

    public class ImportanceLevel
    {
        [XmlAttribute]
        public string Operator { get; set; }
        [XmlElement]
        public int? From { get; set; }
        [XmlElement]
        public int? To { get; set; }
    }
    public class OtherNameTypeKeysElement : SearchElement
    {
        [XmlAttribute]
        public string Type { get; set; }
    }

    public class Actions
    {
        [XmlElement]
        public SearchElement ActionKeys { get; set; }

        [XmlAttribute]
        public short IsRenewalsOnly { get; set; }

        [XmlAttribute]
        public short IsNonRenewalsOnly { get; set; }

        [XmlAttribute]
        public short IncludeClosed { get; set; }
    }
}
