using System.Runtime.Serialization;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class SaveBatchEventsModel
    {
        public SaveBatchEventsModel()
        {
            Initialize();
        }

        public bool AreWarningsConfirmed { get; set; }

        public int CriteriaId { get; set; }

        public short DataEntryTaskId { get; set; }

        public CaseDataEntryTaskModel[] Cases { get; set; }

        public short? ActionCycle { get; set; }

        [OnDeserializing]
        void OnDeserializing(StreamingContext streamingContext)
        {
            Initialize();
        }

        void Initialize()
        {
            Cases = new CaseDataEntryTaskModel[0];
        }
    }
}