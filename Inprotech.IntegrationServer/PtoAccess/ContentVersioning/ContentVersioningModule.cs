using Autofac;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.ContentVersioning
{
    public class ContentVersioningModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DownloadedContent>().As<IDownloadedContent>();

            builder.RegisterType<DefaultVersionableContentResolver>()
                .As<IDefaultVersionableContentResolver>();
        }
    }
}
