namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class EventsRequestModel
    {
        public long TempStorageId { get; set; }

        public int CriteriaId { get; set; }

        public int DataEntryTaskId { get; set; }

        public bool? UseNextCycle { get; set; }

        public short? ActionCycle { get; set; }
    }
}