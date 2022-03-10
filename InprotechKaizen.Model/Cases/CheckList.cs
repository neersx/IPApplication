using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [Table("CHECKLISTS")]
    public class CheckList
    {
        [Obsolete("For persistence only.")]
        public CheckList()
        {
        }

        public CheckList(short id, string description)
        {
            if (description == null) throw new ArgumentNullException("description");
            Description = description;
            Id = id;
        }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        public CheckList(short id, string description, decimal? checklistTypeFlag)
        {
            if (description == null) throw new ArgumentNullException("description");
            Description = description;
            Id = id;
            ChecklistTypeFlag = checklistTypeFlag;
        }

        [Key]
        [Column("CHECKLISTTYPE")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Id { get; protected set; }

        [MaxLength(50)]
        [Column("CHECKLISTDESC")]
        public string Description { get; set; }

        [Column("CHECKLISTDESC_TID")]
        public int? ChecklistDescriptionTId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("CHECKLISTTYPEFLAG")]
        public decimal? ChecklistTypeFlag { get; set; }
    }
}