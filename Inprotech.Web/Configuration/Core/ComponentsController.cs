using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [NoEnrichment]
    public class ComponentsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ICommonQueryService _commonQueryService;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        static readonly CommonQueryParameters DefaulQueryParameters =
        CommonQueryParameters.Default.Extend(new CommonQueryParameters
        {
            SortBy = "ComponentName" // Overwrite sortBy which is default to 'id'
        });

        public ComponentsController(IDbContext dbContext, ICommonQueryService commonQueryService, IPreferredCultureResolver preferredCultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (dbContext == null) throw new ArgumentNullException("preferredCultureResolver");

            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _commonQueryService = commonQueryService;
        }

        [HttpGet]
        [Route("api/configuration/components")]
        public PagedResults Search(string search = "", [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            if (search == null)
                search = string.Empty;

            queryParameters = DefaulQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var components = _dbContext.Set<Component>()
                                       .Select(_ => new ComponentResult
                                                        {
                                                            Id = _.Id,
                                                            ComponentName = DbFuncs.GetTranslation(_.ComponentName, null, _.ComponentNameTId, culture)
                                                        });

            if (!string.IsNullOrWhiteSpace(search))
                components = components.Where(_ => _.ComponentName.Contains(search));

            return Helpers.GetPagedResults(components,
                                           queryParameters ?? new CommonQueryParameters(),
                                           null, x => x.ComponentName, search);
        }
    }

    public class ComponentResult
    {
        public int Id { get; set; }
        public string ComponentName { get; set; }
    }
}