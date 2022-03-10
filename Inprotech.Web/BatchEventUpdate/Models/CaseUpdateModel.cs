using System;
using System.Runtime.Serialization;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class CaseUpdateModel
    {
        public CaseUpdateModel()
        {
            Initialize();
        }

        public int Id { get; set; }

        public string OfficialNumber { get; set; }

        public Miscellaneous.AvailableEventModel[] AvailableEvents { get; set; }

        public int? FileLocationId { get; set; }

        public DateTime WhenMovedToLocation { get; set; }

        [OnDeserializing]
        void OnDeserializing(StreamingContext streamingContext)
        {
            Initialize();
        }

        void Initialize()
        {
            AvailableEvents = new Miscellaneous.AvailableEventModel[0];
        }
    }
}