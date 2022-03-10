using System.Threading.Tasks;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface IBestTranslatedNarrativeResolver
    {
        Task<BestNarrative> Resolve(string fallbackCulture, string activityKey, int? staffNameId, int? caseId = null, int? debtorId = null);
    }

    public class BestTranslatedNarrativeResolver : IBestTranslatedNarrativeResolver
    {
        readonly IBestNarrativeResolver _bestNarrativeResolver;
        readonly ITranslatedNarrative _translatedNarrative;

        public BestTranslatedNarrativeResolver(IBestNarrativeResolver bestNarrativeResolver, ITranslatedNarrative translatedNarrative)
        {
            _bestNarrativeResolver = bestNarrativeResolver;
            _translatedNarrative = translatedNarrative;
        }

        public async Task<BestNarrative> Resolve(string fallbackCulture, string activityKey, int? staffNameId, int? caseId = null, int? debtorId = null)
        {
            var effectiveDebtorId = !caseId.HasValue ? debtorId : null;

            var bestNarrative = await _bestNarrativeResolver.Resolve(fallbackCulture, activityKey, staffNameId, caseId, effectiveDebtorId);

            if (bestNarrative != null)
            {
                bestNarrative.Text = await _translatedNarrative.For(fallbackCulture, bestNarrative.Key, caseId, effectiveDebtorId);
            }

            return bestNarrative;
        }
    }
}