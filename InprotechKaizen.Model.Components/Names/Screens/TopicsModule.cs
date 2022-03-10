using Autofac;

namespace InprotechKaizen.Model.Components.Names.Screens
{
    public class TopicsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<NameViewSectionsResolver>().As<INameViewSectionsResolver>();
            builder.RegisterType<NameViewSectionsTaskSecurity>().As<INameViewSectionsTaskSecurity>();
        }
    }
}
