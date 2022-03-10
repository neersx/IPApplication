using Autofac;
using Inprotech.Web.InproDoc.Config;

namespace Inprotech.Web.InproDoc
{
    public class InproDocModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ConfigManager>().As<IPassThruManager>();
            builder.RegisterType<DocItemCommand>().As<IDocItemCommand>();
            builder.RegisterType<DocumentService>().As<IDocumentService>();
        }
    }
}