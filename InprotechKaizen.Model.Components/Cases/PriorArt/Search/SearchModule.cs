using Autofac;

namespace InprotechKaizen.Model.Components.Cases.PriorArt.Search
{
    public class SearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PriorArtFilterCriteriaBuilder>().As<IPriorArtFilterCriteriaBuilder>();
        }
    }
}