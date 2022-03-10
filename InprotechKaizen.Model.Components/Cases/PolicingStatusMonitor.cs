using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Components.System.Messages;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IPolicingStatusMonitor : IMonitorClockRunnable
    {
    }

    public class PolicingStatusMonitor : IPolicingStatusMonitor
    {
        readonly IPolicingStatusReader _policingStatusReader;
        readonly IBus _bus;
        readonly IPolicingChangeCaseIdProvider _caseIdProvider;

        public PolicingStatusMonitor(IPolicingStatusReader policingStatusReader, IBus bus, IPolicingChangeCaseIdProvider caseIdProvider)
        {
            _policingStatusReader = policingStatusReader;
            _bus = bus;
            _caseIdProvider = caseIdProvider;
        }

        public void Run()
        {
            var caseIds = _caseIdProvider.CaseIds.ToArray();
            if (!caseIds.Any())
                return;

            var results = _policingStatusReader.ReadMany(caseIds);
            
            foreach (var pair in results)
            {
                if(PreventPublishingSameData(pair)) return;

                var message = new BroadcastMessageToClient
                              {
                                  Topic = "policing.change." + pair.Key, Data = pair.Value
                              };

                _bus.Publish(message);
            }
        }

        bool PreventPublishingSameData(KeyValuePair<int, string> pair)
        {
            var dataToCompare = _caseIdProvider.PublishedData[pair.Key];
            if (string.Equals(dataToCompare, pair.Value, StringComparison.OrdinalIgnoreCase)) return true;

            _caseIdProvider.PublishedData[pair.Key] = pair.Value;
            return false;
        }
    }
}