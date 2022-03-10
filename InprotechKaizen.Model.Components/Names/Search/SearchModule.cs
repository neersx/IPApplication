using Autofac;

namespace InprotechKaizen.Model.Components.Names.Search
{
    public class SearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<NameFilterCriteriaBuilder>().As<INameFilterCriteriaBuilder>();
        }
    }
}