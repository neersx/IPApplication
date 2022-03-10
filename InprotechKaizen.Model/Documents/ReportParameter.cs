using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("REPORTPARAM")]
    public class ReportParameter
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("LETTERNO")]
        public short LetterId { get; set; }

        [MaxLength(254)]
        [Required]
        [Column("PARAMNAME")]
        public string Name { get; set; }

        [Column("ITEM_ID")]
        public int ItemId { get; set; }
    }
}