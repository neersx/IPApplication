namespace InprotechKaizen.Model.Components.Cases.PostModificationTasks
{
    public class AvailableEventToConsider
    {
        public AvailableEventToConsider(int eventId, short cycle)
        {
            EventId = eventId;
            Cycle = cycle;
        }

        public int EventId { get; private set; }
        public short Cycle { get; private set; }
    }
}