using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Accounting.Billing.BillReview;
using InprotechKaizen.Model.Profiles;
using NSubstitute;
using Xunit;
using DeliveryCapabilitiesResolver = InprotechKaizen.Model.Components.Accounting.Billing.Delivery.ICapabilitiesResolver;
using GenerationCapabilitiesResolver = InprotechKaizen.Model.Components.Accounting.Billing.Generation.ICapabilitiesResolver;
using DeliveryCapabilities = InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Capabilities;
using GenerationCapabilities = InprotechKaizen.Model.Components.Accounting.Billing.Generation.Capabilities;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.BillReview
{

    public class BillReviewSettingsResolverFacts
    {
        readonly DeliveryCapabilitiesResolver _deliveryCapabilitiesResolver = Substitute.For<DeliveryCapabilitiesResolver>();
        readonly GenerationCapabilitiesResolver _generationCapabilitiesResolver = Substitute.For<GenerationCapabilitiesResolver>();
        readonly IUserPreferenceManager _userPreferenceManager = Substitute.For<IUserPreferenceManager>();

        BillReviewSettingsResolver CreateSubject()
        {
            return new BillReviewSettingsResolver(_userPreferenceManager, _deliveryCapabilitiesResolver, _generationCapabilitiesResolver);
        }

        [Fact]
        public async Task ShouldReturnFalseIfReviewerMailboxNotSet()
        {
            var mailboxSetting = string.Empty;
            var userIdentityId = Fixture.Integer();

            _userPreferenceManager.GetPreference<string>(userIdentityId, KnownSettingIds.ExchangeMailbox)
                                  .Returns(mailboxSetting);

            var r = await CreateSubject().Resolve(userIdentityId);

            Assert.False(r.CanReviewBillInEmailDraft);
            Assert.Null(r.ReviewerMailbox);
        }

        [Fact]
        public async Task ShouldReturnFalseIfReportingServicesIntegrationNotConfigured()
        {
            var mailboxSetting = Fixture.String();
            var userIdentityId = Fixture.Integer();

            _userPreferenceManager.GetPreference<string>(userIdentityId, KnownSettingIds.ExchangeMailbox)
                                  .Returns(mailboxSetting);
            
            _deliveryCapabilitiesResolver.Resolve().Returns(new DeliveryCapabilities { CanDeliverBillInDraftMailbox = true });

            _generationCapabilitiesResolver.Resolve().Returns(new GenerationCapabilities { CanGenerateBills = false, CanGeneratePrintPreview = false });

            var r = await CreateSubject().Resolve(userIdentityId);

            Assert.False(r.CanReviewBillInEmailDraft);
            Assert.Equal(mailboxSetting, r.ReviewerMailbox);
        }

        [Fact]
        public async Task ShouldReturnFalseIfExchangeIntegrationNotConfigured()
        {
            var mailboxSetting = Fixture.String();
            var userIdentityId = Fixture.Integer();

            _userPreferenceManager.GetPreference<string>(userIdentityId, KnownSettingIds.ExchangeMailbox)
                                  .Returns(mailboxSetting);
            
            _deliveryCapabilitiesResolver.Resolve().Returns(new DeliveryCapabilities { CanDeliverBillInDraftMailbox = false });

            _generationCapabilitiesResolver.Resolve().Returns(new GenerationCapabilities { CanGenerateBills = true, CanGeneratePrintPreview = true });

            var r = await CreateSubject().Resolve(userIdentityId);

            Assert.False(r.CanReviewBillInEmailDraft);
            Assert.Equal(mailboxSetting, r.ReviewerMailbox);
        }
        
        [Fact]
        public async Task ShouldReturnTrueIfAllIntegratingServicesAreConfiguredAndMailboxIsSet()
        {
            var mailboxSetting = Fixture.String();
            var userIdentityId = Fixture.Integer();

            _userPreferenceManager.GetPreference<string>(userIdentityId, KnownSettingIds.ExchangeMailbox)
                                  .Returns(mailboxSetting);
            
            _deliveryCapabilitiesResolver.Resolve().Returns(new DeliveryCapabilities { CanDeliverBillInDraftMailbox = true });

            _generationCapabilitiesResolver.Resolve().Returns(new GenerationCapabilities { CanGenerateBills = true, CanGeneratePrintPreview = true });

            var r = await CreateSubject().Resolve(userIdentityId);

            Assert.True(r.CanReviewBillInEmailDraft);
            Assert.Equal(mailboxSetting, r.ReviewerMailbox);
        }
    }
}