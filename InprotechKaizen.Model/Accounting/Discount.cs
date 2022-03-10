using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("DISCOUNT")]
    public class Discount
    {
        [Key]
        [Column("DISCOUNTID")]
        public int Id { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }

        [Column("SEQUENCE")]
        public short Sequence { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [MaxLength(2)]
        [Column("ACTION")]
        public string ActionId { get; set; }

        [Column("DISCOUNTRATE")]
        public decimal? DiscountRate { get; set; }

        [MaxLength(3)]
        [Column("WIPCATEGORY")]
        public string WipCategory { get; set; }

        [Column("BASEDONAMOUNT")]
        public decimal? BasedOnAmount { get; set; }

        [MaxLength(6)]
        [Column("WIPTYPEID")]
        public string WipTypeId { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeId { get; set; }

        [Column("PRODUCTCODE")]
        public int? ProductCode { get; set; }

        [Column("CASEOWNER")]
        public int? CaseOwnerId { get; set; }

        [Column("MARGINPROFILENO")]
        public int? MarginProfileId { get; set; }

        [MaxLength(6)]
        [Column("WIPCODE")]
        public string WipCode { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }
    }
}