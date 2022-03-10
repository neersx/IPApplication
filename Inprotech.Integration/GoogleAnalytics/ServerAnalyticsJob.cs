using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Instrumentation;
using Inprotech.Integration.GoogleAnalytics.Parameters;
using Inprotech.Integration.GoogleAnalytics.Parameters.User;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.GoogleAnalytics
{
    public class ServerAnalyticsJob : IPerformBackgroundJob
    {
        readonly IGoogleAnalyticsSettingsResolver _settingsResolver;
        readonly IGoogleAnalyticsClient _client;
        readonly Func<DateTime> _now;
        readonly IEnumerable<IAnalyticsEventProvider> _analyticsEventProviders;
        readonly IRepository _repository;
        readonly IBackgroundProcessLogger<ServerAnalyticsJob> _logger;
        readonly AnalyticsRuntimeSettings _analyticsRuntimeSettings;
        string _clientName;

        readonly List<string> _transactionalData = new List<string>()
        {
            "Users.",
            "AuthenticationType.",
            "Integrations.",
            "Statistics."
        };

        public ServerAnalyticsJob(IGoogleAnalyticsSettingsResolver settingsResolver, IGoogleAnalyticsClient client, Func<DateTime> now, IEnumerable<IAnalyticsEventProvider> analyticsEventProviders,
                                  IRepository repository, IBackgroundProcessLogger<ServerAnalyticsJob> logger, AnalyticsRuntimeSettings analyticsRuntimeSettings)
        {
            _settingsResolver = settingsResolver;
            _client = client;
            _now = now;
            _analyticsEventProviders = analyticsEventProviders;
            _repository = repository;
            _logger = logger;
            _analyticsRuntimeSettings = analyticsRuntimeSettings;
        }

        public string Type => nameof(ServerAnalyticsJob);

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<ServerAnalyticsJob>(_ => _.CollectAndSend());
        }

        public async Task CollectAndSend()
        {
            if (!_settingsResolver.IsEnabled()) return;

            var lastChecked = _now().AddDays(-7).Date; // Discuss this further

            _clientName = _analyticsRuntimeSettings.IdentifierKey;

            var requests = new List<IGoogleAnalyticsRequest>();
            var eventData = new List<AnalyticsEvent>();

            foreach (var analyticsEventProvider in _analyticsEventProviders)
            {
                eventData.AddRange(from ae in await SafeExecute(analyticsEventProvider.Provide, lastChecked)
                                   select ae);
            }

            requests.AddRange(from ae in FilterUnchanged(eventData)
                              select NewRequest(ae.Name, ae.Value));

            if (requests.Any())
            {
                await _client.Post(requests.ToArray());
                await _repository.SaveChangesAsync();
            }
        }

        List<AnalyticsEvent> FilterUnchanged(IEnumerable<AnalyticsEvent> requests)
        {
            var data = (from r in requests
                        join d in _repository.Set<ServerAnalyticsData>() on r.Name equals d.Event into d1
                        from d in d1.DefaultIfEmpty()
                        where d == null || _transactionalData.Exists(_ => r.Name.StartsWith(_)) || r.Value != d.Value
                        select new
                        {
                            isNew = d == null,
                            r.Name,
                            r.Value,
                            db = d
                        }).ToArray();

            var changed = _now();
            foreach (var d in data)
            {
                if (d.isNew)
                {
                    _repository.Set<ServerAnalyticsData>().Add(new ServerAnalyticsData { Event = d.Name, Value = d.Value, LastSent = changed });
                    continue;
                }

                d.db.Value = d.Value;
                d.db.LastSent = changed;
            }

            return data.Select(_ => new AnalyticsEvent(_.Name, _.Value)).ToList();
        }

        async Task<IEnumerable<AnalyticsEvent>> SafeExecute(Func<DateTime, Task<IEnumerable<AnalyticsEvent>>> execute, DateTime lastChecked)
        {
            try
            {
                return await execute(lastChecked);
            }
            catch (Exception e)
            {
                _logger.Exception(e);
                return Enumerable.Empty<AnalyticsEvent>();
            }
        }

        EventRequest NewRequest(string category, string value)
        {
            var req = new EventRequest();
            req.Parameters.Add(new EventCategory(category));
            //req.Parameters.Add(new UserId(_clientName));
            req.Parameters.Add(new ClientId(_clientName));
            req.Parameters.Add(new EventAction(_clientName));
            req.Parameters.Add(new EventLabel(value));
            return req;
        }
    }
}