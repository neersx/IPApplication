using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace Inprotech.Web.Policing
{
    public class PolicingQueueItem
    {
        public int RequestId { get; set; }

        public string StatusLabel { get; set; }

        public string Status { get; set; }

        public DateTime Requested { get; set; }

        public string User { get; set; }

        public string UserKey { get; set; }

        public string CaseReference { get; set; }

        public int? EventId { get; set; }

        public string EventDescription
        {
            get { return SpecificEventDescription ?? DefaultEventDescription; }
        }

        public string ActionName
        {
            get { return SpecificActionName ?? DefaultActionName; }
        }

        public int? CriteriaId { get; set; }

        public string CriteriaDescription { get; set; }

        public string TypeOfRequest { get; set; }

        public int? CaseId { get; set; }

        public string PropertyName { get; set; }

        public string Jurisdiction { get; set; }
        public DateTime? NextScheduled { get; set; }
        public string PolicingName { get; set; }

        public int? Cycle { get; set; }

        public bool HasEventControl { get; set; }

        [JsonIgnore]
        public int IdleFor { get; set; }

        [JsonIgnore]
        public string DefaultEventDescription { get; set; }

        [JsonIgnore]
        public string SpecificEventDescription { get; set; }

        [JsonIgnore]
        public string DefaultActionName { get; set; }

        [JsonIgnore]
        public string SpecificActionName { get; set; }

        public QueueError Error { get; set; }
    }

    public class QueueError
    {
        public QueueError()
        {
            ErrorItems = Enumerable.Empty<object>();
        }

        public int CaseId { get; set; }

        public int TotalErrorItemsCount { get; set; }

        public IEnumerable<object> ErrorItems { get; set; }
    }
}