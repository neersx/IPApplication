using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class InnographyPrivatePairSettingsBuilder : IBuilder<InnographyPrivatePairSetting>
    {
        public string ClientId { get; set; }

        public string ClientSecret { get; set; }

        public PrivatePairExternalSettings PrivatePairExternalSettings { get; set; }

        public InnographyPrivatePairSetting Build()
        {
            return new InnographyPrivatePairSetting
            {
                ClientId = ClientId ?? Fixture.String(),
                ClientSecret = ClientSecret ?? Fixture.String(),
                PrivatePairSettings = PrivatePairExternalSettings ??
                                      new PrivatePairExternalSettingsBuilder().Build()
            };
        }
    }
}