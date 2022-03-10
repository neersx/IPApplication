using System;

namespace Inprotech.Web.Exchange
{
    public class ExchangeRequest
    {
        public int Id { get; set; }
        public string Staff { get; set; }
        public string EventDescription { get; set; }
        public string ReminderMessage { get; set; }
        public string Reference { get; set; }
        public DateTime RequestDate { get; set; }
        public string TypeOfRequest { get; set; }
        public string Status { get; set; }
        public string FaiedlMessage { get; set; }
        public DateTime? DueDate { get; set; }
        public bool? IsHighPriority { get; set; }
    }
}