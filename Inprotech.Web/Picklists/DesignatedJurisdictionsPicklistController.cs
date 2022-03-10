using System;
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
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/designatedjurisdictions")]
    public class DesignatedJurisdictionsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public DesignatedJurisdictionsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route]
        public PagedResults<DesignatedJurisdictionItem> Search(string groupId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            if (groupId == null) throw new ArgumentNullException(nameof(groupId));

            var culture = _preferredCultureResolver.Resolve();
            var results = _dbContext.Set<CountryGroup>().Where(_ => _.Id == groupId).Select(_ => new
            {
                Key = _.MemberCountry,
                Value = DbFuncs.GetTranslation(_.GroupMember.Name, null, _.GroupMember.NameTId, culture),
            });

            if (!string.IsNullOrEmpty(search))
                results = results.Where(_ => _.Value.StartsWith(search)).Select(_ => new { _.Key, _.Value });

            results = results.OrderBy(_ => _.Value);

            return Helpers.GetPagedResults(results.Select(_ => new DesignatedJurisdictionItem
                                                                   {
                                                                       Key = _.Key,
                                                                       Value = _.Value,
                                                                   }), queryParameters,
                                           x => x.Key, x => x.Value, search);
        }

        public class DesignatedJurisdictionItem
        {
            [PicklistKey]
            public string Key { get; set; }

            [DisplayName(@"Description")]
            [PicklistDescription]
            [DisplayOrder(0)]
            public string Value { get; set; }
        }
    }
}