using Autofac;
using Dependable;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Settings;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    public class DmsIntegrationDependableWireup : IFixture<DmsIntegrationWorkflow>
    {
        readonly InMemoryDbContext _db;

        public DmsIntegrationDependableWireup(InMemoryDbContext db)
        {
            _db = db;

            Loader = Substitute.For<ILoadCaseAndDocuments>();
            Settings = Substitute.For<IDmsIntegrationSettings>();
            Sender = Substitute.For<IMoveDocumentToDmsFolder>();
            Updater = Substitute.For<IUpdateDocumentStatus>();
            Publisher = Substitute.For<IDmsIntegrationPublisher>();
            DocumentForDms = Substitute.For<IDocumentForDms>();
            DmsIntegrationJobStateUpdater = Substitute.For<IUpdateDmsIntegrationJobStates>();
            FailingSender = Substitute.For<IFailedSendingDocumentToDms>();
            LoaderAndSender = Substitute.For<ILoadCaseAndSendDocumentToDms>();

            Subject = new DmsIntegrationWorkflow(Loader, Settings);
        }

        public ILoadCaseAndDocuments Loader { get; set; }

        public IDmsIntegrationSettings Settings { get; set; }

        public IMoveDocumentToDmsFolder Sender { get; set; }

        public IUpdateDocumentStatus Updater { get; set; }

        public IDmsIntegrationPublisher Publisher { get; set; }

        public IDocumentForDms DocumentForDms { get; set; }

        public IUpdateDmsIntegrationJobStates DmsIntegrationJobStateUpdater { get; set; }

        public IFailedSendingDocumentToDms FailingSender { get; set; }

        public ILoadCaseAndSendDocumentToDms LoaderAndSender { get; set; }

        public DmsIntegrationWorkflow Subject { get; set; }

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();
            builder.RegisterInstance(_db).As<IRepository>();
            builder.RegisterInstance(Sender).As<IMoveDocumentToDmsFolder>();
            builder.RegisterInstance(Updater).As<IUpdateDocumentStatus>();
            builder.RegisterInstance(Loader).As<ILoadCaseAndDocuments>();
            builder.RegisterInstance(LoaderAndSender).As<ILoadCaseAndSendDocumentToDms>();
            builder.RegisterInstance(Publisher).As<IDmsIntegrationPublisher>();
            builder.RegisterInstance(DocumentForDms).As<IDocumentForDms>();
            builder.RegisterInstance(DmsIntegrationJobStateUpdater).As<IUpdateDmsIntegrationJobStates>();
            builder.RegisterInstance(FailingSender).As<IFailedSendingDocumentToDms>();
            builder.RegisterType<NullActivity>().AsSelf();
            builder.RegisterInstance(completedActivity).AsSelf();
            return builder.Build();
        }

        public void Execute(Activity activity)
        {
            DependableActivity.Execute(activity, WireUp);
        }
    }
}