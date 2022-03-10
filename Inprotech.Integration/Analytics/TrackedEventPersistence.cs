using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Analytics
{
    public interface ITrackedEventPersistence : IMonitorClockRunnableAsync
    {
    }

    internal class TrackedEventPersistence : ITrackedEventPersistence
    {
        readonly Func<DateTime> _now;
        readonly ITransactionalAnalyticsProviderSink _providerSink;
        readonly IRepository _repository;

        public TrackedEventPersistence(IRepository repository, Func<DateTime> now, ITransactionalAnalyticsProviderSink providerSink)
        {
            _repository = repository;
            _now = now;
            _providerSink = providerSink;
        }

        public void Run()
        {
            RunAsync().ConfigureAwait(false);
        }

        public async Task RunAsync()
        {
            var events = _providerSink.Provide().ToArray();

            if (!events.Any())
            {
                return;
            }

            foreach (var @event in events)
            {
                _repository.Set<ServerTransactionalDataSink>()
                           .Add(new ServerTransactionalDataSink
                           {
                               Event = @event.EventType,
                               Value = @event.Value,
                               Entered = _now()
                           });
            }

            await _repository.SaveChangesAsync();
        }
    }
}