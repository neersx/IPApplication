
namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor
{
    public class RunDocItemParams
    {
        public bool EmptyParamsAsNulls { get; set; }
        public bool SingleSpaceBookmarksAsNull { get; set; }
        public int CommandTimeout { get; set; } = 30;
        public bool ConcatNullYieldsNull { get; set; }
        public int DateStyle { get; set; } = 0;
    }
}