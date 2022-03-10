using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("RECIPROCITY")]
    public class Reciprocity
    {
        [Key]
        [Column("CASETYPE", Order = 0)]
        [MaxLength(1)]
        public string CaseTypeId { get; set; }

        [Key]
        [Column("PROPERTYTYPE", Order = 1)]
        [MaxLength(1)]
        public string PropertyTypeId { get; set; }

        [Key]
        [Column("YEAROFRECEIPT", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short YearOfReceipt { get; set; }

        [Key]
        [Column("COUNTRYCODE", Order = 3)]
        [MaxLength(3)]
        public string CountryCode { get; set; }

        [Key]
        [Column("CATEGORY", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CategoryId { get; set; }

        [Key]
        [Column("NAMENO", Order = 5)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int NameId { get; set; }

        [Key]
        [Column("NAMETYPE", Order = 6)]
        [MaxLength(3)]
        public string NameTypeId { get; set; }

        [Column("TOTALCASES")]
        public short? TotalCases { get; set; }

        [Column("SERVICECHARGE")]
        public decimal? ServiceCharge { get; set; }
    }
}