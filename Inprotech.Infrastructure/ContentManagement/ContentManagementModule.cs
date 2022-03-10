using Autofac;

namespace Inprotech.Infrastructure.ContentManagement
{
    public class ContentManagementModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PdfUtility>().As<IPdfUtility>();
        }
    }
}
