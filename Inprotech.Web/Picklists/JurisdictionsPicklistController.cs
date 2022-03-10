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
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
 
    [NoEnrichment]
    [RoutePrefix("api/picklists/jurisdictions")]
    public class JurisdictionsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _queryParameters;

        public JurisdictionsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;

            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Jurisdiction), ApplicationTask.MaintainJurisdiction)]
        [PicklistMaintainabilityActions(ApplicationTask.ViewJurisdiction, allowDelete: false, allowDuplicate: false, allowAdd: false)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route("{jurisdictionId}")]
        [PicklistPayload(typeof(Jurisdiction), ApplicationTask.MaintainJurisdiction)]
        [PicklistMaintainabilityActions(ApplicationTask.ViewJurisdiction, allowDelete: false, allowDuplicate: false, allowAdd: false)]
        public Jurisdiction Jurisdiction(string jurisdictionId)
        {
            var jurisdiction = _dbContext.Set<Country>().Single(_ => _.Id == jurisdictionId);
            return new Jurisdiction { Code = jurisdiction.Id, Value = jurisdiction.Name };
        }

        [Route("~/api/lists/jurisdictions")]
        [HttpGet]
        public IEnumerable<dynamic> List(string q)
        {
            return from j in Jurisdictions(search: q).Data
                   select new
                   {
                       ((Jurisdiction)j).Key,
                       Name = ((Jurisdiction)j).Value
                   };
        }

        [Route]
        [HttpGet]
        [PicklistPayload(typeof(Jurisdiction))]
        public PagedResults Jurisdictions(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", bool isGroup = false, string excludeCountry = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search, isGroup, excludeCountry),
                                           extendedQueryParams,
                                           x => x.Code,
                                           x => x.Value,
                                           search);
        }

        IEnumerable<Jurisdiction> MatchingItems(string search = "", bool isGroup = false, string excludeCountry = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            var countries = _dbContext.Set<Country>().AsQueryable();

            if (isGroup) countries = countries.Where(c => c.Type == "1");

            if (!string.IsNullOrEmpty(excludeCountry)) countries = countries.Where(c => c.Id != excludeCountry);

            var interim = from j in countries
                          select new Jurisdiction
                          {
                              Code = j.Id,
                              Value = DbFuncs.GetTranslation(j.Name, null, j.NameTId, culture),
                              IsGroup = j.Type == "1",
                              IsCeased = j.DateCeased.HasValue && (DateTime.Compare(j.DateCeased.Value, DateTime.Today) <= 0) 
                          };

            return !string.IsNullOrEmpty(search)
                ? interim.Where(_ => _.Code.Contains(search) ||
                                     _.Value.Contains(search))
                : interim;
        }
    }

    public class Jurisdiction
    {
        [PicklistKey]
        public string Key => Code;

        [DisplayName("Code")]
        [PicklistCode]
        [MaxLength(3)]
        [DisplayOrder(1)]
        public string Code { get; set; }

        [Required]
        [MaxLength(60)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        [DisplayOrder(2)]
        public bool IsGroup { get; set; }

        public bool IsCeased { get; set; }
    }
}