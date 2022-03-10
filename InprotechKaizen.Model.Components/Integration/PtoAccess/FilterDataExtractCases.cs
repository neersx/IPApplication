using System;
using System.Linq;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Integration.PtoAccess
{
    public interface IFilterDataExtractCases
    {
        IQueryable<EligibleCaseItem> For(string externalSystemCodes, params int[] caseIds);
    }
    
    public class FilterDataExtractCases : IFilterDataExtractCases
    {
        readonly IDbContext _dbContext;

        public FilterDataExtractCases(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<EligibleCaseItem> For(string externalSystemCodes, params int[] caseIds)
        {
            if (externalSystemCodes == null) throw new ArgumentNullException(nameof(externalSystemCodes));

            return from e in _dbContext.FilterEligibleCasesForComparison(externalSystemCodes)
                   where caseIds.Contains(e.CaseKey)
                   select e;
        }
    }
}