using System;
using System.Threading.Tasks;
using Inprotech.Integration.Schedules.Extensions.Uspto.Tsdr;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class EnsureScheduleValid
    {
        readonly ITsdrSettings _tsdrSettings;

        public EnsureScheduleValid(ITsdrSettings tsdrSettings)
        {
            _tsdrSettings = tsdrSettings;
        }

        public Task ValidateRequiredSettings(TsdrSchedule tsdrSchedule)
        {
            if (tsdrSchedule == null) throw new ArgumentNullException(nameof(tsdrSchedule));

            _tsdrSettings.EnsureRequiredKeysAvailable();

            if (!tsdrSchedule.SavedQueryId.HasValue)
            {
                throw new InvalidOperationException("Saved query id is missing from schedule.");
            }

            if (!tsdrSchedule.RunAsUserId.HasValue)
            {
                throw new InvalidOperationException("Run as user is missing from schedule.");
            }

            return Task.FromResult(0);
        }
    }
}