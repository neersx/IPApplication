using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Formatting;
using Newtonsoft.Json;

namespace Inprotech.Web.Policing
{
    public class PolicingRequestLogItem
    {
        public int PolicingLogId { get; set; }

        public string PolicingName { get; set; }

        public DateTime StartDateTime { get; set; }

        public DateTime? FinishDateTime { get; set; }

        [JsonConverter(typeof(RoundedTimeSpanConverter))]
        public TimeSpan? TimeTaken
        {
            get
            {
                if (FinishDateTime != null)
                {
                    return FinishDateTime - StartDateTime;
                }
                return null;
            }
        }

        public string FailMessage { get; set; }

        public bool HasErrors
        {
            get { return !string.IsNullOrEmpty(FailMessage); }
        }

        public DateTime? FromDate { get; set; }

        public short? NumberOfDays { get; set; }

        public string Status { get; set; }

        public RequestLogError Error { get; set; }
        public int? RequestId { get; set; }

        [JsonIgnore]
        public short? SpId { get; set; }

        [JsonIgnore]
        public DateTime? SpIdStart { get; set; }

        public bool CanDelete { get; set; }
    }

    public class RequestLogError
    {
        public RequestLogError()
        {
            ErrorItems = Enumerable.Empty<object>();
        }

        public DateTime StartDateTime { get; set; }

        public int TotalErrorItemsCount { get; set; }

        public IEnumerable<object> ErrorItems { get; set; }
    }
}