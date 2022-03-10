using System;
using Autofac;
using Inprotech.Contracts;
using Microsoft.AspNet.SignalR.Hubs;

namespace Inprotech.Server.Extensibility
{
    public class SignalRErrorHandler : HubPipelineModule
    {
        readonly IBackgroundProcessLogger<SignalRErrorHandler> _logger;

        public SignalRErrorHandler(ILifetimeScope container)
        {
            _logger = container.Resolve<IBackgroundProcessLogger<SignalRErrorHandler>>();
        }

        protected override void OnIncomingError(ExceptionContext exceptionContext, IHubIncomingInvokerContext invokerContext)
        {
            if (exceptionContext == null) throw new ArgumentNullException(nameof(exceptionContext));
            if (invokerContext == null) throw new ArgumentNullException(nameof(invokerContext));

            _logger.Exception(exceptionContext.Error);
            base.OnIncomingError(exceptionContext, invokerContext);
        }
    }
}