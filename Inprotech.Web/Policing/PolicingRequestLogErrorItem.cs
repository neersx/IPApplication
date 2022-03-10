using System;
using Newtonsoft.Json;

namespace Inprotech.Web.Policing
{
    public class PolicingRequestLogErrorItem
    {
        public DateTime StartDateTime { get; set; }

        public string Irn { get; set; }

        public string EventDescription => SpecificDescription ?? BaseDescription;

        public short? CycleNo { get; set; }

        public string Message { get; set; }

        public int? CriteriaNo { get; set; }

        public int? EventNo { get; set; }

        [JsonIgnore]
        public string SpecificDescription { get; set; }

        [JsonIgnore]
        public string BaseDescription { get; set; }

        public string CriteriaDescription { get; set; }

        public bool HasEventControl => !string.IsNullOrWhiteSpace(SpecificDescription);

    }
}
