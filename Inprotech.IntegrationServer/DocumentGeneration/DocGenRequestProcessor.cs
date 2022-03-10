using System;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.IntegrationServer.BackgroundProcessing;

namespace Inprotech.IntegrationServer.DocumentGeneration
{
    public class DocGenRequestProcessor : IBackgroundTasksProcessor
    {
        readonly IIndex<string, Func<IHandleDocGenRequest>> _handlers;
        readonly IBackgroundProcessLogger<DocGenRequestProcessor> _logger;
        readonly IRequestQueue _requestQueue;

        public DocGenRequestProcessor(
            IRequestQueue requestQueue,
            IIndex<string, Func<IHandleDocGenRequest>> handlers,
            IBackgroundProcessLogger<DocGenRequestProcessor> logger
        )
        {
            _requestQueue = requestQueue;
            _handlers = handlers;
            _logger = logger;
        }

        public async Task<BackgroundTaskResult> Process()
        {
            var totalCompleted = 0;
            var totalFailed = 0;
            
            while (true)
            {
                var request = new DocGenRequest();
                var result = new DocGenProcessResult();

                try
                {
                    var context = Guid.NewGuid();
                    _logger.SetContext(context);

                    request = await _requestQueue.NextRequest(context);
                    
                    if (request == null) break;

                    var requestType = request.RequestType();

                    LogRequest(request);

                    var handler = GetHandler(requestType, request.Id, context);
                    
                    result = await handler.Handle(request);

                    if (result.Result == KnownStatuses.Success)
                    {
                        await _requestQueue.Completed(request.Id, result.FileName);
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

        IHandleDocGenRequest GetHandler(string requestType, int id, Guid context)
        {
            if (!_handlers.TryGetValue(requestType, out var handlerCreator))
            {
                throw new NotSupportedException($"Unhandled DocGen message type <{requestType}> for id: {id}");
            }

            var handler= handlerCreator();
            handler.SetLogContext(context);
            return handler;
        }

        void LogRequest(DocGenRequest request)
        {
            _logger.Trace("Processing " + DocGenRequestLogHeader(request));
        }

        async Task LogFailure(DocGenRequest request, DocGenProcessResult result)
        {
            _logger.Warning($"Failure processing {DocGenRequestLogHeader(request)} message: {result.ErrorMessage}");
            
            if (request == null) return;
            
            await _requestQueue.Failed(request.Id, result.ErrorMessage);
        }

        static string DocGenRequestLogHeader(DocGenRequest request)
        {
            return $"DocGen Request [{request.RequestType()}] id:{request?.Id}\\  ({request?.CaseId}\\{request?.WhenRequested:s})\\ letter: {request?.LetterId}\\ deliveryId: {request?.DeliveryId};";
        }
    }
}