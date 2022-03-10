using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration.Rules.Workflow
{
    public static class WorkflowGetInheritanceTreeCommand
    {
        public const string Command = "ipw_GetWorkflowInheritanceTree";

        public static IEnumerable<WorkflowInheritanceTree> GetWorkflowInheritanceTree(
            this IDbContext dbContext,
            string culture,
            IEnumerable<int> criteriaIds
            )
        {
            return DbContextHelpers.ExecuteSqlQuery<WorkflowInheritanceTree>(
                dbContext,
                Command,
                culture,
                string.Join(",", criteriaIds)
                );
        }
    }

    public class WorkflowInheritanceTree
    {
        public string Tree { get; protected set; }
    }
}