using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public static class ListValidStatusCommand
    {
        public const string Command = "ipw_ListValidStatus";

        public static IEnumerable<ValidStatusListItem> GetValidStatuses(
            this IDbContext dbContext,
            int userId,
            string culture,
            bool? isRenewal)
        {
            // this method does not populate all the other properties within ValidStatusListItem.
            // Use with caution.

            return DbContextHelpers.ExecuteSqlQuery<ValidStatusListItem>(
                                                                         dbContext,
                                                                         Command,
                                                                         null,
                                                                         userId,
                                                                         culture,
                                                                         false,
                                                                         isRenewal);
        }
    }
}