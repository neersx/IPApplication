using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
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
    public class StatesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _queryParameters;

        public StatesPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;

            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(State))]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [PicklistPayload(typeof(State))]
        [Route("api/configuration/picklists/states")]
        public PagedResults States(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", string country = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search, country),
                                           extendedQueryParams,
                                           x => x.Code,
                                           x => x.Value,
                                           search);
        }

        IEnumerable<State> MatchingItems(string search = "", string countryCode = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            var states = String.IsNullOrEmpty(countryCode) ? _dbContext.Set<InprotechKaizen.Model.Names.State>().ToArray() :
                _dbContext.Set<InprotechKaizen.Model.Names.State>().Where(s => s.CountryCode == countryCode).ToArray();

            var interim = from s in states
                          select new State
                          {
                              Code = s.Code,
                              Value = DbFuncs.GetTranslation(s.Name, null, s.NameTId, culture),
                              CountryCode = s.CountryCode,
                              CountryDescription = s.Country.Name
                          };

            return !string.IsNullOrEmpty(search)
                ? interim.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) ||
                                     _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1)
                : interim;
        }
    }

    public class State
    {
        [PicklistKey]
        public string Key => Code;

        [DisplayName("Code")]
        [PicklistCode]
        [MaxLength(20)]
        [DisplayOrder(1)]
        public string Code { get; set; }

        [Required]
        [MaxLength(40)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        public string CountryCode { get; set; }

        public string CountryDescription { get; set; }
    }
}
