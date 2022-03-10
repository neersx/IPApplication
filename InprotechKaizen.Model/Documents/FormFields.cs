using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("FORMFIELDS")]
    public class FormFields
    {
        [Obsolete("For persistence only.")]
        public FormFields()
        {
        }

        [Key]
        [Column("DOCUMENTNO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short DocumentId { get; set; }

        [Required]
        [MaxLength(3000)]
        [Column("FIELDNAME")]
        public string FieldName { get; set; }

        [Column("FIELDTYPE")]
        public short FieldType { get; set; }

        [Column("ITEM_ID")]
        public int? ItemId { get; set; }

        [MaxLength(254)]
        [Column("FIELDDESCRIPTION")]
        public string FieldDescription { get; set; }

        [Column("ITEMPARAMETER")]
        public string ItemParameter { get; set; }

        [MaxLength(10)]
        [Column("RESULTSEPARATOR")]
        public string ResultSeperator { get; set; }
    }
}