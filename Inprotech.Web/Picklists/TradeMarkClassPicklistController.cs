using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
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
    [RoutePrefix("api/picklists/tmclass")]
    public class TradeMarkClassPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        const string SortByClassField = "code";

        public TradeMarkClassPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver ?? throw new ArgumentNullException(nameof(preferredCultureResolver));
            _queryParameters = new CommonQueryParameters { SortBy = "code" };
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(TradeMarkClass))]
        public PagedResults TradeMarkClass([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", string propertyTypeCode = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            var interim = _dbContext.Set<InprotechKaizen.Model.Configuration.TmClass>()
                            .Where(_ => _.CountryCode == "ZZZ" && (propertyTypeCode == null || propertyTypeCode == string.Empty || _.Property.Code == propertyTypeCode)).ToArray();

            var result = interim.Select(_ => new TradeMarkClass
            {
                Key = _.Id,
                Code = _.Class,
                Value = DbFuncs.GetTranslation(_.Heading, null, _.HeadingTId, culture) ?? string.Empty
            });

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ =>
                                          string.Equals(_.Code, search, StringComparison.InvariantCultureIgnoreCase) ||
                                          _.Code.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 ||
                                          _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return Helpers.GetPagedResults(result, queryParameters ?? new CommonQueryParameters(), x => x.Code, x => x.Value, search);
        }
    }

    public class TradeMarkClass
    {
        [PicklistKey]
        public int Key { get; set; }

        [PicklistCode]
        [DisplayOrder(0)]
        public string Code { get; set; }

        [PicklistDescription]
        [DisplayOrder(1)]
        public string Value { get; set; }
    }
}
