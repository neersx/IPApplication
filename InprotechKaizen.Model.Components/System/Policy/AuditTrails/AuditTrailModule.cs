using Autofac;

namespace InprotechKaizen.Model.Components.System.Policy.AuditTrails
{
    public class AuditTrailModule : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<TransactionRecordal>().As<ITransactionRecordal>();
            builder.RegisterType<ContextInfo>().As<IContextInfo>();
            builder.RegisterType<ContextInfoSerializer>().As<IContextInfoSerializer>();
            builder.RegisterType<AuditLogs>().As<IAuditLogs>();
        }
    }
}