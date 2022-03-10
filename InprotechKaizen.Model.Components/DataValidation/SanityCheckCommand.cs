using System.Collections.Generic;
using System.Data;
using System.Linq;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DataValidation
{
    public static class SanityCheckCommand
    {
        public const string Command = StoredProcedures.RunSanityCheck;

        public static int ApplySanityCheck(this IDbContext dbContext, List<int> caseIds, int identityId, string culture)
        {
            var parameters = new object[]
            {
                identityId,culture,
                "C",
                null,
                null,
                null,0,0,string.Join(",", caseIds)
            };
            return DbContextHelpers.ExecuteSqlQuery(dbContext, PopulateResult, Command, parameters).FirstOrDefault();
        }

        static int PopulateResult(IDataReader dr)
        {
            int result = (int)dr[0];
            return result;
        }
    }
}
