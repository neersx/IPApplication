using Autofac;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public class BulkCaseUpdatesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            
            builder.RegisterType<BulkFieldUpdates>()
                   .As<IBulkFieldUpdates>();

            builder.RegisterType<BulkCaseUpdatesJob>()
                   .AsImplementedInterfaces()
                   .AsSelf();

            builder.RegisterType<ConfigureBulkCaseUpdatesJob>().As<IConfigureBulkCaseUpdatesJob>();
            builder.RegisterType<BulkFieldUpdateHandler>().AsImplementedInterfaces();
            builder.RegisterType<BulkCaseTextUpdateHandler>().As<IBulkCaseTextUpdateHandler>();
            builder.RegisterType<BulkCaseNameReferenceUpdateHandler>().As<IBulkCaseNameReferenceUpdateHandler>();
            builder.RegisterType<BulkFileLocationUpdateHandler>().As<IBulkFileLocationUpdateHandler>();
            builder.RegisterType<BulkCaseStatusUpdateHandler>().As<IBulkCaseStatusUpdateHandler>();
            builder.RegisterType<BatchedSqlCommand>().As<IBatchedSqlCommand>();
            builder.RegisterType<BulkPolicingHandler>().As<IBulkPolicingHandler>();
        }
    }
}