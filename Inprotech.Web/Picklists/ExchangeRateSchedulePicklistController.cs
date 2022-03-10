using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/exchangeRateSchedule")]
    public class ExchangeRateSchedulePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public ExchangeRateSchedulePicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _queryParameters = new CommonQueryParameters { SortBy = "Id" };
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(ExchangeRateSchedule))]
        public PagedResults ExchangeRateSchedule([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var culture = _preferredCultureResolver.Resolve();

            IEnumerable<ExchangeRateSchedulePicklistItem> result = _dbContext.Set<ExchangeRateSchedule>()
                                    .Select(_ => new ExchangeRateSchedulePicklistItem
                                    {
                                        Id = _.Id,
                                        Code = _.ExchangeScheduleCode,
                                        Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture) ?? string.Empty
                                    }).ToArray();
            
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
        public class ExchangeRateSchedulePicklistItem
        {
            [PicklistKey]
            public int Id { get; set; }
            [PicklistCode]
            public string Code { get; set; }
            [PicklistDescription]
            public string Description { get; set; }
        }
    }
}