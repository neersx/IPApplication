using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/chargetypes")]
    public class ChargeTypesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        private readonly IPreferredCultureResolver _preferredCultureResolver;

        public ChargeTypesPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route]
        public PagedResults<ChargeTypeListItem> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            return Helpers.GetPagedResults(MatchingItems(search),
                                           queryParameters,
                                           null, x => x.Value, search);
        }

        IQueryable<ChargeTypeListItem> MatchingItems(string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            IQueryable<ChargeType> chargeTypes = _dbContext.Set<ChargeType>();

            if (!string.IsNullOrEmpty(search))
                chargeTypes = chargeTypes.Where(_ => _.Description.Contains(search));

            return chargeTypes.Select(_ => new ChargeTypeListItem
                                               {
                                                   Key = _.Id,
                                                   Value = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                               }).OrderBy(_ => _.Value);
        }

        public class ChargeTypeListItem
        {
            [PicklistKey]
            public int Key { get; set; }

            [PicklistDescription]
            [DisplayOrder(0)]
            public string Value { get; set; }
        }
    }
}
