namespace Inprotech.Web.Configuration.TaskPlanner
{
    public class TaskPlannerTabConfigItem
    {
        public int? Id { get; set; }
        public ProfileData Profile { get; set; }
        public QueryData Tab1 { get; set; }
        public bool Tab1Locked { get; set; }
        public QueryData Tab2 { get; set; }
        public bool Tab2Locked { get; set; }
        public QueryData Tab3 { get; set; }
        public bool IsDeleted { get; set; }
        public bool Tab3Locked { get; set; }
    }

    public class QueryData
    {
        public int Key { get; set; }
        public string SearchName { get; set; }
        public string Description { get; set; }

        public bool IsPublic { get; set; }

        public int TabSequence { get; set; }
        public int? PresentationId { get; set; }
    }

    public class ProfileData
    {
        public int Key { get; set; }
        public int Code => Key;
        public string Name { get; set; }
    }
}
