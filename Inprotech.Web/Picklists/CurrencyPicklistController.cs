using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/currency")]
    public class CurrencyPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CurrencyPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _queryParameters = new CommonQueryParameters { SortBy = "Id" };
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(Currency))]
        public PagedResults Currency([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var culture = _preferredCultureResolver.Resolve();

            var interim = _dbContext.Set<InprotechKaizen.Model.Cases.Currency>().ToArray();

            var result = interim.Select(_ => new Currency
            {
                Id = _.Id,
                Code = _.Id,
                Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture) ?? string.Empty
            });

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ =>
                                          string.Equals(_.Code, search, StringComparison.InvariantCultureIgnoreCase) ||
                                          _.Code.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 ||
                                          _.Description.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return Helpers.GetPagedResults(result,
                                           extendedQueryParams ?? new CommonQueryParameters(),
                                           x => x.Code, x => x.Description, search);
        }
    }

    public class Currency
    {
        [PicklistKey]
        public string Id { get; set; }

        [PicklistCode]
        [DisplayOrder(0)]
        public string Code { get; set; }

        [PicklistDescription]
        [DisplayOrder(1)]
        public string Description { get; set; }

        public bool HasHistory { get; set; }
    }
}
