using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using System.Data.Entity;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;

namespace Inprotech.Web.Search
{
    public interface ISavedSearchValidator
    {
        Task<bool> ValidateQueryExists(QueryContext queryContext, int queryKey, bool savedSearch = false);
    }
    public class SavedSearchValidator : ISavedSearchValidator
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public SavedSearchValidator(IDbContext dbContext, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public async Task<bool> ValidateQueryExists(QueryContext queryContext, int queryKey, bool savedSearch = false)
        {
            var user = _securityContext.User;
            var accessAccountId = user.IsExternalUser ? user.AccessAccount?.Id : null;
            if (!await _dbContext.Set<Query>().AnyAsync(_ => _.Id == queryKey
                                                             && _.ContextId == (int) queryContext
                                                             && (!_.IsClientServer || savedSearch)
                                                             && (_.IdentityId == null && _.AccessAccountId == null
                                                                 || _.IdentityId == user.Id
                                                                 || _.AccessAccountId != null && _.AccessAccountId == accessAccountId
                                                                 || user.IsExternalUser && _.IsPublicToExternal)))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            return true;
        }
    }
}
