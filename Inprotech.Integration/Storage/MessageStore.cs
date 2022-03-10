using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Storage
{
    [Table("MessageStore")]
    public class MessageStore
    {
        [Key]
        public long Id { get; set; }

        public string ServiceId { get; set; }
        public string ServiceType { get; set; }
        public DateTime MessageTimestamp { get; set; }
        public string MessageStatus { get; set; }
        public string MessageText { get; set; }
        public string MessageTransactionId { get; set; }
        public string LinkFileName { get; set; }
        public string LinkStatus { get; set; }
        public string LinkApplicationId { get; set; }
        public string MessageData { get; set; }
        public long ProcessId { get; set; }
    }
}