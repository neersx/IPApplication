using System;
using Newtonsoft.Json;

namespace Inprotech.Web.Policing
{
    public class PolicingErrorItem
    {
        public int CaseId { get; set; }

        public DateTime ErrorDate { get; set; }

        public int? EventNumber { get; set; }

        [JsonIgnore]
        public string SpecificDescription { get; set; }

        [JsonIgnore]
        public string BaseDescription { get; set; }

        public string EventDescription => SpecificDescription ?? BaseDescription;

        public short? EventCycle { get; set; }

        public string Message { get; set; }

        public int? EventCriteriaNumber { get; set; }

        public bool HasEventControl => !string.IsNullOrWhiteSpace(SpecificDescription);

        public string CriteriaDescription { get; set; }
    }

    public class PolicingErrorLogItem
    {
        public int PolicingErrorsId { get; set; }

        public string CaseRef { get; set; }

        public int? CaseId { get; set; }

        public DateTime ErrorDate { get; set; }

        public short ErrorSeq { get; set; }

        public int? EventNumber { get; set; }

        [JsonIgnore]
        public string SpecificDescription { get; set; }

        [JsonIgnore]
        public string BaseDescription { get; set; }

        public string EventDescription => SpecificDescription ?? BaseDescription;

        public short? EventCycle { get; set; }

        public string Message { get; set; }

        public int? EventCriteriaNumber { get; set; }

        public string EventCriteriaDescription { get; set; }

        public bool ErrorForInProgressQueue { get; set; }

        public InprogressItem ErrorForInProgressItem { get; set; }

        public bool HasEventControl => !string.IsNullOrWhiteSpace(SpecificDescription);
    }

    public enum InprogressItem
    {
        None = 0,
        Queue = 1,
        Request = 2
    }
}
