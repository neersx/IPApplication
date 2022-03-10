using Autofac;

namespace Inprotech.Web.BulkCaseImport.NameResolution
{
    public class NameResolutionModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PotentialNameMatches>().As<IPotentialNameMatches>();
            builder.RegisterType<MapCandidates>().As<IMapCandidates>();
        }
    }
}
