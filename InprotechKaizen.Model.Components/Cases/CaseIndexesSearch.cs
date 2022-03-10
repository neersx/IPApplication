using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface ICaseIndexesSearch
    {
        IEnumerable<int> Search(string searchText, params CaseIndexSource[] caseIndexSources);
    }

    public class CaseIndexesSearch : ICaseIndexesSearch
    {
        readonly IDbContext _dbContext;

        public CaseIndexesSearch(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }
        public IEnumerable<int> Search( string searchText, params CaseIndexSource[] caseIndexSources)
            {
                return _dbContext.Set<CaseIndexes>()
                          .Where(_ => caseIndexSources.Contains(_.Source))
                          .Where(_ => _.GenericIndex.Contains(searchText))
                          .Select(_ => _.CaseId)
                          .Distinct();
            }
    }
}
