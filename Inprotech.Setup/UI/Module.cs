using Autofac;

namespace Inprotech.Setup.UI
{
    public class Module : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<MessageBox>().As<IMessageBox>();
            builder.RegisterTypes(
               typeof(RecoveryCommand))
               .AsSelf();

        }
    }
}
