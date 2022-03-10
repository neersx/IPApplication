using Autofac;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Security.Access
{
    public class AccessModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ProgramAccessEnricher>().As<IResponseEnricher>();
            builder.RegisterType<AllowableProgramsResolver>().As<IAllowableProgramsResolver>();
        }
    }
}
