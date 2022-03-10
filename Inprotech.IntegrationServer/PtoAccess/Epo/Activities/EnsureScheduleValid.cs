using System;
using System.Threading.Tasks;
using Inprotech.Integration.Schedules.Extensions.Epo;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.Activities
{
    public class EnsureScheduleValid
    {
        readonly IEpoSettings _epoSettings;

        public EnsureScheduleValid(IEpoSettings epoSettings)
        {
            _epoSettings = epoSettings;
        }

        public Task ValidateRequiredSettings(EpoSchedule epoSchedule)
        {
            if (epoSchedule == null) throw new ArgumentNullException(nameof(epoSchedule));

            _epoSettings.EnsureRequiredKeysAvailable();

            if (!epoSchedule.SavedQueryId.HasValue)
                throw new InvalidOperationException("Saved query id is missing from schedule.");

            if (!epoSchedule.RunAsUserId.HasValue)
                throw new InvalidOperationException("Run as user is missing from schedule.");

            return Task.FromResult(0);
        }
    }
}
