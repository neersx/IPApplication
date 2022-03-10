using System;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure.Monitoring;

namespace Inprotech.Infrastructure.Web
{
    /// <summary>
    ///     Provides access to per request data.
    ///     Scope: InstancePerLifetimeScope
    /// </summary>
    public interface IRequestContext
    {
        /// <summary>
        ///     Uniquely identifies the current request.
        ///     This can be used during operations such as logging to correlate log messages from different
        ///     parts involved in processing the current request.
        /// </summary>
        Guid RequestId { get; }

        /// <summary>
        ///     Current http request message.
        /// </summary>
        HttpRequestMessage Request { get; }
    }

    public interface IInitializeRequestContext
    {
        void SetRequest(HttpRequestMessage request, string ambientOperationId);
    }
    
    public class RequestContext : IRequestContext, IInitializeRequestContext
    {
        public void SetRequest(HttpRequestMessage request, string ambientOperationId)
        {
            Request = request;

            RequestId = Guid.TryParse(ambientOperationId, out Guid operationId)
                ? operationId
                : Guid.NewGuid();
        }

        public Guid RequestId { get; private set; }
        
        public HttpRequestMessage Request { get; private set; }
    }

    /// <summary>
    ///     Hooks into Web API pipeline to initialize our
    ///     RequestContext.  This is switched from an ActionFilter to an AuthorizationFilter so that it is executed first.
    /// </summary>
    public class RequestContextInitializationFilter : IAutofacAuthorizationFilter
    {
        readonly IInitializeRequestContext _initializeRequestContext;
        readonly ICurrentOperationIdProvider _currentOperationIdProvider;
        
        public RequestContextInitializationFilter(IInitializeRequestContext initializeRequestContext,
                                                    ICurrentOperationIdProvider currentOperationIdProvider)
        {
            _initializeRequestContext = initializeRequestContext;
            _currentOperationIdProvider = currentOperationIdProvider;
        }

        public Task OnAuthorizationAsync(HttpActionContext actionContext, CancellationToken cancellationToken)
        {
            _initializeRequestContext.SetRequest(actionContext.Request,
                                                    _currentOperationIdProvider.OperationId);

            return Task.FromResult(0);
        }
    }
}