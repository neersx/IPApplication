using Autofac;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.Diagnostics
{
    public class DiagnosticsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterGeneric(typeof(NLogLogger<>)).As(typeof(ILogger<>));
            builder.RegisterGeneric(typeof(NLogBackgroundProcessLogger<>)).As(typeof(IBackgroundProcessLogger<>));
            builder.RegisterGeneric(typeof(NLogUserAuditLogger<>)).As(typeof(IUserAuditLogger<>));
        }
    }
}