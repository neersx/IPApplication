using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Tax
{
    [Table("TAXRATESCOUNTRY")]
    public class TaxRatesCountry
    {
        [Key]
        [Column("TAXRATESCOUNTRYID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int TaxRateCountryId { get; set; }

        [MaxLength(3)]
        [Column("TAXCODE")]
        public string TaxCode { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }
        
        [Column("RATE")]
        public decimal? Rate { get; set; }

        [Column("EFFECTIVEDATE")]
        public DateTime? EffectiveDate { get; set; }
    }
}
