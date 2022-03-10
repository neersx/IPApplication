using System.ComponentModel;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists")]
    public class ProfilePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public ProfilePicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route("profile")]
        public async Task<PagedResults<ProfilePicklistItem>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                           CommonQueryParameters queryParameters = null, string search = "")
        {
            var query = search ?? string.Empty;
            var culture = _preferredCultureResolver.Resolve();

            var interimResult = from p in _dbContext.Set<Profile>()
                                let name = DbFuncs.GetTranslation(p.Name, null, null, culture)
                                let description = DbFuncs.GetTranslation(p.Description, null, null, culture)
                                where name.Contains(query) || p.Description.Contains(query)
                                select new
                                {
                                    Name = name,
                                    p.Id,
                                    Description = description
                                };

            var results = from r in await interimResult.ToArrayAsync()
                          let isContains = r.Name.IgnoreCaseContains(query) || r.Description.IgnoreCaseContains(query)
                          let isStartsWith = r.Name.IgnoreCaseStartsWith(query) || r.Description.IgnoreCaseStartsWith(query)
                          orderby isStartsWith descending, isContains descending, r.Name
                          select new ProfilePicklistItem
                          {
                              Key = r.Id,
                              Name = r.Name,
                              Description = r.Description
                          };

            return results.AsPagedResults(CommonQueryParameters.Default.Extend(queryParameters));
        }

        public class ProfilePicklistItem
        {
            [PicklistKey]
            public int Key { get; set; }

            [PicklistDescription]
            public string Name { get; set; }

            [DisplayName(@"Description")]
            public string Description { get; set; }
        }
    }
}