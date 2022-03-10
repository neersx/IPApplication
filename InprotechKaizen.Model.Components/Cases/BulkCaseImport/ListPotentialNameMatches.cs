using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.BulkCaseImport
{
    public static class ListPotentialNameMatches
    {
        public const string Command = "ede_ListPotentialNameMatch";

        public static IEnumerable<PotentialNameMatchItem> GetPotentialNameMatches(
            this IDbContext dbContext,
            int userId,
            string culture,
            string name,
            string givenName,
            int? restrictToOffice,
            bool? useStreetAddress,
            bool? removeNoiseChars,
            string restrictByNameType)
        {
            return DbContextHelpers.ExecuteSqlQuery<PotentialNameMatchItem>(
                dbContext,
                Command,
                userId,
                culture,
                name,
                givenName,
                restrictToOffice,
                useStreetAddress,
                removeNoiseChars,
                (int?) null,
                restrictByNameType);
        }
    }
}