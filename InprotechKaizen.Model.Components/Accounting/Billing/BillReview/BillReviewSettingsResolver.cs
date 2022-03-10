using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Profiles;
using DeliveryCapabilitiesResolver = InprotechKaizen.Model.Components.Accounting.Billing.Delivery.ICapabilitiesResolver;
using GenerationCapabilitiesResolver = InprotechKaizen.Model.Components.Accounting.Billing.Generation.ICapabilitiesResolver;

namespace InprotechKaizen.Model.Components.Accounting.Billing.BillReview
{
    public interface IBillReviewSettingsResolver
    {
        Task<BillReviewSettings> Resolve(int userIdentityId);
    }

    public class BillReviewSettingsResolver : IBillReviewSettingsResolver
    {
        readonly DeliveryCapabilitiesResolver _deliveryCapabilitiesResolver;
        readonly GenerationCapabilitiesResolver _generationCapabilitiesResolver;
        readonly IUserPreferenceManager _userPreferenceManager;

        public BillReviewSettingsResolver(IUserPreferenceManager userPreferenceManager,
                                          DeliveryCapabilitiesResolver deliveryCapabilitiesResolver,
                                          GenerationCapabilitiesResolver generationCapabilitiesResolver)
        {
            _userPreferenceManager = userPreferenceManager;
            _deliveryCapabilitiesResolver = deliveryCapabilitiesResolver;
            _generationCapabilitiesResolver = generationCapabilitiesResolver;
        }

        public async Task<BillReviewSettings> Resolve(int userIdentityId)
        {
            var reviewerMailbox = _userPreferenceManager.GetPreference<string>(userIdentityId, KnownSettingIds.ExchangeMailbox);

            if (string.IsNullOrWhiteSpace(reviewerMailbox))
            {
                return new BillReviewSettings();
            }

            var canGenerate = (await _generationCapabilitiesResolver.Resolve()).CanGenerateBills;

            var canDeliver = (await _deliveryCapabilitiesResolver.Resolve()).CanDeliverBillInDraftMailbox;

            return new BillReviewSettings
            {
                ReviewerMailbox = reviewerMailbox,
                CanReviewBillInEmailDraft = canGenerate && canDeliver
            };
        }
    }
}