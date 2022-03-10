using Autofac;
using Inprotech.Infrastructure;
using Inprotech.Web.Attachment;
using Inprotech.Web.Configuration.Attachments;

namespace Inprotech.Web.ContactActivities
{
    public class ContactActivitiesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ActivityAttachmentMaintenance>().As<IActivityAttachmentMaintenance>().Keyed<IActivityAttachmentMaintenance>(AttachmentFor.ContactActivity).WithParameter("attachmentFor", AttachmentFor.ContactActivity);
            builder.RegisterType<FileHelpers>().As<IFileHelpers>();
            builder.RegisterType<AttachmentSettings>().As<IAttachmentSettings>();
            builder.RegisterType<ActivityMaintenance>().As<IActivityMaintenance>();
        }
    }
}
