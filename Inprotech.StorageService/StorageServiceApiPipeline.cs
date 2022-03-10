using System.Web.Http;
using Autofac;
using Autofac.Integration.WebApi;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.Diagnostics;

namespace Inprotech.StorageService
{
    public static class StorageServiceApiPipeline
    {
        public static void Assemble(ContainerBuilder builder)
        {
            builder.RegisterType<ExternalApplicationAuthenticationFilter>().AsWebApiAuthenticationFilterFor<ApiController>();
            builder.RegisterGeneric(typeof(WebApiLogger<>)).As(typeof(ILogger<>));
            builder.RegisterType<UnhandledWebApiExceptionFilter>().AsWebApiExceptionFilterFor<ApiController>();
        }
    }
}