using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface ITranslatedNarrative
    {
        Task<string> For(string fallbackCulture, short narrativeId, int? caseId = null, int? debtorId = null, int? languageId = null);

        Task<IDictionary<short, string>> For(string fallbackCulture, IEnumerable<short> narrativeIds, int? caseId = null, int? debtorId = null, int? languageId = null);
    }

    public class TranslatedNarrative : ITranslatedNarrative
    {
        readonly IBillingLanguageResolver _billingLanguageResolver;
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public TranslatedNarrative(IDbContext dbContext,
                                   ISiteControlReader siteControlReader,
                                   IBillingLanguageResolver billingLanguageResolver)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _billingLanguageResolver = billingLanguageResolver;
        }

        public async Task<IDictionary<short, string>> For(string fallbackCulture, IEnumerable<short> narrativeIds, int? caseId = null, int? debtorId = null, int? languageId = null)
        {
            var billingLanguageId = languageId ?? await _billingLanguageResolver.Resolve(debtorId, caseId);

            return await GetTranslatedNarrativeWithFallback(billingLanguageId, fallbackCulture, narrativeIds.ToArray())
                .ToDictionaryAsync(k => k.NarrativeId, v => v.TranslatedText);
        }

        public async Task<string> For(string fallbackCulture, short narrativeId, int? caseId = null, int? debtorId = null, int? languageId = null)
        {
            var billingLanguageId = languageId ?? await _billingLanguageResolver.Resolve(debtorId, caseId);

            return (await GetTranslatedNarrativeWithFallback(billingLanguageId, fallbackCulture, narrativeId).SingleOrDefaultAsync())?.TranslatedText;
        }

        IQueryable<InterimTranslatedNarrative> GetTranslatedNarrativeWithFallback(int? billingLanguageId, string fallbackCulture, params short[] narrativeIds)
        {
            var requireTranslation = _siteControlReader.Read<bool>(SiteControls.NarrativeTranslate);

            var narrativeTranslate = from nt in _dbContext.Set<NarrativeTranslation>()
                                     where requireTranslation && nt.LanguageId == billingLanguageId
                                     select nt;

            return from n in _dbContext.Set<Narrative>()
                   join nt in narrativeTranslate on n.NarrativeId equals nt.NarrativeId into nt1
                   from nt in nt1.DefaultIfEmpty()
                   where narrativeIds.Contains(n.NarrativeId)
                   select new InterimTranslatedNarrative
                   {
                       NarrativeId = n.NarrativeId,
                       TranslatedText = nt != null && nt.TranslatedText != null
                           ? nt.TranslatedText
                           : DbFuncs.GetTranslation(n.NarrativeText, null, n.NarrativeTextTid, fallbackCulture)
                   };
        }

        class InterimTranslatedNarrative
        {
            public short NarrativeId { get; set; }

            public string TranslatedText { get; set; }
        }
    }
}