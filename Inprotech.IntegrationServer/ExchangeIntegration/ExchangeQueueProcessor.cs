using System;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Dependable.Utilities;
using Inprotech.Contracts;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.IntegrationServer.BackgroundProcessing;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.ExchangeIntegration
{
    public class ExchangeQueueProcessor : IBackgroundTasksProcessor
    {
        readonly IIndex<ExchangeRequestType, Func<IHandleExchangeMessage>> _handlers;
        readonly IBackgroundProcessLogger<ExchangeQueueProcessor> _logger;
        readonly IRequestQueue _requestQueue;
        readonly IExchangeIntegrationSettings _settings;

        public ExchangeQueueProcessor(
            IRequestQueue requestQueue,
            IBackgroundProcessLogger<ExchangeQueueProcessor> logger,
            IExchangeIntegrationSettings settings,
            IIndex<ExchangeRequestType, Func<IHandleExchangeMessage>> handlers)
        {
            _requestQueue = requestQueue;
            _logger = logger;
            _settings = settings;
            _handlers = handlers;
        }

        public async Task<BackgroundTaskResult> Process()
        {
            var settings = _settings.Resolve();
            if (!settings.IsReminderEnabled && !settings.IsDraftEmailEnabled && !settings.IsBillFinalisationEnabled)
            {
                return new BackgroundTaskResult(true);
            }

            var totalCompleted = 0;
            var totalFailed = 0;

            while (true)
            {
                var request = new ExchangeRequest();
                var result = new ExchangeProcessResult();

                try
                {
                    request = await _requestQueue.NextRequest();
                    if (request == null) break;

                    LogRequest(request);

                    var handler = GetHandler(request);

                    result = await handler.Process(request, settings);

                    if (result.Result != KnownStatuses.Failed)
                    {
                        await _requestQueue.Completed(request.Id);
                        totalCompleted++;

                        continue;
                    }

                    await LogFailure(request, result);
                    totalFailed++;
                }
                catch (Exception ex)
                {
                    if (ex.IsFatal())
                    {
                        throw;
                    }

                    _logger.Exception(ex);

                    result.Result = KnownStatuses.Failed;
                    result.ErrorMessage = ex.FlattenErrorMessageForFrontEnd();

                    await LogFailure(request, result);
                    totalFailed++;
                }
            }

            return new BackgroundTaskResult(totalCompleted, totalFailed);
        }

        IHandleExchangeMessage GetHandler(ExchangeRequest request)
        {
            if (!_handlers.TryGetValue(request.RequestType, out var handlerCreator))
            {
                throw new NotSupportedException($"Unhandled exchange message type <{request.RequestType}> for id: {request.Id}");
            }

            var handler= handlerCreator();
            handler.SetLogContext(request.Context);
            return handler;
        }

        void LogRequest(ExchangeRequest request)
        {
            _logger.Trace("Processing " + ExchangeRequestLogHeader(request));
        }

        async Task LogFailure(ExchangeRequest request, ExchangeProcessResult result)
        {
            _logger.Warning($"Failure processing {ExchangeRequestLogHeader(request)} message: {result.ErrorMessage}");
            
            if (request == null) return;
            
            await _requestQueue.Failed(request.Id, result.ErrorMessage, result.Result);
        }

        static string ExchangeRequestLogHeader(ExchangeRequest request)
        {
            return $"Processing Exchange Request [{request?.RequestType}] id: {request?.Id}\\ {request?.StaffId}\\ {request?.SequenceDate:s};";
        }
    }
}