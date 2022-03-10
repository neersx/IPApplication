using Autofac;
using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Integration.Innography.Ids
{
    public class IdsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DocumentApiClient>().As<IDocumentApiClient>();
            builder.RegisterType<IpOneDataDocumentFinder>()
                   .As<IAsyncPriorArtEvidenceFinder>()
                   .Keyed<IAsyncPriorArtEvidenceFinder>(typeof(IpOneDataDocumentFinder).Name)
                   .WithMetadata("Name", typeof(IpOneDataDocumentFinder).Name);
            builder.RegisterType<PatentScoutSettingsResolver>().As<IPatentScoutSettingsResolver>();
        }
    }
}