using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration.Rules.Workflow
{
    public static class WorkflowEventReferenceSearchCommand
    {
        public const string Command = "ipw_WorkflowEventReferenceSearch";

        public static IEnumerable<WorkflowEventReferenceListItem> WorkflowEventReferenceSearch(
            this IDbContext dbContext,
            int criteriaId,
            int eventId
            )
        {
            return DbContextHelpers.ExecuteSqlQuery<WorkflowEventReferenceListItem>(
                dbContext,
                Command,
                criteriaId,
                eventId
                );
        }
    }

    public class WorkflowEventReferenceListItem
    {
        public int EventId { get; protected set; }
    }
}