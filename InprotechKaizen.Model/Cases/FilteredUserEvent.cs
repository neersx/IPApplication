namespace InprotechKaizen.Model.Cases
{
    public class FilteredUserEvent
    {
        public int EventNo { get; set; }

        public string EventCode { get; set; }

        public string EventDescription { get; set; }

        public short? NumCyclesAllowed { get; set; }

        public string ImportanceLevel { get; set; }

        public string ControllingAction { get; set; }

        public string Definition { get; set; }
    }
}