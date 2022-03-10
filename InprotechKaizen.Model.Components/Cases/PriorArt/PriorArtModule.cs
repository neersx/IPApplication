using Autofac;

namespace InprotechKaizen.Model.Components.Cases.PriorArt
{
    public class PriorArtModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ConcurrentPriorArtEvidenceFinder>()
                   .As<IConcurrentPriorArtEvidenceFinder>();
        }
    }
}