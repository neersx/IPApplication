using System;
using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.Schedules.Extensions.FileApp;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class EnsureScheduleValid
    {
        readonly IFileSettingsResolver _fileSettingsResolver;

        public EnsureScheduleValid(IFileSettingsResolver fileSettingsResolver)
        {
            _fileSettingsResolver = fileSettingsResolver;
        }

        public Task ValidateRequiredSettings(FileAppSchedule fileAppSchedule)
        {
            if (fileAppSchedule == null) throw new ArgumentNullException(nameof(fileAppSchedule));

            _fileSettingsResolver.EnsureRequiredKeysAvailable();

            if (!fileAppSchedule.SavedQueryId.HasValue)
            {
                throw new InvalidOperationException("Saved query id is missing from schedule.");
            }

            if (!fileAppSchedule.RunAsUserId.HasValue)
            {
                throw new InvalidOperationException("Run as user is missing from schedule.");
            }

            return Task.FromResult(0);
        }
    }
}