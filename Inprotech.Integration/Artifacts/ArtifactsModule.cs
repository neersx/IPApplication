using Autofac;

namespace Inprotech.Integration.Artifacts
{
    public class ArtifactsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DataDownloadLocationResolver>().As<IDataDownloadLocationResolver>();
        }
    }
}
