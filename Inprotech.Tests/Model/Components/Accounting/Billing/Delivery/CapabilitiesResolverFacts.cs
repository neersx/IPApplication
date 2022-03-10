using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Integration.Exchange;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Delivery
{
    public class CapabilitiesResolverFacts
    {
        [Theory]
        [InlineData(false, false, false)]
        [InlineData(false, true, false)]
        [InlineData(true, false, false)]
        [InlineData(true, true, true)]
        public async Task ShouldReturnCanDeliverBillInDraftMailboxIfSettingPermits(bool hasValidSettings, bool isBillFinalisationEnabled, bool expectedValue)
        {
            var exchangeSiteSettingsResolver = Substitute.For<IExchangeSiteSettingsResolver>();
            exchangeSiteSettingsResolver.Resolve()
                                        .Returns(new ExchangeSiteSetting
                                        {
                                            HasValidSettings = hasValidSettings,
                                            Settings = new ExchangeConfigurationSettings
                                            {
                                                IsBillFinalisationEnabled = isBillFinalisationEnabled
                                            }
                                        });

            var subject = new CapabilitiesResolver(exchangeSiteSettingsResolver);

            var result = await subject.Resolve();

            Assert.Equal(expectedValue, result.CanDeliverBillInDraftMailbox);
        }
    }
}