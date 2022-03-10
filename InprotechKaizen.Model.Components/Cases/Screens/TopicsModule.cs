using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Screens
{
    public class TopicsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CaseViewSectionsResolver>().AsImplementedInterfaces();
            builder.RegisterType<CaseViewSectionsTaskSecurity>().As<ICaseViewSectionsTaskSecurity>();
        }
    }
}
