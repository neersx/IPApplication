using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CPAEVENT")]
    public class CpaEvent
    {
        public CpaEvent()
        {

        }

        public CpaEvent(Case @case, int cefNo, DateTime renewalEventDate, string eventCode, int batchNo)
        {
            if(@case == null) throw new ArgumentNullException("case");

            CaseId = @case.Id;
            CefNo = cefNo;
            RenewalEventDate = renewalEventDate;
            EventCode = eventCode;
            BatchNo = batchNo;
        }

        [Key]
        [Column("CEFNO")]
        [Required]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CefNo { get; set; }

        [Column("RENEWALEVENTDATE")]
        public DateTime? RenewalEventDate { get; set; }

        [Column("CASEID")]
        public int CaseId { get; set; }

        [MaxLength(2)]
        [Column("EVENTCODE")]
        public string EventCode { get; set; }

        [Column("BATCHNO")]
        public int BatchNo { get; set; }
    }
}
