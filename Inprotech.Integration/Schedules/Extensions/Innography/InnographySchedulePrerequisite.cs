using Inprotech.Integration.Innography;

namespace Inprotech.Integration.Schedules.Extensions.Innography
{
    public class InnographySchedulePrerequisite : IDataSourceSchedulePrerequisites
    {
        readonly IInnographySettingsResolver _settingsResolver;

        public InnographySchedulePrerequisite(IInnographySettingsResolver settingsResolver)
        {
            _settingsResolver = settingsResolver;
        }

        public bool Validate(out string unmetRequirement)
        {
            unmetRequirement = null;
            if (_settingsResolver.Resolve(InnographyEndpoints.Default).IsIPIDIntegrationEnabled) return true;

            unmetRequirement = "missing-platform-registration-innography";
            return false;
        }
    }
}