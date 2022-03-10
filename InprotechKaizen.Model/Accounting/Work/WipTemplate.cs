using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Work
{
    [Table("WIPTEMPLATE")]
    public class WipTemplate
    {
        [Key]
        [MaxLength(6)]
        [Column("WIPCODE")]
        public string WipCode { get; set; }

        [MaxLength(30)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTid { get; set; }

        [Column("USEDBY")]
        public short? UsedBy { get; set; }

        [MaxLength(6)]
        [Column("WIPTYPEID")]
        public string WipTypeId { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [MaxLength(2)]
        [Column("ACTION")]
        public string ActionId { get; set; }

        [Column("NOTINUSEFLAG")]
        public bool IsNotInUse { get; set; }

        [Column("RENEWALFLAG")]
        public decimal IsRenewalWip { get; set; }

        [Column("TAXCODE")]
        public string TaxCode { get; set; }
        
        [Column("WIPCODESORT")]
        public short? WipCodeSortOrder { get; set; }

        public virtual WipType WipType { get; set; }
    }
}