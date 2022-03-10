using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public static class ListTextTypeCommand
    {
        public const string Command = "ipw_ListTextTypes";

        public static IEnumerable<TextTypeListItem> GetTextTypes(this IDbContext dbContext, int userIdentityId, string culture, bool? caseOnly = null)
        {
            return DbContextHelpers.ExecuteSqlQuery<TextTypeListItem>(dbContext, Command,
                                                                      null, /* row count */
                                                                      userIdentityId,
                                                                      culture,
                                                                      0, /* centura */
                                                                      null, /* external user */
                                                                      caseOnly);
        }
    }
}