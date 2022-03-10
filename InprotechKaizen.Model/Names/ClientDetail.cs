using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Names
{
    [Table("IPNAME")]
    public class ClientDetail
    {
        [Obsolete("For persistence only")]
        public ClientDetail()
        {
        }

        public ClientDetail(int nameId)
        {
            Id = nameId;
        }

        public ClientDetail(int nameId, Name name)
        {
            Id = nameId;
            Name = name;
        }

        [Key]
        [Column("NAMENO")]
        public int Id { get; set; }

        [Required]
        public Name Name { get; protected set; }

        [Column("BADDEBTOR")]
        public virtual DebtorStatus DebtorStatus { get; set; }

        [Column("CREDITLIMIT")]
        public decimal? CreditLimit { get; set; }

        [MaxLength(5)]
        [Column("AIRPORTCODE")]
        public string AirportCode { get; set; }

        [Column("BILLINGCAP")]
        public decimal? BillingCap { get; set; }

        [Column("BILLINGCAPPERIOD")]
        public int? BillingCapPeriod { get; set; }

        [MaxLength(254)]
        [Column("CORRESPONDENCE")]
        public string Correspondence { get; set; }

        [Column("CORRESPONDENCE_TID")]
        public int? CorrespondenceTid { get; set; }

        [MaxLength(1)]
        [Column("BILLINGCAPPERIODTYPE")]
        public string BillingCapPeriodType { get; set; }

        [Column("BILLINGCAPSTARTDATE")]
        public DateTime? BillingCapStartDate { get; set; }

        [Column("BILLINGCAPRESETFLAG")]
        public bool? IsBillingCapRecurring { get; set; }

        [Column("SEPARATEMARGINFLAG")]
        public bool? UseSeparateMargin { get; set; }

        [Column("CURRENCY")]
        public string CurrencyId { get; set; }

        [Column("CONSOLIDATION", TypeName = "numeric")]
        public ConsolidationType? ConsolidationType { get; set; }

        [Column("CATEGORY")]
        public int? NameCategoryId { get; set; }

        [Column("LOCALCLIENTFLAG")]
        public decimal? LocalClientFlag { get; set; }

        [Column("TRADINGTERMS")]
        public int? TradingTerms { get; set; }

        [ForeignKey("NameCategoryId")]
        public virtual TableCode Category { get; protected set; }
    }
}