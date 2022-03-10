using System.Collections.Generic;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Configuration.Rules.Checklists;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Rules.Checklists
{
    public interface IChecklistConfigurationSearch
    {
        public IEnumerable<ChecklistConfigurationItem> Search(SearchCriteria filter);
        public IEnumerable<ChecklistConfigurationItem> Search(int[] ids);
    }

    public class ChecklistConfigurationSearch : IChecklistConfigurationSearch
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public ChecklistConfigurationSearch(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _securityContext = securityContext;
        }

        public IEnumerable<ChecklistConfigurationItem> Search(SearchCriteria filter)
        {
            return _dbContext.ChecklistConfigurationSearch(_securityContext.User.Id, _preferredCultureResolver.Resolve(), filter);
        }

        public IEnumerable<ChecklistConfigurationItem> Search(int[] ids)
        {
            return _dbContext.ChecklistConfigurationSearchByIds(_securityContext.User.Id, _preferredCultureResolver.Resolve(), ids);
        }
    }
}
