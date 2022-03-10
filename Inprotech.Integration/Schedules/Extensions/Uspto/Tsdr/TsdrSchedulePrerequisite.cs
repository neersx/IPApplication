using Inprotech.Integration.Settings;

namespace Inprotech.Integration.Schedules.Extensions.Uspto.Tsdr
{
    public class TsdrSchedulePrerequisite : IDataSourceSchedulePrerequisites
    {
        readonly ITsdrIntegrationSettings _tsdrIntegrationSettings;

        public TsdrSchedulePrerequisite(ITsdrIntegrationSettings tsdrIntegrationSettings)
        {
            _tsdrIntegrationSettings = tsdrIntegrationSettings;
        }

        public bool Validate(out string unmetRequirement)
        {
            unmetRequirement = string.Empty;
            if (!string.IsNullOrWhiteSpace(_tsdrIntegrationSettings.Key))
            {
                return true;
            }

            unmetRequirement = "tsdr-missing-keys";
            return false;
        }
    }
}