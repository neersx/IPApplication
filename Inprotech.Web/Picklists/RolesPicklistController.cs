using System.ComponentModel;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/roles")]
    public class RolesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _queryParameters;

        public RolesPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
        }

        [HttpGet]
        [Route]
        public PagedResults<RolesPicklistItem> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var results = _dbContext.Set<Role>().Select(_ => new RolesPicklistItem
            {
                                                                     Key = _.Id,
                                                                     Value = DbFuncs.GetTranslation(_.RoleName, null, _.RoleNameTId, culture),
                                                                     IsExternal = _.IsExternal == true
            });

            if (!string.IsNullOrEmpty(search))
                results = results.Where(_ => _.Value.Contains(search));

            return Helpers.GetPagedResults(results,
                                           extendedQueryParams,
                                           null, x => x.Value, search);
        }

        public class RolesPicklistItem
        {
            [PicklistKey]
            public int Key { get; set; }
            
            [DisplayName(@"Description")]
            [PicklistDescription]
            [DisplayOrder(0)]
            public string Value { get; set; }

            public bool IsExternal { get; set; }
        }
    }
}