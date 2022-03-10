using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace Inprotech.IntegrationServer.Scheduling
{
    public static class DueScheduleActivities
    {
        public static IReadOnlyCollection<Type> List { get; } = new ReadOnlyCollection<Type>(
                                                                                             new [] 
                                                                                             {
                                                                                                 typeof(PtoAccess.Epo.Activities.DueSchedule),
                                                                                                 typeof(PtoAccess.Innography.Activities.DueSchedule),
                                                                                                 typeof(PtoAccess.FileApp.Activities.DueSchedule),
                                                                                                 typeof(PtoAccess.Uspto.Tsdr.Activities.DueSchedule),
                                                                                                 typeof(PtoAccess.Uspto.PrivatePair.Activities.DueSchedule),
                                                                                                 typeof(PtoAccess.Activities.BackgroundIdentityConfiguration)
                                                                                             });
    }
}
