using InprotechKaizen.Model.TaskPlanner;

namespace Inprotech.Tests.Web.Builders.Model.TaskPlanner
{
    public class TaskPlannerTabsByProfileBuilder : IBuilder<TaskPlannerTabsByProfile>
    {
        public int? ProfileId { get; set; }

        public int TabSequence { get; set; }

        public int QueryId { get; set; }
        
        public bool IsLocked { get; set; }

        public TaskPlannerTabsByProfile Build()
        {
            ProfileId = ProfileId;
            TabSequence = TabSequence;
            QueryId = QueryId;
            return new TaskPlannerTabsByProfile(ProfileId, QueryId, TabSequence) { IsLocked = IsLocked };
        }
    }
}