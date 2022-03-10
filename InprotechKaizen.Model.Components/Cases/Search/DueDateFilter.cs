using System.Xml.Serialization;
using InprotechKaizen.Model.Components.Queries;

namespace InprotechKaizen.Model.Components.Cases.Search
{
    public class DueDateFilter
    {
        public DueDates DueDates { get; set; }
    }

    public class DueDates
    {
        [XmlAttribute]
        public short UseEventDates { get; set; }
        [XmlAttribute]
        public short UseAdHocDates { get; set; }
        public Dates Dates { get; set; }
        public DueDateImportanceLevel ImportanceLevel { get; set; }
        public SearchElement EventCategoryKey { get; set; }
        public SearchElement EventKey { get; set; }
        public DueDateActions Actions { get; set; }
        public DueDateResponsibilityOf DueDateResponsibilityOf { get; set; }
    }
    
    public class Dates
    {
        [XmlAttribute]
        public short UseDueDate { get; set; }
        [XmlAttribute]
        public short UseReminderDate { get; set; }

        [XmlAttribute]
        public short SinceLastWorkingDay { get; set; }

        public DateRange DateRange { get; set; }
        public PeriodRange PeriodRange { get; set; }
    }

    public class PeriodRange
    {
        [XmlAttribute]
        public string Operator { get; set; }
        [XmlElement]
        public string Type { get; set; }
        [XmlElement]
        public short? From { get; set; }

        [XmlElement]
        public short? To { get; set; }

        public bool ShouldSerializeFrom()
        {
            return From.HasValue;
        }

        public bool ShouldSerializeTo()
        {
            return To.HasValue;
        }
    }

    public class DueDateImportanceLevel
    {
        [XmlAttribute]
        public short Operator { get; set; }
        [XmlElement]
        public string From { get; set; }
        [XmlElement]
        public string To { get; set; }
    }

    public class DueDateResponsibilityOf 
    {
        [XmlAttribute]
        public short IsAnyName { get; set; }
        [XmlAttribute]
        public short IsStaff { get; set; }
        [XmlAttribute]
        public short IsSignatory { get; set; }
        public SearchElement NameType { get; set; }
        public SearchElement NameKey { get; set; }
        public SearchElement NameGroupKey { get; set; }
        public SearchElement StaffClassificationKey { get; set; }
    }

    public class DueDateActions
    {
        [XmlAttribute]
        public short IncludeClosed { get; set; }
        [XmlAttribute]
        public short IsRenewalsOnly { get; set; }
        [XmlAttribute]
        public short IsNonRenewalsOnly { get; set; }
        public SearchElement ActionKey { get; set; }
    }
}
