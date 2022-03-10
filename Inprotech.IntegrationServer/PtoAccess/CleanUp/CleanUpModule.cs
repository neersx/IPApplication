using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    class CleanUpModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<FileCleanUp>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<LegacyFileCleanUp>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<LegacyDirectories>().AsImplementedInterfaces(); 
            builder.RegisterType<ScheduleExecutionSessionCleaner>().AsImplementedInterfaces();
            builder.RegisterType<ScheduleExecutionSessionFolderCleaner>().AsImplementedInterfaces();
            builder.RegisterType<ScheduleExecutionStatusUpdater>().AsImplementedInterfaces();
            builder.RegisterType<FileCleanUpPublisher>().AsImplementedInterfaces();
            builder.RegisterType<FolderCleanUpPublisher>().AsImplementedInterfaces();
            builder.RegisterType<FileCleanUpLogger>().AsImplementedInterfaces();
            builder.RegisterType<DependableJobsCleanUp>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<ScheduleExecutionArtefactsCleanUp>().AsImplementedInterfaces().AsSelf();
            builder.RegisterType<IdentifyProcessIdsToCleanup>().AsImplementedInterfaces().AsSelf();
        }
    }
}
