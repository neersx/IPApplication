using Autofac;

namespace Inprotech.Server.Scheduling
{
    public class SchedulingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<PriorityRunner>().As<IRunner>().SingleInstance();
            builder.RegisterType<MonitorRunner>().As<IRunner>().SingleInstance();
            builder.RegisterType<LowPriorityRunner>().As<IRunner>().SingleInstance();
        }
    }
}