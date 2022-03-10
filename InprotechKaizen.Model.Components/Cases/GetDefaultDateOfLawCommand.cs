using System;
using System.Linq;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public static class GetDefaultDateOfLawCommand
    {
        public const string Command = "ipw_GetDefaultDateOfLaw";

        public static DateTime? GetDefaultDateOfLaw(this IDbContext dbContext, int caseId, string actionId)
        {
            return DbContextHelpers.ExecuteSqlQuery<DateTime?>(dbContext, Command, caseId, actionId).FirstOrDefault();
        }
    }
}
