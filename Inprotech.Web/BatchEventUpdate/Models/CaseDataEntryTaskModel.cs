using System.Collections.Generic;
using System.Runtime.Serialization;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class CaseDataEntryTaskModel
    {
        public CaseDataEntryTaskModel()
        {
            Initialize();
        }

        public int CaseId { get; set; }

        public string ConfirmationPassword { get; set; }

        public short ControllingCycle { get; set; }

        public KeyValuePair<string, string>[] Data { get; set; }

        public bool AreWarningsConfirmed { get; set; }

        public int[] SanityCheckResultIds { get; set; }

        [OnDeserializing]
        void OnDeserializing(StreamingContext streamingContext)
        {
            Initialize();
        }

        void Initialize()
        {
            Data = new KeyValuePair<string, string>[0];
        }
    }
}