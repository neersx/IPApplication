using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/JurisdictionAttributeTypes")]
    public class JurisdictionAttributeTypePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _defaultQueryParameters;

        public JurisdictionAttributeTypePicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
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

            var attributeTypes = _dbContext.Set<SelectionTypes>()
                                           .Where(_ => _.ParentTable == KnownParentTable.Country)
                                           .Select(_ => new
                                           {
                                               Key = _.TableType.Id,
                                               Value = DbFuncs.GetTranslation(_.TableType.Name, null, _.TableType.NameTId, culture)
                                           });  

            var results = Helpers.GetPagedResults(attributeTypes,
                                                  extendedQueryParams,
                                                  null, x => x.Value, search);
            return results;
        }
    }
}
