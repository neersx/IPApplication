using System;
using System.IO;
using System.Linq;
using Autofac;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Extensibility;
using Inprotech.IntegrationServer.PtoAccess.WorkflowIntegration;
using Inprotech.Tests.Dependable;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class DueScheduleDependableWireup
    {
        readonly InMemoryDbContext _db;

        public DueScheduleDependableWireup(InMemoryDbContext db)
        {
            _db = db;
            FileSystem = Substitute.For<IFileSystem>();
            ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
            ArtifactsLocationResolver.Resolve(Arg.Any<Session>())
                                     .Returns("SessionFolder");
            ArtifactsLocationResolver.Resolve(Arg.Any<Session>(), Arg.Any<string>())
                                     .Returns(x => Path.Combine("SessionFolder", (string)x[1]));

            ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();
            ScheduleRuntimeEvents.StartSchedule(Arg.Any<Schedule>(), Arg.Any<Guid>())
                                 .Returns(Guid.NewGuid());

            InnographyPrivatePairSettings = Substitute.For<IInnographyPrivatePairSettings>();

            LogEntry = Substitute.For<ILogEntry>();
            FailureLogger = Substitute.For<IPtoFailureLogger>();
            
            EnsureScheduleValid = Substitute.For<IEnsureScheduleValid>();
            ApplicationList = Substitute.For<IApplicationList>();
            PrivatePairService = Substitute.For<IPrivatePairService>();

            ArtefactsService = Substitute.For<IArtifactsService>();
            ExceptionGlobber = Substitute.For<IGlobErrors>();

            ScheduleInitialisationFailure = Substitute.For<IScheduleInitialisationFailure>();

            RequeueMessageDates = Substitute.For<IRequeueMessageDates>();
            Messages = Substitute.For<IMessages>();
            PrivatePairRuntimeEvents = Substitute.For<IPrivatePairRuntimeEvents>();
            UpdateArtifactMessageIndex = Substitute.For<IUpdateArtifactMessageIndex>();
            UsptoScheduleSettings = Substitute.For<IReadScheduleSettings>();
            ManageRecovery = Substitute.For<IManageRecoveryInfo>();
            ScheduleRecoverableReader = Substitute.For<IScheduleRecoverableReader>();
            SponsorshipHealthCheck = Substitute.For<ISponsorshipHealthCheck>();
            BufferedStringReader = Substitute.For<IBufferedStringReader>();
            ApplicationDownloadFailed = Substitute.For<IApplicationDownloadFailed>();
            DocumentDownload = Substitute.For<IDocumentDownload>();
            ProcessApplicationDocuments = Substitute.For<IProcessApplicationDocuments>();
            DocumentUpdate = Substitute.For<IDocumentUpdate>();
            BiblioStorage = Substitute.For<IBiblioStorage>();
            BiblioStorage.GetFileStoreBiblioInfo(Arg.Any<string>()).Returns((new FileStore(), Fixture.PastDate()));
            FileNameExtractor = Substitute.For<IFileNameExtractor>();
            FileNameExtractor.AbsoluteUriName(Arg.Any<string>()).Returns(call =>
            {
                var arg = call.ArgAt<string>(0);
                return Uri.TryCreate(arg, UriKind.Absolute, out Uri created)
                    ? Path.GetFileName(created.LocalPath)
                    : Path.GetFileName(arg);
            });

            DetailsWorkflow = Substitute.For<IDetailsWorkflow>();
            CorrelationIdUpdator = Substitute.For<ICorrelationIdUpdator>();
            BuildDmsIntegrationWorkflows = Substitute.For<IBuildDmsIntegrationWorkflows>();
            ConvertApplicationDetailsToCpaXml = Substitute.For<IConvertApplicationDetailsToCpaXml>();
            DocumentEvents = Substitute.For<DocumentEvents>(_db, Substitute.For<IDocumentLoader>(), DocumentEvents, CorrelationIdUpdator, Substitute.For<IComparisonDocumentsProvider>());
            ContentHasher = Substitute.For<IContentHasher>();
            PtoAccessCase = Substitute.For<IPtoAccessCase>();
            CheckCaseValidity = Substitute.For<ICheckCaseValidity>();
            DocumentDownloadFailure = Substitute.For<IDocumentDownloadFailure>();
        }

        HostInfo ReturnHostInfo()
        {
            return HostInfo;
        }

        public HostInfo HostInfo { get; } = new HostInfo { DbIdentifier = "this-environment" };
        public IFileSystem FileSystem { get; }
        public IMessages Messages { get; }
        public IArtifactsLocationResolver ArtifactsLocationResolver { get; }
        public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; }
        public IInnographyPrivatePairSettings InnographyPrivatePairSettings { get; }
        public IPrivatePairRuntimeEvents PrivatePairRuntimeEvents { get; }
        public IScheduleInitialisationFailure ScheduleInitialisationFailure { get; }
        public IEnsureScheduleValid EnsureScheduleValid { get; }
        public IPrivatePairService PrivatePairService { get; }
        public IApplicationList ApplicationList { get; }
        public IArtifactsService ArtefactsService { get; }
        public IGlobErrors ExceptionGlobber { get; }
        public ILogEntry LogEntry { get; }
        public IPtoFailureLogger FailureLogger { get; }
        public IUpdateArtifactMessageIndex UpdateArtifactMessageIndex { get; }
        public IReadScheduleSettings UsptoScheduleSettings { get; }
        public IManageRecoveryInfo ManageRecovery { get; }
        public IScheduleRecoverableReader ScheduleRecoverableReader { get; }
        public ISponsorshipHealthCheck SponsorshipHealthCheck { get; }
        public IBufferedStringReader BufferedStringReader { get; }
        public IApplicationDownloadFailed ApplicationDownloadFailed { get; }
        public IDocumentDownload DocumentDownload { get; }
        public IProcessApplicationDocuments ProcessApplicationDocuments { get; }
        public IDocumentUpdate DocumentUpdate { get; }
        public IBiblioStorage BiblioStorage { get; }
        public IFileNameExtractor FileNameExtractor { get; }
        public IDetailsWorkflow DetailsWorkflow { get; }
        public ICorrelationIdUpdator CorrelationIdUpdator { get; }
        public IBuildDmsIntegrationWorkflows BuildDmsIntegrationWorkflows { get; }
        public IConvertApplicationDetailsToCpaXml ConvertApplicationDetailsToCpaXml { get; }
        public DocumentEvents DocumentEvents { get; }
        public IContentHasher ContentHasher { get; }
        public IPtoAccessCase PtoAccessCase { get; }
        public ICheckCaseValidity CheckCaseValidity { get; }
        public IRequeueMessageDates RequeueMessageDates { get; }

        public IDocumentDownloadFailure DocumentDownloadFailure { get; }

        public DueScheduleDependableWireup WithPrivatePairSettings(InnographyPrivatePairSetting setting = null)
        {
            if (setting == null)
            {
                var external = new PrivatePairExternalSettingsBuilder()
                               .WithServiceCredential()
                               .Build();
                setting = new InnographyPrivatePairSettingsBuilder
                {
                    PrivatePairExternalSettings = external
                }.Build();
            }
            InnographyPrivatePairSettings.Resolve().Returns(setting);
            return this;
        }

        public DueScheduleDependableWireup WithMessagesRetrieveDispatchesNormally()
        {
            Messages.Retrieve(Arg.Any<Session>())
                    .Returns(r =>
                    {
                        var session = (Session) r[0];

                        var dispatchMessageFilesForProcessing = Activity.Run<IMessages>(_ => _.DispatchMessageFilesForProcessing(session));

                        var dispatchApplicationDownloads = Activity.Run<IApplicationList>(_ => _.DispatchDownload(session));

                        // Should keep in-sync with implementation
                        return Activity.Sequence(dispatchMessageFilesForProcessing, dispatchApplicationDownloads)
                                       .AnyFailed(Activity.Run<IScheduleInitialisationFailure>(s => s.SaveArtifactAndNotify(session)));
                    });
            return this;
        }

        public DueScheduleDependableWireup WithMessagesDispatchesFilesForProcessing(params int[] index)
        {
            Messages.DispatchMessageFilesForProcessing(Arg.Any<Session>())
                    .Returns(r =>
                    {
                        var session = (Session) r[0];

                        var sortIntoAppBucketActivities = index.Select(number =>
                                                                           Activity.Run<IMessages>(_ => _.SortIntoApplicationBucket(session, number))
                                                                      );

                        // Should keep in-sync with implementation
                        return Activity.Sequence(sortIntoAppBucketActivities);
                    });
            return this;
        }

        public DueScheduleDependableWireup WithDetailedLogging()
        {
            _detailedLogging = true;
            return this;
        }

        public string GetTrace() => _simpleLogger.Collected();

        bool _detailedLogging;

        SimpleLogger _simpleLogger;

        ILifetimeScope WireUp(
            DependableActivity.CompletedActivity completedActivity)
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User());
            _simpleLogger = new SimpleLogger();

            var builder = new ContainerBuilder();

            builder.RegisterType<NullActivity>().AsSelf();
            builder.RegisterType<DueSchedule>().AsSelf();
            builder.RegisterInstance(Messages).As<IMessages>();
            builder.Register(x => HostInfo);
            builder.RegisterInstance(EnsureScheduleValid).As<IEnsureScheduleValid>();

            builder.RegisterInstance(FileSystem).As<IFileSystem>();
            builder.RegisterInstance(ArtifactsLocationResolver).As<IArtifactsLocationResolver>();
            builder.RegisterInstance(ScheduleRuntimeEvents).As<IScheduleRuntimeEvents>();
            builder.RegisterInstance(InnographyPrivatePairSettings).As<IInnographyPrivatePairSettings>();
            builder.RegisterInstance(ScheduleInitialisationFailure).As<IScheduleInitialisationFailure>();
            builder.RegisterInstance(PrivatePairRuntimeEvents).As<IPrivatePairRuntimeEvents>();
            builder.RegisterInstance(ArtefactsService).As<IArtifactsService>();
            builder.RegisterInstance(ManageRecovery).As<IManageRecoveryInfo>();
            builder.RegisterInstance(UpdateArtifactMessageIndex).As<IUpdateArtifactMessageIndex>();
            builder.RegisterInstance(ScheduleRecoverableReader).As<IScheduleRecoverableReader>();
            builder.RegisterInstance(SponsorshipHealthCheck).As<ISponsorshipHealthCheck>();
            builder.RegisterInstance(BufferedStringReader).As<IBufferedStringReader>();
            builder.RegisterInstance(ApplicationDownloadFailed).As<IApplicationDownloadFailed>();
            builder.RegisterInstance(DocumentDownload).As<IDocumentDownload>();
            builder.RegisterInstance(ProcessApplicationDocuments).As<IProcessApplicationDocuments>();
            builder.RegisterInstance(DocumentUpdate).As<IDocumentUpdate>();
            builder.RegisterInstance(BiblioStorage).As<IBiblioStorage>();
            builder.RegisterInstance(FileNameExtractor).As<IFileNameExtractor>();
            builder.RegisterInstance(DetailsWorkflow).As<IDetailsWorkflow>();
            builder.RegisterInstance(CorrelationIdUpdator).As<ICorrelationIdUpdator>();
            builder.RegisterInstance(BuildDmsIntegrationWorkflows).As<IBuildDmsIntegrationWorkflows>();
            builder.RegisterInstance(ConvertApplicationDetailsToCpaXml).As<IConvertApplicationDetailsToCpaXml>();
            builder.RegisterInstance(DocumentEvents).As<DocumentEvents>();
            builder.RegisterInstance(ContentHasher).As<IContentHasher>();
            builder.RegisterInstance(PtoAccessCase).As<IPtoAccessCase>();
            builder.RegisterInstance(CheckCaseValidity).As<ICheckCaseValidity>();
            builder.RegisterInstance(RequeueMessageDates).As<IRequeueMessageDates>();

            builder.RegisterInstance(_simpleLogger);
            builder.RegisterInstance(_db).As<IRepository>();
            builder.RegisterInstance(securityContext).As<ISecurityContext>();
            builder.RegisterType<BackgroundIdentityConfiguration>().AsSelf();
            builder.RegisterInstance(completedActivity).AsSelf();
            builder.RegisterInstance(PrivatePairService).As<IPrivatePairService>();
            builder.RegisterInstance(FailureLogger).As<IPtoFailureLogger>();
            builder.RegisterInstance(UsptoScheduleSettings).As<IReadScheduleSettings>();

            builder.RegisterInstance(ApplicationList).As<IApplicationList>();
            builder.RegisterInstance(ExceptionGlobber).As<IGlobErrors>();
            builder.RegisterInstance<Func<DateTime>>(Fixture.Today).As<Func<DateTime>>();
            builder.RegisterInstance(DocumentDownloadFailure).As<IDocumentDownloadFailure>();

            AdditionalWireUp?.Invoke(builder);

            return builder.Build();
        }

        public Action<ContainerBuilder> AdditionalWireUp { get; set; }

        public void Execute(Activity activity)
        {
            DependableActivity.Execute(activity, WireUp, logJobStatusChanged: true, detailedLogging: _detailedLogging);
        }
    }
}