namespace InprotechKaizen.Model.Integration.PtoAccess
{
    public class SourceMappedEvents
    {
        public string Code { get; set; }

        public int? MappedEventId { get; set; }

        public SourceMappedEvents()
        {
            
        }

        public SourceMappedEvents(string code, int? mappedEventId)
        {
            Code = code;
            MappedEventId = mappedEventId;
        }
    }
}
