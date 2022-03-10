using System.Collections.Generic;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class PrivatePairExternalSettingsBuilder : IBuilder<PrivatePairExternalSettings>
    {
        public string AccountId { get; set; }

        public string AccountSecret { get; set; }

        public string QueueId { get; set; }

        public string QueueAccessSecret { get; set; }
        
        public string ValidEnvironment { get; set; }
        
        public Dictionary<string, ServiceCredentials> Services { get; }

        public PrivatePairExternalSettings Build()
        {
            return new PrivatePairExternalSettings
            {
                ClientId = AccountId ?? Fixture.String(),
                ClientSecret = AccountSecret ?? Fixture.String(),
                QueueId = QueueId ?? Fixture.String(),
                QueueSecret = QueueAccessSecret ?? Fixture.String(),
                ValidEnvironment = ValidEnvironment ?? "this-environment",
                Services = Services ?? new Dictionary<string, ServiceCredentials>()
            };
        }

        public PrivatePairExternalSettingsBuilder()
        {
            Services = new Dictionary<string, ServiceCredentials>();
        }

        public PrivatePairExternalSettingsBuilder WithServiceCredential(string serviceId = null)
        {
            var id = serviceId ?? Fixture.String();

            Services.Add(id, new ServiceCredentials
            {
                Id = id
            });

            return this;
        }
    }
}