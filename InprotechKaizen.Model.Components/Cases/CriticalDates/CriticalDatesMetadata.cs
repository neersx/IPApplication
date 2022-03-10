using System;
using System.Threading.Tasks;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface ICriticalDatesMetadataResolver
    {
        Task<CriticalDatesMetadata> Resolve(User user, string culture, int caseId);
    }

    public class CriticalDatesMetadataResolver : ICriticalDatesMetadataResolver
    {
        readonly ICriticalDatesConfigResolver _configResolver;
        readonly ICriticalDatesPriorityInfoResolver _priorityInfoResolver;
        readonly ICriticalDatesRenewalInfoResolver _renewalInfoResolver;

        public CriticalDatesMetadataResolver(ICriticalDatesConfigResolver configResolver, ICriticalDatesRenewalInfoResolver renewalInfoResolver, ICriticalDatesPriorityInfoResolver priorityInfoResolver)
        {
            _configResolver = configResolver;
            _renewalInfoResolver = renewalInfoResolver;
            _priorityInfoResolver = priorityInfoResolver;
        }

        public async Task<CriticalDatesMetadata> Resolve(User user, string culture, int caseId)
        {
            if (user == null) throw new ArgumentNullException(nameof(user));

            var result = new CriticalDatesMetadata {CaseId = caseId};

            await _configResolver.Resolve(user, culture, result);

            if (!result.IsComplete) return result;

            await _renewalInfoResolver.Resolve(user, culture, result);

            await _priorityInfoResolver.Resolve(user, culture, result);

            return result;
        }
    }

    public class CriticalDatesMetadata
    {
        public int CaseId { get; set; }

        public string CaseRef { get; set; }

        public int? CriteriaNo { get; set; }

        public string Action { get; set; }

        public string RenewalAction { get; set; }

        public int ImportanceLevel { get; set; }

        public int? DefaultPriorityEventNo { get; set; }

        public Uri ExternalPatentInfoUriForPriorityEvent { get; set; }

        public int? PriorityEventNo { get; set; }

        public DateTime? EarliestPriorityDate { get; set; }

        public string EarliestPriorityNumber { get; set; }

        public string EarliestPriorityCountry { get; set; }

        public string EarliestPriorityCountryId { get; set; }

        public DateTime? NextRenewalDate { get; set; }

        public DateTime? CpaRenewalDate { get; set; }

        public short? AgeOfCase { get; set; }

        public bool IsComplete => !string.IsNullOrWhiteSpace(Action) && CriteriaNo.HasValue;
    }
}