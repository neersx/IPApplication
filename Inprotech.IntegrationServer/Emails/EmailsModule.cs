using Autofac;
using Inprotech.Infrastructure.Notifications;

namespace Inprotech.IntegrationServer.Emails
{
    public class EmailsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SmtpClient>().As<ISmtpClient>();
        }
    }
}