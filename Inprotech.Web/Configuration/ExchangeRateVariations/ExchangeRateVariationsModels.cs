using System;

namespace Inprotech.Web.Configuration.ExchangeRateVariations
{
    public class ExchangeRateVariationsFilterModel
    {
        public string CurrencyCode { get; set; }
        public int? ExchangeRateScheduleId { get; set; }
        public string CaseType { get; set; }
        public string CountryCode { get; set; }
        public string PropertyType { get; set; }
        public string CaseCategory { get; set; }
        public string SubType { get; set; }
        public bool IsExactMatch { get; set; }
    }

    public class ExchangeRateVariationsResult
    {
        public int Id { get; set; }
        public string CurrencyCode { get; set; }
        public string Currency { get; set; }
        public int? ExchangeRateScheduleId { get; set; }
        public string ExchangeRateSchedule { get; set; }
        public int? CaseTypeId { get; set; }
        public string CaseTypeCode {get; set; }
        public string CaseType { get; set; }
        public string PropertyTypeCode { get; set; }
        public string PropertyType { get; set; }
        public string CaseCategoryCode { get; set; }
        public string CaseCategory { get; set; }
        public string SubTypeCode { get; set; }
        public string SubType { get; set; }
        public string CountryCode { get; set; }
        public string Country { get; set; }
        public DateTime? EffectiveDate { get; set; }
        public decimal? BuyFactor { get; set; }
        public decimal? SellFactor { get; set; }
        public decimal? BuyRate { get; set; }
        public decimal? SellRate { get; set; }
        public string Notes { get; set; }
    }

    public class ExchangeRateVariationModel
    {
        public int Id { get; set; }
        public PicklistItem ExchRateSch { get; set; }
        public PicklistItem Currency { get; set; }
        public PicklistItem CaseType { get; set; }
        public PicklistItem CaseCategory { get; set; }
        public PicklistItem PropertyType { get; set; }
        public PicklistItem Country { get; set; }
        public PicklistItem SubType { get; set; }
        public DateTime? EffectiveDate { get; set; }
        public decimal? BuyRate { get; set; }
        public decimal? BuyFactor { get; set; }
        public decimal? SellRate { get; set; }
        public decimal? SellFactor { get; set; }
        public string Notes { get; set; }
    }

    public class PicklistItem
    {
        public int? Id { get; set; }
        public int? Key { get; set; }
        public string Code { get; set; }
        public string Value { get; set; }
    }

    public class ExchangeRateVariationRequest
    {
        public int? Id { get; set; }
        public int? ExchScheduleId { get; set; }
        public string CurrencyCode { get; set; }
        public string CaseTypeCode { get; set; }
        public string CaseCategoryCode { get; set; }
        public string PropertyTypeCode { get; set; }
        public string CountryCode { get; set; }
        public string SubTypeCode { get; set; }
        public DateTime? EffectiveDate { get; set; }
        public decimal? BuyRate { get; set; }
        public decimal? BuyFactor { get; set; }
        public decimal? SellRate { get; set; }
        public decimal? SellFactor { get; set; }
        public string Notes { get; set; }
    }
}
