using Inprotech.Integration.IPPlatform.FileApp;

namespace Inprotech.Integration.Schedules.Extensions.FileApp
{
    public class FileAppSchedulePrerequisite : IDataSourceSchedulePrerequisites
    {
        readonly IFileSettingsResolver _fileSettingsResolver;

        public FileAppSchedulePrerequisite(IFileSettingsResolver fileSettingsResolver)
        {
            _fileSettingsResolver = fileSettingsResolver;
        }
        public bool Validate(out string unmetRequirement)
        {
            unmetRequirement = null;
            if (_fileSettingsResolver.Resolve().IsEnabled) return true;

            unmetRequirement = "missing-platform-registration-file";
            return false;
        }
    }
}
