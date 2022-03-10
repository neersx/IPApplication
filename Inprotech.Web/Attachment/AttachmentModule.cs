using Autofac;

namespace Inprotech.Web.Attachment
{
    class AttachmentModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<AttachmentMaintenance>().As<IAttachmentMaintenance>();
            builder.RegisterType<ActivityAttachmentAccessResolver>().As<IActivityAttachmentAccessResolver>();
            builder.RegisterType<AttachmentContentLoader>().As<IAttachmentContentLoader>();
            builder.RegisterType<ActivityAttachmentFileNameResolver>().As<IActivityAttachmentFileNameResolver>();

            builder.RegisterType<CaseNamesAdhocDocumentData>().As<ICaseNamesAdhocDocumentData>();
        }
    }
}