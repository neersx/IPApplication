using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.PctOneTimeJob
{
    class PctJobModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PctCasesCleanUp>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<CheckPctCase>().AsSelf();
            builder.RegisterType<UpdateAssociatedRelationCountry>().As<IUpdateAssociatedRelationCountry>();
        }
    }
}
