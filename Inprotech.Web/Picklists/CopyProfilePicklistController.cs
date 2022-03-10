using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/CopyProfiles")]
    public class CopyProfilePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _defaultQueryParameters;

        public CopyProfilePicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _defaultQueryParameters = CommonQueryParameters.Default.Extend(new CommonQueryParameters { SortBy = "Value" });
        }

        [HttpGet]
        [Route]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _defaultQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var culture = _preferredCultureResolver.Resolve();

            var copyProfilesCrm = _dbContext.Set<CopyProfile>()
                                            .Where(_ => _.CrmOnly).Select(_ => _.ProfileName).Distinct().ToList();

            var copyProfiles = _dbContext.Set<CopyProfile>()
                                           .Where(_ => !_.CrmOnly && !copyProfilesCrm.Contains(_.ProfileName))
                                           .Select(_ => new
                                           {
                                               Key = _.ProfileName,
                                               Value = DbFuncs.GetTranslation(_.ProfileName, null, _.ProfileNameTId, culture)
                                           }).Distinct();  

            var results = Helpers.GetPagedResults(copyProfiles,
                                                  extendedQueryParams,
                                                  null, x => x.Value, search);
            return results;
        }
    }
}
