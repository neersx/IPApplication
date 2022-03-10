using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.GoogleAnalytics
{
    [Table("ServerAnalyticsData")]
    public class ServerAnalyticsData
    {
        [Key]
        public long Id { get; set; }

        public string Event { get; set; }
        public string Value { get; set; }
        public DateTime LastSent { get; set; }
    }
}