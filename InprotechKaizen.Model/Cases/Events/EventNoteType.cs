using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases.Events
{
    [Table("EVENTTEXTTYPE")]
    public class EventNoteType
    {
        [Obsolete("For persistence only.")]
        public EventNoteType()
        {
        }

        public EventNoteType(string description, bool isExternal, bool sharingAllowed)
        {
            Description = description;
            IsExternal = isExternal;
            SharingAllowed = sharingAllowed;
        }

        [Key]
        [Column("EVENTTEXTTYPEID")]
        public short Id { get; set; }

        [Required]
        [MaxLength(250)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [Column("ISEXTERNAL")]
        public bool IsExternal { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        [Column("SHARINGALLOWED")]
        public bool? SharingAllowed { get; set; }
    }
}