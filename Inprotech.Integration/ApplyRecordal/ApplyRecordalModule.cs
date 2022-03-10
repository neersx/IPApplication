using Autofac;

namespace Inprotech.Integration.ApplyRecordal
{
    public class ApplyRecordalModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ApplyRecordal>().AsSelf();
            builder.RegisterType<ApplyRecordalHandler>().AsImplementedInterfaces();
            builder.RegisterType<ApplyRecordalJob>().AsImplementedInterfaces().AsSelf();
        }
    }
}
