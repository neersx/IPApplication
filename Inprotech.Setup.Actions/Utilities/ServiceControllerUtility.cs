using System;
using System.Linq;
using System.ServiceProcess;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions.Utilities
{
    public static class ServiceControllerUtility
    {
        public static void Stop(string service, IEventStream eventStream)
        {
            if(string.IsNullOrWhiteSpace(service)) throw new ArgumentNullException(nameof(service));
            if(eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            ServiceController scm;
            bool canStop;
            try
            {
                scm = new ServiceController(service);
                canStop = scm.CanStop;
            }
            catch (Exception e)
            {
                eventStream.PublishWarning($"Could not stop service {service} - {e}");
                return;
            }

            if(canStop) scm.Stop();
        }

        public static bool TryCheckExists(string service, IEventStream eventStream, out bool exists)
        {
            if (string.IsNullOrWhiteSpace(service)) throw new ArgumentNullException(nameof(service));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            exists = false;
            try
            {
                exists = ServiceController.GetServices().Any(_ => _.ServiceName == service);
                return true;
            }
            catch (Exception e)
            {
                eventStream.PublishWarning($"Could not query for service {service} status: {e}");
                return false;
            }
        }
    }
}