using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Translations;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Translations;

namespace Inprotech.Web.Processing
{
    public interface ITranslationChangeMonitor : IMonitorClockRunnableAsync
    {
    }

    class TranslationChangeMonitor : ITranslationChangeMonitor
    {
        readonly IRepository _repository;
        readonly ITranslationDeltaApplier _translationDeltaApplier;
        readonly Func<DateTime> _now;
        static DateTime _lastChecked;
        public TranslationChangeMonitor(IRepository repository, ITranslationDeltaApplier translationDeltaApplier, Func<DateTime> now)
        {
            _repository = repository;
            _translationDeltaApplier = translationDeltaApplier;
            _now = now;
        }
        public void Run()
        {
            throw new NotImplementedException();
        }

        public async Task RunAsync()
        {
            var now = _now();
            var lastChecked = _lastChecked;
            _lastChecked = now;
            var deltas = _repository.Set<TranslationDelta>().Where(_ => _.LastModified >= lastChecked);
            var translationsPath = @"client\condor\localisation\translations";

            foreach (var data in deltas)
            {
                var translationFilePath = Path.Combine(translationsPath, $"translations_{data.Culture}.json");
                await _translationDeltaApplier.ApplyFor(data.Delta, translationFilePath);
            }
        }
    }
}