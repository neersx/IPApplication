using Autofac;

namespace Inprotech.Integration.ExternalCaseResolution
{
    public class ExternalCaseResolutionModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PrivatePairCases>().As<IPrivatePairCases>();
        }
    }
}
