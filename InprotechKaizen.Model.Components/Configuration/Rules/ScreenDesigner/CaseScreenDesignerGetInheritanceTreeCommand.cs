using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner
{
    public static class CaseScreenDesignerGetInheritanceTreeCommand
    {
        public const string Command = "ipw_GetCaseScreenDesignerInheritanceTree";

        public static IEnumerable<CaseScreenDesignerInheritanceTree> GetCaseScreenDesignerInheritanceTree(
            this IDbContext dbContext,
            string culture,
            IEnumerable<int> criteriaIds
            )
        {
            return DbContextHelpers.ExecuteSqlQuery<CaseScreenDesignerInheritanceTree>(
                dbContext,
                Command,
                culture,
                string.Join(",", criteriaIds)
                );
        }
    }

    public class CaseScreenDesignerInheritanceTree
    {
        public string Tree { get; protected set; }
    }
}