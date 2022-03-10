using Autofac;
using Inprotech.Infrastructure.Diagnostics;

namespace Inprotech.Web.Diagnostics
{
    public class DiagnosticsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<InprotechServerLogs>().As<ICompressedServerLogs>();
        }
    }
}
