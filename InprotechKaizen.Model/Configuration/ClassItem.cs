using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("CLASSITEM")]
    public class ClassItem
    {

        public ClassItem(int classId)
        {
            ClassId = classId;
        }

        public ClassItem(string itemNo, string itemDescription, int? languageCode, int classId) : this(classId)
        {
            ItemNo = itemNo;
            ItemDescription = itemDescription;
            LanguageCode = languageCode;
        }

        [Obsolete("For persistence only.")]
        public ClassItem()
        {

        }

        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(20)]
        [Column("ITEMNO")]
        public string ItemNo { get; set; }

        [Required]
        [Column("DESCRIPTION")]
        public string ItemDescription { get; set; }

        [Column("LANGUAGE")]
        [ForeignKey("Language")]
        public int? LanguageCode { get; set; }

        [Column("CLASS")]
        [ForeignKey("Class")]
        public int ClassId { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Class")]
        public virtual TmClass Class { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Class")]
        public virtual TableCode Language { get; set; }

    }
}
