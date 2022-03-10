using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;
using Program = InprotechKaizen.Model.Security.Program;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists")]
    public class ProgramPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControlReader;

        public ProgramPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControlReader = siteControlReader;
        }

        [HttpGet]
        [Route("program")]
        public async Task<PagedResults<ProgramPicklistItem>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                           CommonQueryParameters queryParameters = null, string search = "", string programGroup = "")
        {
            var culture = _preferredCultureResolver.Resolve();

            var screenControlName = _siteControlReader.Read<string>(SiteControls.CRMScreenControlProgram) ?? string.Empty;
            var query = search ?? string.Empty;
            var interimResult = await (from p in _dbContext.Set<Program>().Include(p => p.ParentProgram)
                                       where (p.Id.Contains(query) || p.Name.Contains(query)) &&
                                               p.Id != screenControlName &&
                                               ((p.ProgramGroup ?? string.Empty).Equals(programGroup) ||
                                               (p.ParentProgram != null && (p.ParentProgram.ProgramGroup ?? string.Empty).Equals(programGroup)))
                                       select new
                                       {
                                           Name = DbFuncs.GetTranslation(p.Name, null, p.Name_TID, culture),
                                           p.Id,
                                           ParentProgramName = p.ParentProgram != null ? DbFuncs.GetTranslation(p.ParentProgram.Name, null, p.ParentProgram.Name_TID, culture) : null
                                       }).ToArrayAsync();
            var results = from r in interimResult
                          let isContains = r.Name.IgnoreCaseContains(query) || r.Id.IgnoreCaseContains(query)
                          let isStartsWith = r.Name.IgnoreCaseStartsWith(query) || r.Id.IgnoreCaseStartsWith(query)
                          orderby isStartsWith descending, isContains descending, r.Name
                          select new ProgramPicklistItem
                          {
                              Key = r.Id,
                              Value = r.Name,
                              ParentName = r.ParentProgramName
                          };

            return results.AsPagedResults(CommonQueryParameters.Default.Extend(queryParameters));
        }

        public class ProgramPicklistItem
        {
            [PicklistKey]
            public string Key { get; set; }

            [PicklistDescription]
            public string Value { get; set; }

            public string ParentName { get; set; }
        }
    }
}