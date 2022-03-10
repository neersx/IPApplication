using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Queries
{
    public static class ListSavedQueriesCommand
    {
        public const string Command = "qr_ListQueries";

        public static IEnumerable<SavedQueryItem> GetSavedQueries(
            this IDbContext dbContext,
            int userId,
            string culture,
            int queryContextKey
            )
        {
            return DbContextHelpers.ExecuteSqlQuery<SavedQueryItem>(
                dbContext,
                Command,
                (int?) null,
                userId,
                culture,
                queryContextKey,
                false);
        }
    }
}