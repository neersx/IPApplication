using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.GoogleAnalytics;

namespace Inprotech.Integration.Analytics
{
    public interface ITransactionalAnalyticsProviderSink
    {
        IEnumerable<TransactionalAnalyticsMessage> Provide();
    }

    public class TransactionalAnalyticsProviderSink : ITransactionalAnalyticsProviderSink,
                                         IHandle<TransactionalAnalyticsMessage>,
                                         IHandleAsync<TransactionalAnalyticsMessage>
    {
        readonly Func<IGoogleAnalyticsSettingsResolver> _settingsResolver;

        static readonly ConcurrentBag<TransactionalAnalyticsMessage> Cache =
            new ConcurrentBag<TransactionalAnalyticsMessage>();

        public TransactionalAnalyticsProviderSink(Func<IGoogleAnalyticsSettingsResolver> settingsResolver)
        {
            _settingsResolver = settingsResolver;
        }

        public Task HandleAsync(TransactionalAnalyticsMessage message)
        {
            Handle(message);

            return Task.FromResult((object) null);
        }

        bool? _isEnabled = null;
        public void Handle(TransactionalAnalyticsMessage message)
        {
            if (!_isEnabled.HasValue)
            {
                _isEnabled = _settingsResolver().IsEnabled();
            }
            if (!_isEnabled.Value) return;

            Cache.Add(message);
        }

        public IEnumerable<TransactionalAnalyticsMessage> Provide()
        {
            while (Cache.TryTake(out var message) && message != null)
                yield return message;
        }
    }
}