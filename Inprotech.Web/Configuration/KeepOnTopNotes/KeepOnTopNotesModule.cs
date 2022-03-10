using Autofac;

namespace Inprotech.Web.Configuration.KeepOnTopNotes
{
    public class KeepOnTopNotesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<KeepOnTopTextTypes>().As<IKeepOnTopTextTypes>();
        }
    }
}
