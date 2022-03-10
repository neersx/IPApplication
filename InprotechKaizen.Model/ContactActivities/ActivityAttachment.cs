using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.ContactActivities
{
    [Table("ACTIVITYATTACHMENT")]
    public class ActivityAttachment
    {
        [Obsolete("For Persistent Purposes")]
        public ActivityAttachment()
        {
        }

        public ActivityAttachment(int activityId, int sequenceNo)
        {
            ActivityId = activityId;
            SequenceNo = sequenceNo;
        }

        [Key]
        [Column("ACTIVITYNO", Order = 1)]
        [ForeignKey("Activity")]
        public int ActivityId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        public int SequenceNo { get; set; }

        [MaxLength(254)]
        [Column("ATTACHMENTNAME")]
        public string AttachmentName { get; set; }

        [Required]
        [MaxLength(254)]
        [Column("FILENAME")]
        public string FileName { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("PUBLICFLAG")]
        public decimal? PublicFlag { get; set; }

        [Column("ATTACHMENTTYPE")]
        public int? AttachmentTypeId { get; set; }
        public virtual TableCode AttachmentType { get; set; }

        [Column("PAGECOUNT")]
        public int? PageCount { get; set; }

        [Column("REFERENCE")]
        public Guid? Reference { get; set; }

        [MaxLength(254)]
        [Column("ATTACHMENTDESC")]
        public string AttachmentDescription { get; set; }

        public virtual AttachmentContent AttachmentContent { get; set; }

        public virtual Activity Activity { get; set; }

        [Column("LANGUAGENO")]
        public int? LanguageId { get; set; }
        public virtual TableCode Language { get; set; }
    }
}