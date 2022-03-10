using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases.Events;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASEEVENTTEXT")]
    public class CaseEventText
    {

        [Obsolete("For persistence only.")]
        public CaseEventText()
        {
        }

        public CaseEventText(int caseId, int eventId, short cycle)
        {
            CaseId = caseId;
            EventId = eventId;
            Cycle = cycle;
        }

        public CaseEventText(Case @case, int eventNo, short cycle, EventText eventText)
        {
            CaseId = @case.Id;
            EventId = eventNo;
            Cycle = cycle;
            EventNote = eventText;
            Case = @case;
        }

        [Key]
        [Column("CASEID", Order = 0)]
        public int CaseId { get; set; }

        [Key]
        [Column("EVENTNO", Order = 1)]
        public int EventId { get; set; }

        [Key]
        [Column("CYCLE", Order = 2)]
        public short Cycle { get; set; }

        [Key]
        [Column("EVENTTEXTID", Order = 3)]
        public int EventTextId { get; set; }

        public virtual EventText EventNote { get; set; }

        public virtual Case Case { get; protected set; }
    }
}
