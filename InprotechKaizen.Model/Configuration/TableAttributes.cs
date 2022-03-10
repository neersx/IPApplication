using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("TABLEATTRIBUTES")]
    public class TableAttributes
    {
        [Obsolete("For persistence only...")]
        public TableAttributes()
        {
        }

        public TableAttributes(string parentTable, string genericKey)
        {
            if(parentTable == null) throw new ArgumentNullException("parentTable");
            if(genericKey == null) throw new ArgumentNullException("genericKey");

            ParentTable = parentTable;
            GenericKey = genericKey;
        }

        [Key]
        [Column("TABLEATTRIBUTESID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("PARENTTABLE")]
        public string ParentTable { get; set; }

        [Required]
        [MaxLength(20)]
        [Column("GENERICKEY")]
        public string GenericKey { get; set; }

        [Column("TABLETYPE")]
        public short? SourceTableId { get; set; }

        [Column("TABLECODE")]
        public int TableCodeId { get; set; }

        public virtual TableCode TableCode { get; set; }
    }
}