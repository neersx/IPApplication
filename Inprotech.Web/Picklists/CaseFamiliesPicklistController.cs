using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/CaseFamilies")]
    public class CaseFamiliesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public CaseFamiliesPicklistController(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(CaseFamily))]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        public PagedResults Get([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                CommonQueryParameters queryParameters
                                    = null, string search = "", string mode = "all")
        {
            var userId = _securityContext.User.Id;
            var isExternal = _securityContext.User.IsExternalUser;
            var culture = _preferredCultureResolver.Resolve();
            var cases = isExternal
                ? from c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                  join fc in _dbContext.FilterUserCases(userId, true) on c.Id equals fc.CaseId
                  where c.Family != null
                  select c
                : from c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                  where c.Family != null
                  select c;

            var families = from f in _dbContext.Set<Family>()
                           join c in cases.GroupBy(_ => _.FamilyId).Select(x => x.FirstOrDefault()) on f.Id equals c.FamilyId into c1
                           from c in c1.DefaultIfEmpty()
                           select new CaseFamily
                           {
                               Key = f.Id,
                               Value = DbFuncs.GetTranslation(f.Name, null, f.NameTId, culture),
                               InUse = c != null
                           };

            if (isExternal)
            {
                families = families.Where(_ => _.InUse);
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                families = families.Where(_ => _.Key == search ||
                                               _.Value.Contains(search));
            }

            return Helpers.GetPagedResults(families,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Key, x => x.Value, search);
        }
    }

    public class CaseFamily
    {
        [PicklistKey]
        [DisplayName("key")]
        [DisplayOrder(0)]
        public string Key { get; set; }

        [DisplayName("description")]
        [DisplayOrder(1)]
        public string Value { get; set; }

        [DataType("boolean")]
        [DisplayName("inUse")]
        [DisplayOrder(2)]
        public bool InUse { get; set; }
    }
}