using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("NARRATIVERULE")]
    public class NarrativeRule
    {
        [Key]
        [Column("NARRATIVERULENO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int NarrativeRuleId { get; set; }

        [Column("NARRATIVENO")]
        public short NarrativeId { get; set; }

        [Required]
        [MaxLength(6)]
        [Column("WIPCODE")]
        public string WipCode { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffId { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [MaxLength(2)]
        [Column("CASECATEGORY")]
        public string CaseCategoryId { get; set; }

        [MaxLength(2)]
        [Column("SUBTYPE")]
        public string SubTypeId { get; set; }

        [Column("TYPEOFMARK")]
        public int? TypeOfMark { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [Column("LOCALCOUNTRYFLAG")]
        public bool? IsLocalCountry { get; set; }

        [Column("FOREIGNCOUNTRYFLAG")]
        public bool? IsForeignCountry { get; set; }

        [Column("DEBTORNO")]
        public int? DebtorId { get; set; }
    }
}