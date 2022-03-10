using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search
{
    public class SearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<WipOverviewFilterCriteriaBuilder>().As<IWipOverviewFilterCriteriaBuilder>();
        }
    }
}