using System;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Activities
{
    public class ScheduleInitialisationFailure
    {
        readonly IScheduleRuntimeEvents _scheduleRuntimeEvents;
        readonly IGlobErrors _globErrors;
        
        public ScheduleInitialisationFailure(
            IScheduleRuntimeEvents scheduleRuntimeEvents,
            IGlobErrors globErrors)
        {
            _scheduleRuntimeEvents = scheduleRuntimeEvents;
            _globErrors = globErrors;
        }

        public async Task Notify(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            _scheduleRuntimeEvents.Failed(dataDownload.Id, 
                JsonConvert.SerializeObject(await _globErrors.For(dataDownload)));
        }
    }
}
