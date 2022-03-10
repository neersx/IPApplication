using System;
using System.Threading.Tasks;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface ICriticalDatesRenewalInfoResolver
    {
        Task Resolve(User user, string culture, CriticalDatesMetadata result);
    }

    public class CriticalDatesRenewalInfoResolver : ICriticalDatesRenewalInfoResolver
    {
        readonly INextRenewalDatesResolver _nextRenewalDatesResolver;

        public CriticalDatesRenewalInfoResolver(INextRenewalDatesResolver nextRenewalDatesResolver)
        {
            _nextRenewalDatesResolver = nextRenewalDatesResolver;
        }

        public async Task Resolve(User user, string culture, CriticalDatesMetadata result)
        {
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (result.CriteriaNo == null) throw new ArgumentException("CriteriaNo must be provided");

            var dates = await _nextRenewalDatesResolver.Resolve(result.CaseId, result.CriteriaNo);

            result.NextRenewalDate = dates.NextRenewalDate;
            result.CpaRenewalDate = dates.CpaRenewalDate;
            result.AgeOfCase = dates.AgeOfCase;
        }
    }
}