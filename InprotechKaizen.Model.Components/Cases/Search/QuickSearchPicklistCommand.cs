using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Search
{
    public static class QuickSearchPicklistCommand
    {
        public const string Command = "csw_QuickSearchPicklist";

        public static IEnumerable<QuickSearchPicklistItem> QuickSearchPicklist(this IDbContext dbContext, string searchString, int identityId, int limit)
        {
            return DbContextHelpers.ExecuteSqlQuery<QuickSearchPicklistItem>(dbContext, Command, searchString, identityId, limit);
        }
    }
}
