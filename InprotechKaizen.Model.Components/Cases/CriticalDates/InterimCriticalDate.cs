using System;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public class InterimCriticalDate
    {
        [ThreadStatic]
        static short _identity;

        public InterimCriticalDate()
        {
            _identity++;
        }

        public int CaseKey { get; set; }
        public string EventDescription { get; set; }
        public string EventDefinition { get; set; }
        public DateTime? DisplayDate { get; set; }
        public string OfficialNumber { get; set; }
        public string CountryCode { get; set; }
        public bool? IsLastOccurredEvent { get; set; }
        public bool? IsNextDueEvent { get; set; }
        public bool? IsCPARenewalDate { get; set; }
        public short? DisplaySequence { get; set; }
        public short? RenewalYear { get; set; }
        public string RowKey { get; set; }
        public int? EventKey { get; set; }
        public string CountryKey { get; set; }
        public bool? IsPriorityEvent { get; set; }
        public string NumberTypeCode { get; set; }
        public int? NumberTypeDataItemId { get; set; }
        public Uri ExternalPatentInfoUri { get; set; }
        public short Sequence => _identity;
        public bool? IsOccurred { get; set; }
        public string Weighting { get; set; }
    }
}