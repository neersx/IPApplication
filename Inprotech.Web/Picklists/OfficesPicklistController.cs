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
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/offices")]
    public class OfficesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public OfficesPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");

            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;

            _queryParameters = new CommonQueryParameters {SortBy = "Value"};
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof (Office))]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof (Office))]
        public PagedResults Offices(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search),
                                           extendedQueryParams,
                                           null, x => x.Value, search);
        }

        IEnumerable<Office> MatchingItems(string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();

            IQueryable<InprotechKaizen.Model.Cases.Office> offices =
                _dbContext.Set<InprotechKaizen.Model.Cases.Office>();

            if (!string.IsNullOrEmpty(search))
                offices = offices.Where(_ => (DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) ?? string.Empty).ToLower().Contains(search.ToLower()));

            var filteredOffices = offices.Select(_ => new
                                                 {
                                                     _.Id,
                                                     Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                                                     _.Organisation,
                                                     CountryName = _.Country == null ? null : DbFuncs.GetTranslation(_.Country.Name, null, _.Country.NameTId, culture),
                                                     DefaultLanguageName = _.DefaultLanguage == null ? null : DbFuncs.GetTranslation(_.DefaultLanguage.Name, null, _.DefaultLanguage.NameTId, culture)
                                                 }).ToArray();

            return filteredOffices.Select(_ => new Office
                                                   {
                                                       Key = _.Id,
                                                       Value = _.Name,
                                                       Organisation = _.Organisation == null ? null : _.Organisation.Formatted(),
                                                       Country = _.CountryName,
                                                       DefaultLanguage = _.DefaultLanguageName
                                                   });
        }
    }

    public class Office
    {
        [Required]
        [PicklistKey]
        public int Key { get; set; }

        [MaxLength(80)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        [DisplayName(@"Organisation")]
        [DisplayOrder(1)]
        public string Organisation { get; set; }

        [DisplayName(@"Country")]
        [DisplayOrder(2)]
        public string Country { get; set; }

        [DisplayName(@"DefaultLanguage")]
        [DisplayOrder(3)]
        public string DefaultLanguage { get; set; }
    }
}