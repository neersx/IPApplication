using System;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion.Extensions;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;

namespace Inprotech.Server.ApplicationInsightsExtensions
{
    public class UserContextIdsTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            if (telemetry == null) throw new ArgumentNullException(nameof(telemetry));

            var owinContext = OwinContextAccessor.CurrentContext;
            if (owinContext == null || !owinContext.Environment.TryGetValue("LogId", out var logId) || owinContext.Request.User == null) return;
            telemetry.Context.Session.Id = logId.ToString();
            telemetry.Context.User.AuthenticatedUserId = owinContext.Request.User.Identity.Name;
            telemetry.Context.User.Id = owinContext.Request.User.Identity.Name;
        }
    }

    public class ApplicationVersionTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            if (telemetry == null) throw new ArgumentNullException(nameof(telemetry));

            telemetry.Context.Component.Version = this.GetType().Assembly.Version();
        }
    }
}