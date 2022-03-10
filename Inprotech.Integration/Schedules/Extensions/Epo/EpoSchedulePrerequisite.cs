using Inprotech.Integration.Settings;

namespace Inprotech.Integration.Schedules.Extensions.Epo
{
    public class EpoSchedulePrerequisite : IDataSourceSchedulePrerequisites
    {
        readonly IEpoIntegrationSettings _epoIntegrationSettings;

        public EpoSchedulePrerequisite(IEpoIntegrationSettings epoIntegrationSettings)
        {
            _epoIntegrationSettings = epoIntegrationSettings;
        }
        public bool Validate(out string unmetRequirement)
        {
            unmetRequirement = string.Empty;
            if (!string.IsNullOrWhiteSpace(_epoIntegrationSettings.Keys.ConsumerKey) && !string.IsNullOrWhiteSpace(_epoIntegrationSettings.Keys.PrivateKey))
                return true;

            unmetRequirement = "epo-missing-keys";
            return false;
        }
    }
}
