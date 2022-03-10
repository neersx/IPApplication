using Autofac;
using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Web.PriorArt.ExistingPriorArtFinders
{
    public class ExistingPriorArtFindersModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ExistingSourcePriorArt>()
                   .As<IExistingPriorArtFinder>()
                   .Keyed<IExistingPriorArtFinder>(PriorArtTypes.Source);
            builder.RegisterType<ExistingLiteraturePriorArt>()
                   .As<IExistingPriorArtFinder>()
                   .Keyed<IExistingPriorArtFinder>(PriorArtTypes.Literature);
            builder.RegisterType<ExistingIpoIssuedPriorArt>()
                   .As<IExistingPriorArtFinder>()
                   .Keyed<IExistingPriorArtFinder>(PriorArtTypes.Ipo);
        }
    }
}