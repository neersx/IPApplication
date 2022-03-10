using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Cases
{
    public class CaseData
    {
        public int ItemEntityNo { get; set; }
        public int ItemTransNo { get; set; }
        public int CaseId { get; set; }
        public string CaseReference { get; set; }
        public string Title { get; set; }
        public string CaseTypeCode { get; set; }
        public string CaseTypeDescription { get; set; }
        public string CountryCode { get; set; }
        public string Country { get; set; }
        public string PropertyType { get; set; }
        public string PropertyTypeDescription { get; set; }
        public decimal? TotalCredits { get; set; }
        public decimal? UnlockedWip { get; set; }
        public decimal? TotalWip { get; set; }

        public string OpenAction { get; set; }
        public bool? IsMainCase { get; set; }
        public int? LanguageId { get; set; }
        public string LanguageDescription { get; set; }
        public string BillSourceCountryCode { get; set; }
        public int? CaseListId { get; set; }
        public string TaxCode { get; set; }
        public string TaxDescription { get; set; }
        public decimal? TaxRate { get; set; }
        public string CaseProfitCentre { get; set; }
        public ICollection<CaseUnpostedTime> UnpostedTimeList { get; set; } = new Collection<CaseUnpostedTime>();
        public bool IsMultiDebtorCase { get; set; }
        public string CaseStatus { get; set; }
        public string OfficialNumber { get; set; }
        public bool HasRestrictedStatusForBilling { get; set; }
        public int? OfficeEntityId { get; set; }
        public ICollection<string> DraftBills { get; set; } = new Collection<string>();
    }

    public class CaseUnpostedTime
    {
        public int NameId { get; set; }
        public string Name { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime TotalTime { get; set; }
        public decimal TimeValue { get; set; }
    }
}
