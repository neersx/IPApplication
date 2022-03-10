using System.ComponentModel;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    /// <summary>
    ///     This class shows an example of how to handle translation in picklist. More importantly all sorting, paging and
    ///     filtering are executed in database rather than in-memory.
    /// </summary>
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/numbertypes")]
    public class NumberTypesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public NumberTypesPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route]
        public PagedResults<NumberTypesPicklistItem> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            var results = _dbContext.Set<NumberType>().Select(_ => new
                                                                   {
                                                                       _.NumberTypeCode,
                                                                       Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                                                       RelatedEvent = _.RelatedEvent != null ? DbFuncs.GetTranslation(_.RelatedEvent.Description, null, _.RelatedEvent.DescriptionTId, culture) : string.Empty,
                                                                       _.IssuedByIpOffice
                                                                   })
                                    .Select(_ => new {_.NumberTypeCode, _.Name, _.RelatedEvent, _.IssuedByIpOffice, IsExactMatch = (_.NumberTypeCode == search) || (_.Name == search)});

            if (!string.IsNullOrEmpty(search))
                results = results.Where(_ => _.NumberTypeCode.Contains(search) || _.Name.Contains(search));

            results = results.OrderByDescending(_ => _.IsExactMatch).ThenBy(_ => _.Name).ThenBy(_ => _.NumberTypeCode);

            return Helpers.GetPagedResults(results.Select(_ => new NumberTypesPicklistItem
                                                                   {
                                                                       Code = _.NumberTypeCode,
                                                                       Value = _.Name,
                                                                       RelatedEvent = _.RelatedEvent,
                                                                       IssuedByIpOffice = _.IssuedByIpOffice
                                                                   }),
                                           queryParameters,
                                           x => x.Code, x => x.Value, search);
        }

        public class NumberTypesPicklistItem
        {
            [PicklistKey]
            public string Key
            {
                get { return Code; }
            }

            [PicklistCode]
            [DisplayOrder(1)]
            public string Code { get; set; }

            [DisplayName(@"Description")]
            [PicklistDescription]
            [DisplayOrder(0)]
            public string Value { get; set; }

            [DisplayName(@"RelatedEvent")]
            [PicklistColumn]
            [DisplayOrder(2)]
            public string RelatedEvent { get; set; }

            [DisplayName(@"IssuedByIpOffice")]
            [PicklistColumn]
            [DisplayOrder(3)]
            public bool IssuedByIpOffice { get; set; }
        }
    }
}