using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Work
{
    [Table("WIPCATEGORY")]
    public class WipCategory
    {
        [Key]
        [MaxLength(3)]
        [Column("CATEGORYCODE")]
        public string Id { get; set; }

        [MaxLength(50)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTid { get; set; }

        [Column("CATEGORYSORT")]
        public short? CategorySortOrder { get; set; }

        [Column("HISTORICALEXCHRATE")]
        public bool? HistoricalExchangeRate { get; set; }
    }
}