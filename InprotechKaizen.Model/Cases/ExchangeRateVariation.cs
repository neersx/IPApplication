using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases
{
    [Table("EXCHRATEVARIATION")]
    public class ExchangeRateVariation
    {
        public ExchangeRateVariation()
        {

        }

        [Key]
        [Column("EXCHVARIATIONID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Column("EXCHSCHEDULEID")]
        public int? ExchScheduleId { get; set; }

        [Column("CURRENCYCODE")]
        [MaxLength(3)]
        public string CurrencyCode { get; set; }

        [Column("CASETYPE")]
        [MaxLength(1)]
        public string CaseTypeCode { get; set; }

        [Column("CASECATEGORY")]
        [MaxLength(2)]
        public string CaseCategoryCode { get; set; }

        [Column("PROPERTYTYPE")]
        [MaxLength(1)]
        public string PropertyTypeCode { get; set; }

        [Column("COUNTRYCODE")]
        [MaxLength(3)]
        public string CountryCode { get; set; }

        [Column("CASESUBTYPE")]
        [MaxLength(2)]
        public string SubtypeCode { get; set; }

        [Column("SELLRATE")]
        public decimal? SellRate { get; set; }

        [Column("BUYRate")]
        public decimal? BuyRate { get; set; }

        [Column("BUYFACTOR")]
        public decimal? BuyFactor { get; set; }

        [Column("SELLFACTOR")]
        public decimal? SellFactor { get; set; }

        [Column("EFFECTIVEDATE")]
        public DateTime? EffectiveDate { get; set; }

        [Column("NOTES")]
        public string Notes { get; set; }

        public virtual ExchangeRateSchedule ExchangeRateSchedule { get; set; }
        public virtual Currency Currency { get; set; }
        public virtual CaseType CaseType { get; set; }
        public virtual Country Country { get; set; }
    }
}
