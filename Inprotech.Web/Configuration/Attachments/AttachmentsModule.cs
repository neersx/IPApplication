using Autofac;

namespace Inprotech.Web.Configuration.Attachments
{
    class AttachmentsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<AttachmentSettings>().As<IAttachmentSettings>();
        }
    }
}