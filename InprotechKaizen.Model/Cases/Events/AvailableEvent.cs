using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Cases.Events
{
    [Table("DETAILDATES")]
    public class AvailableEvent
    {
        [Obsolete("For persistence only.")]
        public AvailableEvent()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public AvailableEvent(DataEntryTask dataEntryTask, Event @event, Event alsoUpdateEvent = null)
        {
            if (dataEntryTask == null) throw new ArgumentNullException(nameof(dataEntryTask));
            if (@event == null) throw new ArgumentNullException(nameof(@event));

            CriteriaId = dataEntryTask.CriteriaId;
            DataEntryTaskId = dataEntryTask.Id;
            EventId = @event.Id;

            Event = @event;

            if (alsoUpdateEvent != null)
            {
                AlsoUpdateEvent = alsoUpdateEvent;
                AlsoUpdateEventId = alsoUpdateEvent.Id;
            }
        }

        [Key]
        [Column("CRITERIANO", Order = 0)]
        public int CriteriaId { get; internal set; }

        [Key]
        [Column("ENTRYNUMBER", Order = 1)]
        public short DataEntryTaskId { get; set; }

        [Key]
        [Column("EVENTNO", Order = 2)]
        public int EventId { get; internal set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Event")]
        public virtual Event Event { get; internal set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("DEFAULTFLAG")]
        public decimal? DefaultFlag { get; set; }

        [Column("EVENTATTRIBUTE")]
        public short? EventAttribute { get; set; }

        [Column("DUEATTRIBUTE")]
        public short? DueAttribute { get; set; }

        [Column("POLICINGATTRIBUTE")]
        public short? PolicingAttribute { get; set; }

        [Column("PERIODATTRIBUTE")]
        public short? PeriodAttribute { get; set; }

        [Column("OVRDUEATTRIBUTE")]
        public short? OverrideDueAttribute { get; set; }

        [Column("OVREVENTATTRIBUTE")]
        public short? OverrideEventAttribute { get; set; }

        [Column("JOURNALATTRIBUTE")]
        public short? JournalAttribute { get; set; }

        [Column("DUEDATERESPATTRIBUTE")]
        public short? DueDateResponsibleNameAttribute { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short? DisplaySequence { get; set; }

        [Column("OTHEREVENTNO")]
        [ForeignKey("AlsoUpdateEvent")]
        public int? AlsoUpdateEventId { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited == 1; }
            set { Inherited = value ? 1 : 0; }
        }

        [NotMapped]
        public string EventName => Event?.Description;

        public virtual Event AlsoUpdateEvent { get; internal set; }

        public bool CanUpdateAsToday => DueAttribute == null && EventAttribute == (short) EntryAttribute.DefaultToSystemDate;
    }

    public static class AvailableEventExt
    {
        public static AvailableEvent InheritRuleFrom(this AvailableEvent availableEvent, AvailableEvent from)
        {
            if (availableEvent == null) throw new ArgumentNullException(nameof(availableEvent));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            availableEvent.IsInherited = true;
            availableEvent.EventId = from.EventId;
            return availableEvent.CopyFrom(from);
        }

        public static AvailableEvent CreateCopy(this AvailableEvent from)
        {
            if (@from == null) throw new ArgumentNullException(nameof(@from));

#pragma warning disable 618
            var newEntity = new AvailableEvent
                            {
                                EventId = @from.EventId,
                                Inherited = @from.Inherited
                            };
#pragma warning restore 618
            return newEntity.CopyFrom(from);
        }

        static AvailableEvent CopyFrom(this AvailableEvent availableEvent, AvailableEvent from)
        {
            availableEvent.DefaultFlag = from.DefaultFlag;
            availableEvent.EventAttribute = from.EventAttribute;
            availableEvent.DueAttribute = from.DueAttribute;
            availableEvent.PolicingAttribute = from.PolicingAttribute;
            availableEvent.PeriodAttribute = from.PeriodAttribute;
            availableEvent.OverrideDueAttribute = from.OverrideDueAttribute;
            availableEvent.OverrideEventAttribute = from.OverrideEventAttribute;
            availableEvent.JournalAttribute = from.JournalAttribute;
            availableEvent.DueDateResponsibleNameAttribute = from.DueDateResponsibleNameAttribute;
            availableEvent.AlsoUpdateEventId = from.AlsoUpdateEventId;
            availableEvent.DisplaySequence = from.DisplaySequence;

            return availableEvent;
        }
    }
}