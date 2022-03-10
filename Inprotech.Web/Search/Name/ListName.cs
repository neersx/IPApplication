using System.Collections.Generic;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Name
{
    public interface IListName
    {
        IEnumerable<NameListItem> Get(out int rowCount, string search, string filterNameType, EntityTypes forEntityTypes, bool? showCeased, string sortBy,
            string sortDir, int? skip, int? take, int? associatedNameId = null, bool buildDisplayNameCode = false);

        IEnumerable<NameListItem> GetSpecificNames(out int rowCount, string search, EntityTypes forEntityTypes, List<int> nameKeys, string sortBy,
                                                   string sortDir, int? skip, int? take, bool buildDisplayNameCode = false);
    }

    public class ListName : IListName
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public ListName(IDbContext dbContext, ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _dbContext = dbContext;
        }

        public IEnumerable<NameListItem> Get(out int rowCount, string search, string filterNameType, EntityTypes forEntityTypes, bool? showCeased, string sortBy,
            string sortDir, int? skip, int? take, int? associatedNameId = null, bool buildDisplayNameCode = false)
        {  
            return _dbContext.GetNamesForPickList(out rowCount, _securityContext.User.Id,
                _preferredCultureResolver.Resolve(), search, filterNameType, forEntityTypes, showCeased, sortBy, sortDir, skip, take, associatedNameId, buildDisplayNameCode);
        }

        public IEnumerable<NameListItem> GetSpecificNames(out int rowCount, string search, EntityTypes forEntityTypes, List<int> nameKeys, string sortBy,
                                             string sortDir, int? skip, int? take, bool buildDisplayNameCode = false)
        {  
            return _dbContext.GetSpecificNamesForPicklist(out rowCount, _securityContext.User.Id,
                                                  _preferredCultureResolver.Resolve(), search, forEntityTypes, nameKeys, sortBy, sortDir, skip, take, buildDisplayNameCode);
        }
    }

}