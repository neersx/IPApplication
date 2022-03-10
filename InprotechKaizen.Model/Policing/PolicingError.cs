using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Policing
{
    [Table("POLICINGERRORS")]
    public class PolicingError
    {
        [Obsolete("For persistence only.")]
        public PolicingError()
        {
        }

        public PolicingError(DateTime startTime, short errorSeqNo)
        {
            StartDateTime = startTime;
            ErrorSeqNo = errorSeqNo;
        }

        [Column("POLICINGERRORSID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int PolicingErrorsId { get; set; }

        [Column("STARTDATETIME")]
        public DateTime StartDateTime { get; set; }

        [Column("ERRORSEQNO")]
        public short ErrorSeqNo { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; internal set; }

        [Column("CRITERIANO")]
        public int? CriteriaNo { get; set; }

        [Column("EVENTNO")]
        public int? EventNo { get; set; }

        [Column("CYCLENO")]
        public short? CycleNo { get; set; }

        [MaxLength(254)]
        [Column("MESSAGE")]
        public string Message { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        public virtual Case Case { get; set; }

        public virtual PolicingLog PolicingLog { get; set; }
    }
}
