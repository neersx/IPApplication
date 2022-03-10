using System;
using Inprotech.Contracts.Messages;

namespace Inprotech.Integration.ApplyRecordal
{
    public class ApplyRecordalArgs : Message
    {
        public int RunBy { get; set; }
        public string Culture { get; set; }
        public int RecordalCase { get; set; }
        public DateTime RecordalDate { get; set; }
        public string RecordalStatus { get; set; }
        public string RecordalSeqIds { get; set; }
        public string SuccessMessage { get; set; }
        public string ErrorMessage { get; set; }
    }
}
