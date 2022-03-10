using System.Collections.Generic;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using CaseListItem = InprotechKaizen.Model.Components.Cases.Search.CaseListItem;

namespace Inprotech.Web.Search.Case
{
    public interface IListCase
    {
        IEnumerable<CaseListItem> Get(out int rowCount, string search, string sortBy,
            string sortDir,
            int? skip,
            int? take,
            int? nameKey,
            bool? withInstructor = false, CaseSearchFilter searchFilter = null);
    }

    public class ListCase : IListCase
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public ListCase(IDbContext dbContext, ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _dbContext = dbContext;
        }

        public IEnumerable<CaseListItem> Get(out int rowCount, string search, string sortBy,
            string sortDir,
            int? skip,
            int? take,
            int? nameKey, bool? withInstructor = false, CaseSearchFilter searchFilter = null)
        {
            return _dbContext.GetCasesForPickList(out rowCount, _securityContext.User.Id,
                _preferredCultureResolver.Resolve(), search, sortBy, sortDir, skip, take, nameKey, withInstructor.GetValueOrDefault(), searchFilter);
        }
    }
}