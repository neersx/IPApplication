using System.Web.Http;
using Autofac;
using Autofac.Integration.WebApi;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.Policy;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure
{
    public static class WebApiPipeline
    {
        public static void Assemble(HttpConfiguration configuration, ContainerBuilder builder)
        {
            builder.RegisterType<RequestContextInitializationFilter>().AsWebApiAuthorizationFilterFor<ApiController>();
            builder.RegisterType<ExternalApplicationAuthenticationFilter>().AsWebApiAuthenticationFilterFor<ApiController>();

            builder.RegisterType<SessionValidationFilter>().AsWebApiAuthorizationFilterFor<ApiController>();
            builder.RegisterType<TaskAuthorisationFilter>().AsWebApiAuthorizationFilterFor<ApiController>();

            builder.RegisterType<AuthenticationSettingsFilter>().AsWebApiAuthorizationFilterFor<ApiController>();
            builder.RegisterType<RequiresIpPlatformSessionFilter>().AsWebApiAuthorizationFilterFor<ApiController>();

            // These action filters are executed in the reverse order of registration.
            builder.RegisterType<AuthorizeCriteriaPurposeCodeTaskSecurityFilter>().AsWebApiAuthorizationFilterFor<ApiController>();
            builder.RegisterType<NoCacheFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<JsonAsPlainTextFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<ResponseEnrichmentFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<PicklistResponseFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<RegisterAccessFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<AllowableProgramsOnlyFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<DataSecurityExceptionLoggingFilter>().AsWebApiExceptionFilterFor<ApiController>();
            builder.RegisterType<UnhandledExceptionLoggingFilter>().AsWebApiExceptionFilterFor<ApiController>();
            builder.RegisterType<PreallocateSessionAccessTokenFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<AuditTrailFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<CaseAuthorizationFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<NameAuthorizationFilter>().AsWebApiActionFilterFor<ApiController>();
        }
    }
}