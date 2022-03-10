using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/narratives")]
    public class NarrativesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ITranslatedNarrative _translatedNarrative;

        public NarrativesPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ITranslatedNarrative translatedNarrative)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _translatedNarrative = translatedNarrative;
        }

        [HttpGet]
        [Route]
        [RequiresCaseAuthorization]
        [RequiresNameAuthorization(PropertyName = "debtorKey")]
        public async Task<PagedResults<NarrativeItem>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                              CommonQueryParameters queryParameters = null, string search = "", int? caseKey = null, int? debtorKey = null)
        {
            return Helpers.GetPagedResults(await MatchingItems(search, caseKey, debtorKey),
                                           queryParameters,
                                           x => x.Key.ToString(), x => x.Value, search);
        }

        async Task<IEnumerable<NarrativeItem>> MatchingItems(string search = "", int? caseId = null, int? debtorId = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            var matches = from n in _dbContext.Set<Narrative>()
                          select new NarrativeItem
                          {
                              Key = n.NarrativeId,
                              Code = n.NarrativeCode,
                              Value = DbFuncs.GetTranslation(n.NarrativeTitle, null, n.NarrativeTitleTid, culture),
                              Text = DbFuncs.GetTranslation(null, n.NarrativeText, n.NarrativeTextTid, culture),
                              ExactMatch = search != null && n.NarrativeCode == search
                          };

            if (!string.IsNullOrEmpty(search))
            {
                matches = matches.Where(_ => _.Code.Contains(search) || _.Value.Contains(search));
            }

            var results = await matches.OrderBy(_ => _.ExactMatch).ThenBy(_ => _.Value).ToArrayAsync();

            var translated = await _translatedNarrative.For(culture, results.Select(_ => _.Key), caseId, GetEffectiveDebtorId(debtorId, caseId));

            var translatedResults = (from r in results
                                     join t in translated on r.Key equals t.Key into t1
                                     from t in t1.DefaultIfEmpty()
                                     select new NarrativeItem
                                     {
                                         Key = r.Key,
                                         Code = r.Code,
                                         Value = r.Value,
                                         Text = t.Value ?? r.Text,
                                         ExactMatch = r.ExactMatch
                                     }).ToArray();

            return translatedResults.Any(_ => _.ExactMatch) ? translatedResults.Where(_ => _.ExactMatch) : translatedResults;
        }

        static int? GetEffectiveDebtorId(int? debtorId, int? caseId)
        {
            // particularly this is because Time Recording sends Instructor Key masquerading as Debtor Key
            // setting the debtorKey null will result in the logic to derive the debtor from the case.
            return caseId != null ? null : debtorId;
        }

        public class NarrativeItem
        {
            [PicklistKey]
            public short Key { get; set; }

            [PicklistCode]
            [DisplayOrder(0)]
            public string Code { get; set; }

            [PicklistDescription]
            [DisplayOrder(1)]
            public string Value { get; set; }

            [DisplayOrder(2)]
            public string Text { get; set; }

            [JsonIgnore]
            public bool ExactMatch { get; set; }
        }
    }
}