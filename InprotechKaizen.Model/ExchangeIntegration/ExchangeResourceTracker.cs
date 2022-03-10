using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.ExchangeIntegration
{
    [Table("EXCHANGERESOURCETRACKER")]
    public class ExchangeResourceTracker
    {
        [Obsolete("For persistence only.")]
        public ExchangeResourceTracker()
        {

        }

        public ExchangeResourceTracker(int staffId, DateTime seqDate, short resourceType, string resourceId)
        {
            StaffId = staffId;
            SequenceDate = seqDate;
            ResourceId = resourceId;
            ResourceType = resourceType;
        }

        [Key]
        [Column("ID")]
        public long Id { get; protected set; }
        
        [Column("MESSAGESEQ")]
        public DateTime SequenceDate { get; set; }

        [Column("EMPLOYEENO")]
        [ForeignKey("StaffName")]
        public int StaffId { get; set; }

        [Column("RESOURCETYPE")]
        public short ResourceType { get; set; }

        [MaxLength(4000)]
        [Required]
        [Column("RESOURCEID")]
        public string ResourceId { get; set; }

        public virtual Name StaffName { get; set; }

    }
}
