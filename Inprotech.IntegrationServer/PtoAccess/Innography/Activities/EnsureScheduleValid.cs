using System;
using System.Threading.Tasks;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Schedules.Extensions.Innography;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public class EnsureScheduleValid
    {
        readonly IInnographySettingsResolver _innographySettingsResolver;

        public EnsureScheduleValid(IInnographySettingsResolver innographySettingsResolver)
        {
            _innographySettingsResolver = innographySettingsResolver;
        }

        public Task ValidateRequiredSettings(InnographySchedule innographySchedule)
        {
            if (innographySchedule == null) throw new ArgumentNullException(nameof(innographySchedule));

            _innographySettingsResolver.EnsureRequiredKeysAvailable();

            if (!innographySchedule.SavedQueryId.HasValue)
            {
                throw new InvalidOperationException("Saved query id is missing from schedule.");
            }

            if (!innographySchedule.RunAsUserId.HasValue)
            {
                throw new InvalidOperationException("Run as user is missing from schedule.");
            }

            return Task.FromResult(0);
        }
    }
}