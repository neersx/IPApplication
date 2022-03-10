using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("DESIGNELEMENT")]
    public class DesignElement
    {
        [Obsolete("For persistence only...")]
        public DesignElement()
        {
        }

        public DesignElement(int caseId, int sequence)
        {
            CaseId = caseId;
            Sequence = sequence;
        }

        [Key]
        [Column("CASEID", Order = 0)]
        public int CaseId { get; protected set; }

        [Key]
        [Column("SEQUENCE", Order = 1)]
        public int Sequence { get; protected set; }

        [Required]
        [MaxLength(20)]
        [Column("FIRMELEMENTID")]
        public string FirmElementId { get; set; }

        [MaxLength(254)]
        [Column("ELEMENTDESC")]
        public string Description { get; set; }

        [MaxLength(254)]
        [Column("CLIENTELEMENTID")]
        public string ClientElementId { get; set; }

        [Column("RENEWFLAG")]
        public bool? IsRenew { get; set; }

        [Column("TYPEFACE")]
        public int? Typeface { get; set; }
       
        [MaxLength(20)]
        [Column("OFFICIALELEMENTID")]
        public string OfficialElementId { get; set; }

        [MaxLength(36)]
        [Column("REGISTRATIONNO")]
        public string RegistrationNo { get; set; }

        [Column("STOPRENEWDATE")]
        public DateTime? StopRenewDate { get; set; }

        [Column("ELEMENTDESC_TID")]
        public int? ElementdescTid { get; set; }
        
    }
}
