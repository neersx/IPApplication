using Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion.Extensions;
using Inprotech.Server.ApplicationInsightsExtensions;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Server
{
    public class ApplicationVersionTelemetryInitializerFacts
    {
        [Fact]
        public void IntializesWithCurrentComponentVersion()
        {
            var thisVersion = GetType().Assembly.Version();

            var telemetry = Substitute.For<ITelemetry>();
            var context = new TelemetryContext();

            telemetry.Context.Returns(context);

            var subject = new ApplicationVersionTelemetryInitializer();
            subject.Initialize(telemetry);

            Assert.Equal(thisVersion, telemetry.Context.Component.Version);
        }
    }
}