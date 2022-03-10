using System;
using System.IO;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Web;
using Microsoft.Owin;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using NLog;

namespace Inprotech.Infrastructure
{
    /// <summary>
    ///     This middleware will handle all exceptions originating from any of the middlewares
    ///     and will also handle any global unhandled exceptions delegated by DelegatingExceptionHandlerMiddleware
    ///     such as exceptions thrown from controller constructors or message handlers, during routing
    ///     or response content serialization.
    /// </summary>
    public class GlobalExceptionHandlerMiddleware : OwinMiddleware
    {
        readonly Logger _logger;
        readonly IRequestContext _requestContext;

        public GlobalExceptionHandlerMiddleware(OwinMiddleware next, IRequestContext requestContext) : base(next)
        {
            _requestContext = requestContext;

            _logger = LogManager.GetLogger(typeof(GlobalExceptionHandlerMiddleware).FullName);
        }

        public override async Task Invoke(IOwinContext context)
        {
            try
            {
                await Next.Invoke(context);
            }
            catch (IOException io) when (io.InnerException is HttpListenerException)
            {
            }
            catch (OperationCanceledException ocx) when (WhenTypingaheadInPicklists(ocx, context))
            {
                
            }
            catch (TaskCanceledException tcx) when (WhenRedirectingToSignIn(tcx, context))
            {
            }
            catch (Exception ex)
            {
                await HandleException(ex, context);
            }
        }

        static T TryGet<T>(Func<T> action)
        {
            try
            {
                return action();
            }
            catch (ObjectDisposedException)
            {
                return default(T);
            }
        }

        async Task HandleException(Exception exception, IOwinContext context)
        {
            var @event = LogEventInfo.Create(LogLevel.Error, _logger.Name, exception, null, exception.Message);
            
            @event.Properties["User"] = TryGet(() => context.Request?.User?.Identity?.Name);
            @event.Properties["RequestId"] = TryGet(() => _requestContext.RequestId);
            @event.Properties["Url"] = TryGet(() => context.Request?.Uri?.AbsoluteUri);

            foreach (var key in exception.Data.Keys)
                @event.Properties[key] = exception.Data[key];

            _logger.Log(@event);

            if (exception is HttpResponseException)
            {
                // If exception being thrown is an HttpResponseException, we shouldn't modify it
                // because, we could potentially override the response intended by the ApiController.
                return;
            }

            var result = new
            {
                Status = "UnhandledException",
#if DEBUG
                Exception = exception.ToString(),
#endif
                CorrelationId = @event.Properties["RequestId"],
                User = @event.Properties["User"]
            };

            context.Response.StatusCode = (int) HttpStatusCode.InternalServerError;

            // In rare situation, the below re-writing of context.Response may cause an ObjectDisposedException.
            // It usually means that something was attempting to write the response stream after the response was completed.
            // This would mean controller action and all other middleware already finished executing.
            
            await context.Response.WriteAsync(
                                              JsonConvert.SerializeObject(result,
                                                                          new JsonSerializerSettings
                                                                          {
                                                                              ContractResolver = new CamelCasePropertyNamesContractResolver()
                                                                          }));
        }

        static bool WhenRedirectingToSignIn(TaskCanceledException tcx, IOwinContext context)
        {
            if (tcx.Task.IsFaulted || !context.Request.CallCancelled.IsCancellationRequested)
            {
                return false;
            }

            return context.Request.Path.HasValue && context.Request.Path.Value.EndsWith("signin/index.html");
        }

        static bool WhenTypingaheadInPicklists(OperationCanceledException ocx, IOwinContext context)
        {
            return context.Request.CallCancelled.IsCancellationRequested &&
                   context.Request.Path.HasValue && context.Request.Path.Value.Contains("api/picklists");
        }
    }
}