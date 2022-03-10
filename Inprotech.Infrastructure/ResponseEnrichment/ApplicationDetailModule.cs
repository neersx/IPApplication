using Autofac;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationUser;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion;
using Inprotech.Infrastructure.ResponseEnrichment.Instrumentation;

namespace Inprotech.Infrastructure.ResponseEnrichment
{
    public class ApplicationDetailModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ApplicationUserResponseEnricher>().As<IResponseEnricher>();
            builder.RegisterType<SystemInfoResponseEnricher>().As<IResponseEnricher>();
            builder.RegisterType<UserAgentResponseEnricher>().As<IResponseEnricher>();
            builder.RegisterType<AuthenticationInfoResponseEnricher>().As<IResponseEnricher>();
            builder.RegisterType<InstrumentationDetailsEnricher>().As<IResponseEnricher>();
            builder.RegisterType<AnalyticsIdentifierEnricher>().As<IResponseEnricher>();
            builder.RegisterType<AppVersion>().As<IAppVersion>();
        }
    }
}
