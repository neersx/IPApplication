using System.Collections.Generic;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Integration.PtoAccess
{
    public static class FindPrivatePairCaseMatches
    {
        public const string Command = "apps_FindPrivatePairCaseMatches";

        public static IEnumerable<PrivatePairCaseMatch> FindPrivatePairCaseMatchesMatches(
            this IDbContext dbContext,
            string systemCode,
            string privatePairCases)
        {
            return DbContextHelpers.ExecuteSqlQuery<PrivatePairCaseMatch>(dbContext, Command, systemCode, privatePairCases);
        }
    }

    public class PrivatePairCaseMatch
    {
        public int PrivatePairCaseKey { get; set; }
        public int CaseKey { get; set; }
    }
}