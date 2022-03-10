using System.Web.Http;
using Autofac;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Integration.Diagnostics;
using Inprotech.Integration.Filters;

namespace Inprotech.Integration
{
    public static class IntegrationApiPipeline
    {
        public static void Assemble(ContainerBuilder builder)
        {
            builder.RegisterType<ExternalApplicationAuthenticationFilter>().AsWebApiAuthenticationFilterFor<ApiController>();

            builder.RegisterType<TaskAuthorisationFilter>().AsWebApiAuthorizationFilterFor<ApiController>();
            builder.RegisterType<LicenseAuthorisationFilter>().AsWebApiAuthorizationFilterFor<ApiController>();
            
            builder.RegisterGeneric(typeof(WebApiLogger<>)).As(typeof(ILogger<>));
            builder.RegisterType<DataSecurityExceptionLoggingFilter>().AsWebApiExceptionFilterFor<ApiController>();
            builder.RegisterType<UnhandledWebApiExceptionFilter>().AsWebApiExceptionFilterFor<ApiController>();

            // These action filters are executed in the reverse order of registration.
            builder.RegisterType<HandleNullArgumentFilter>().AsWebApiActionFilterFor<ApiController>();
            builder.RegisterType<CaseAuthorizationFilter>().AsWebApiActionFilterFor<ApiController>();
        }
    }
}