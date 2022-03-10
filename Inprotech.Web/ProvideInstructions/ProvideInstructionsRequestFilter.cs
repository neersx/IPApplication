using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.ProvideInstructions
{
    public class ProvideInstructionsRequestFilter : SearchRequestFilter
    {
        public ColumnFilterCriteria ColumnFilterCriteria { get; set; }
    }

    public class ColumnFilterCriteria
    {
        public ProvideInstructions ProvideInstructions { get; set; }
    }

    public class ProvideInstructions
    {
        public AvailabilityFlags AvailabilityFlags { get; set; }

        public DueEvent DueEvent { get; set; }
    }
    
    public class AvailabilityFlags
    {
        public bool IsDueEvent { get; set; }
    }

    public class DueEvent
    {
        public int CaseKey { get; set; }

        public int EventKey { get; set; }

        public short Cycle { get; set; }
    }
}
