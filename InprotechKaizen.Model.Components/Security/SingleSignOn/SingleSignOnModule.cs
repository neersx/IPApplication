using Autofac;

namespace InprotechKaizen.Model.Components.Security.SingleSignOn
{
    public class SingleSignOnModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SsoUserIdentifier>().As<ISsoUserIdentifier>();
        }
    }
}
