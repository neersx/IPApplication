using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Policing
{
    [Table("POLICINGLOG")]
    public class PolicingLog
    {
        public PolicingLog(DateTime startDateTime)
        {
            StartDateTime = startDateTime;
        }

        public PolicingLog()
        {
            
        }

        [Column("POLICINGLOGID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int PolicingLogId { get; set; }

        [Key]
        [Column("STARTDATETIME")]
        public DateTime StartDateTime { get;set; }

        [Column("FINISHDATETIME")]
        public DateTime? FinishDateTime { get; set; }

        [MaxLength(254)]
        [Column("FAILMESSAGE")]
        public string FailMessage { get; set; }

        [MaxLength(40)]
        [Column("POLICINGNAME")]
        public string PolicingName { get; set; }

        [Column("FROMDATE")]
        public DateTime? FromDate { get; set; }

        [Column("NOOFDAYS")]
        public short? NumberOfDays { get; set; }

        [Column("PROCESSINGCASEID")]
        public int? LastCaseId { get; set; }

        [Column("SPID")]
        public short? SpId { get; set; }

        [Column("SPIDSTART")]
        public DateTime? SpIdStart { get; set; }
    }
}
