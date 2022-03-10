using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("ITEM")]
    public class DocItem
    {
        [Key]
        [Column("ITEM_ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [Required]
        [MaxLength(40)]
        [Column("ITEM_NAME")]
        public string Name { get; set; }

        [Required]
        [MaxLength(254)]
        [Column("ITEM_DESCRIPTION")]
        public string Description { get; set; }

        [Required]
        [Column("SQL_QUERY")]
        public string Sql { get; set; }

        [MaxLength(254)]
        [Column("SQL_DESCRIBE")]
        public string SqlDescribe { get; set; }

        [MaxLength(1000)]
        [Column("SQL_INTO")]
        public string SqlInto { get; set; }

        [Column("ITEM_TYPE")]
        public short? ItemType { get; set; }

        [Column("ENTRY_POINT_USAGE")]
        public short? EntryPointUsage { get; set; }

        [Column("ITEM_DESCRIPTION_TID")]
        public int? ItemDescriptionTId { get; set; }

        [MaxLength(50)]
        [Column("CREATED_BY")]
        public string CreatedBy { get; set; }

        [Column("DATE_CREATED")]
        public DateTime? DateCreated { get; set; }

        [Column("DATE_UPDATED")]
        public DateTime? DateUpdated { get; set; }

        public virtual ItemNote Note { get; set; }

        public bool ReturnsImage()
        {
            return !string.IsNullOrEmpty(SqlDescribe) && SqlDescribe.Trim().Contains("9");
        }
    }
}
