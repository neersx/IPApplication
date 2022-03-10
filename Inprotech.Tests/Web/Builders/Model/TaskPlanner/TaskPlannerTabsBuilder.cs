using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Common;
using InprotechKaizen.Model.TaskPlanner;

namespace Inprotech.Tests.Web.Builders.Model.TaskPlanner
{
    public class TaskPlannerTabsBuilder : IBuilder<TaskPlannerTab>
    {
        readonly InMemoryDbContext _db;

        public TaskPlannerTabsBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public int? IdentityId { get; set; }

        public int TabSequence { get; set; }

        public int QueryId { get; set; }

        public TaskPlannerTab Build()
        {
            var query = new QueryBuilder
            {
                SearchName = "Test Saved Search", 
                Description = "Test Saved Search", 
                ContextId = (int)QueryContext.TaskPlanner
            }.Build().In(_db);
            IdentityId = null;
            TabSequence = Fixture.Integer();
            QueryId = query.Id;
            return new TaskPlannerTab(QueryId, TabSequence, IdentityId);
        }

        public TaskPlannerTab Build(int queryId, int tabSequence, int? identityId)
        {
            return new TaskPlannerTab(queryId, tabSequence, identityId);
        }
    }
}