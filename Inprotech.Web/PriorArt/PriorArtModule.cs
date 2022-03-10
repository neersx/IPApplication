using Autofac;
using Inprotech.Web.PriorArt.Maintenance;
using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Web.PriorArt
{
    public class PriorArtModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CaseEvidenceFinder>()
                   .As<IAsyncPriorArtEvidenceFinder>()
                   .Keyed<IAsyncPriorArtEvidenceFinder>(typeof(CaseEvidenceFinder).Name)
                   .WithMetadata("Name", typeof(CaseEvidenceFinder).Name);

            builder.RegisterType<ExistingPriorArtFinder>()
                   .As<IAsyncPriorArtEvidenceFinder>()
                   .Keyed<IAsyncPriorArtEvidenceFinder>(typeof(ExistingPriorArtFinder).Name)
                   .WithMetadata("Name", typeof(ExistingPriorArtFinder).Name);

            builder.RegisterType<ConcurrentPriorArtEvidenceFinder>()
                   .As<IConcurrentPriorArtEvidenceFinder>();

            builder.RegisterType<EvidenceImporter>().As<IEvidenceImporter>();
            builder.RegisterType<CreateSourcePriorArt>().As<ICreateSourcePriorArt>();
            builder.RegisterType<MaintainSourcePriorArt>().As<IMaintainSourcePriorArt>();
            builder.RegisterType<ExistingPriorArtMatchBuilder>().As<IExistingPriorArtMatchBuilder>();
            builder.RegisterType<MaintainCitation>().As<IMaintainCitation>();
            builder.RegisterType<PriorArtMaintenanceValidator>().As<IPriorArtMaintenanceValidator>();
            builder.RegisterType<LinkedCaseSearch>().As<ILinkedCaseSearch>();
        }
    }
}