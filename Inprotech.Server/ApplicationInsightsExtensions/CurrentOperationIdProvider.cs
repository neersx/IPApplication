using ApplicationInsights.OwinExtensions;
using Inprotech.Infrastructure.Monitoring;

namespace Inprotech.Server.ApplicationInsightsExtensions
{
    public class CurrentOperationIdProvider : ICurrentOperationIdProvider
    {
        public string OperationId => OperationContext.Get()?.OperationId;
    }
}