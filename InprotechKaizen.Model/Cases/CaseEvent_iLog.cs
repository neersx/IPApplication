using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASEEVENT_iLog")]
    public class CaseEventILog
    {
        [Obsolete("For persistence only...")]
        public CaseEventILog()
        {
        }

        [Column("CASEID")]
        public int CaseId { get; protected set; }

        [Column("EVENTNO")]
        public int EventNo { get; protected set; }

        [Column("CYCLE")]
        public short Cycle { get; protected set; }
    }
}