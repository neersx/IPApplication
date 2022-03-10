using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.GoogleAnalytics
{
    [Table("ServerTransactionalDataSink")]
    public class ServerTransactionalDataSink
    {
        [Key]
        public long Id { get; set; }

        public string Event { get; set; }

        public string Value { get; set; }

        public DateTime Entered { get; set; }
    }
}