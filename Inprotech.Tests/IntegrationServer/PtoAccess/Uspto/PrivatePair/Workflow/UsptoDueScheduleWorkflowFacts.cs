using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Autofac;
using Dependable;
using Dependable.Dispatcher;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using NSubstitute;
using NSubstitute.Core;
using NSubstitute.ExceptionExtensions;
using ServiceStack;
using Xunit;
using Messages = Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.Messages;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Workflow
{
    [Collection("Dependable")]
    public class UsptoDueScheduleWorkflowFacts : FactBase
    {
        Schedule SetupSchedule()
        {
            return new Schedule
            {
                Name = Fixture.String()
            }.In(Db);
        }

        Session Session => Arg.Any<Session>();
        ApplicationDownload Application => Arg.Any<ApplicationDownload>();

        (DueScheduleDependableWireup runner, SingleActivity dueSchedule) SetupRunnerAndSchedule()
        {
            var schedule = SetupSchedule();
            var sessionGuid = Guid.NewGuid();

            var runner = new DueScheduleDependableWireup(Db)
                .WithPrivatePairSettings();
            return (runner, Activity.Run<DueSchedule>(_ => _.Run(schedule.Id, sessionGuid)));
        }

        const string CpaXml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n<Transaction xmlns=\"http://www.cpasoftwaresolutions.com\">\r\n  <TransactionHeader>\r\n    <SenderDetails>\r\n      <SenderRequestType>Extract Cases Response</SenderRequestType>\r\n      <SenderRequestIdentifier>NDJRCMFSGRGWITRBSWSH VQCXABMOZAKNUDHGZBPI RCSWSJSRBYIGZKFXAMRB ZRTGGSCELLBRHKPSXFFQ</SenderRequestIdentifier>\r\n      <Sender>USPTO.PrivatePAIR</Sender>\r\n      <SenderXSDVersion>1.5</SenderXSDVersion>\r\n      <SenderSoftware>\r\n        <SenderSoftwareName>Inprotech.IntegrationServer</SenderSoftwareName>\r\n      </SenderSoftware>\r\n      <SenderFilename>cpa-xml.xml</SenderFilename>\r\n    </SenderDetails>\r\n  </TransactionHeader>\r\n  <TransactionBody>\r\n    <TransactionIdentifier>958/CAL/90</TransactionIdentifier>\r\n    <TransactionContentDetails>\r\n      <TransactionCode>Case Import</TransactionCode>\r\n      <TransactionData>\r\n        <CaseDetails>\r\n          <CaseTypeCode>Property</CaseTypeCode>\r\n          <CasePropertyTypeCode>Patent</CasePropertyTypeCode>\r\n          <CaseCountryCode>US</CaseCountryCode>\r\n          <DescriptionDetails>\r\n            <DescriptionCode>Short Title</DescriptionCode>\r\n            <DescriptionText>NDJRCMFSGRGWITRBSWSH VQCXABMOZAKNUDHGZBPI RCSWSJSRBYIGZKFXAMRB ZRTGGSCELLBRHKPSXFFQ</DescriptionText>\r\n          </DescriptionDetails>\r\n          <IdentifierNumberDetails>\r\n            <IdentifierNumberCode>Application</IdentifierNumberCode>\r\n            <IdentifierNumberText>958/CAL/90</IdentifierNumberText>\r\n          </IdentifierNumberDetails>\r\n          <IdentifierNumberDetails>\r\n            <IdentifierNumberCode>Customer Number</IdentifierNumberCode>\r\n            <IdentifierNumberText>123456</IdentifierNumberText>\r\n          </IdentifierNumberDetails>\r\n          <DocumentDetails>\r\n            <Document>\r\n              <DocumentIdentifier>958CAL90-2017-12-03-00001-P.113</DocumentIdentifier>\r\n              <DocumentName>RO/113 - Request for the Recording of a Change</DocumentName>\r\n              <DocumentDate>2017-12-03</DocumentDate>\r\n              <DocumentTypeCode>PROSECUTION</DocumentTypeCode>\r\n              <DocumentNumberPages>3</DocumentNumberPages>\r\n              <DocumentComment>P.113</DocumentComment>\r\n            </Document>\r\n          </DocumentDetails>\r\n        </CaseDetails>\r\n      </TransactionData>\r\n    </TransactionContentDetails>\r\n  </TransactionBody>\r\n</Transaction>";

        (string[] applications, Message[] messages, BiblioFile[] biblio) Data()
        {
            var applications = new[]
            {
                Fixture.String(), Fixture.String()
            };
            var messages = new[]
            {
                new Message
                {
                    Meta = new Meta {ServiceId = Fixture.String(), EventDate = Fixture.Today().SetFileStoreMessageEventTimeStamp()},
                    Links = new[] {new LinkInfo {LinkType = LinkTypes.Pdf}, new LinkInfo {LinkType = LinkTypes.Biblio}}
                },
                new Message
                {
                    Meta = new Meta {ServiceId = Fixture.String(), EventDate = Fixture.Today().SetFileStoreMessageEventTimeStamp()},
                    Links = new[] {new LinkInfo {LinkType = LinkTypes.Pdf}, new LinkInfo {LinkType = LinkTypes.Biblio}}
                }
            };
            var biblioFiles = new[]
            {
                new BiblioFile
                {
                    Summary = new BiblioSummary
                    {
                        AppId = applications.First(),
                        AppNumber = applications.First()
                    },
                    ImageFileWrappers = new List<ImageFileWrapper>
                    {
                        new ImageFileWrapper {FileName = Fixture.String(), MailDate = Fixture.Today().ToString("yyyy-MM-dd"), ObjectId = Fixture.String()}
                    }
                },
                new BiblioFile
                {
                    Summary = new BiblioSummary
                    {
                        AppId = applications.Last(),
                        AppNumber = applications.Last()
                    },
                    ImageFileWrappers = new List<ImageFileWrapper>
                    {
                        new ImageFileWrapper {FileName = Fixture.String(), MailDate = Fixture.Today().ToString("yyyy-MM-dd"), ObjectId = Fixture.String()}
                    }
                }
            };
            return (applications, messages, biblioFiles);
        }

        static Func<CallInfo, IEnumerable<string>> FilesReturn(string[] applications, BiblioFile[] biblioFiles)
        {
            return call =>
            {
                var path = call.ArgAt<string>(0);
                if (path == Path.Combine("SessionFolder", "messages"))
                {
                    return new[] { Path.Combine(path, "0.json") };
                }

                var i = Array.IndexOf(applications, path);
                return new[]
                {
                    Path.Combine(call.ArgAt<string>(0), biblioFiles[i].ImageFileWrappers[0].FileName)
                };
            };
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public void ApplicationDownloadFailsIfBiblioNotDownloaded(bool downloadThrowsInsteadOfProcessApplication)
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, _) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
            };
            if (downloadThrowsInsteadOfProcessApplication)
            {
                runner.DocumentDownload.DownloadIfRequired(Application, Arg.Any<LinkInfo>(), Arg.Any<string>()).ThrowsForAnyArgs(new Exception());
            }
            else
            {
                runner.ProcessApplicationDocuments.ProcessDownloadedDocuments(Session, Application).ThrowsForAnyArgs(new Exception());
            }

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(call => new[] { call.ArgAt<string>(0) });
            runner.BufferedStringReader.Read(applications[0]).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(applications[1]).Returns(JsonConvert.SerializeObject(messages[1]));

            runner.Execute(dueSchedule);

            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.ApplicationDownloadFailed.Received(2).SaveArtifactAndNotify(Application);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.ScheduleInitialisationFailure.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ApplicationDownloadDoesNotFailWithFailureInDocumentDownload()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, _) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
            };

            runner.DocumentDownload.DownloadIfRequired(Application, Arg.Is<LinkInfo>(l => l.LinkType == LinkTypes.Pdf), Arg.Any<string>()).Throws(
                                                                                                                                                  new Exception());

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(call => new[] { call.ArgAt<string>(0) });
            runner.BufferedStringReader.Read(applications[0]).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(applications[1]).Returns(JsonConvert.SerializeObject(messages[1]));

            runner.Execute(dueSchedule);
            
            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.DocumentDownloadFailure.Received(2).NotifyFailure(Arg.Any<ApplicationDownload>(), Arg.Any<LinkInfo>(), Arg.Any<string>());
            runner.ApplicationDownloadFailed.DidNotReceive().SaveArtifactAndNotify(Application);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.ScheduleInitialisationFailure.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ApplicationDownloadsBiblioIfNewerThanDb()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, _) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
            };

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(call => new[] { call.ArgAt<string>(0) });
            runner.BufferedStringReader.Read(applications[0]).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(applications[1]).Returns(JsonConvert.SerializeObject(messages[1]));

            runner.Execute(dueSchedule);

            runner.DocumentDownload.Received(4).DownloadIfRequired(Arg.Any<ApplicationDownload>(), Arg.Any<LinkInfo>(), Arg.Any<string>());
            MatchSingleCall(applications[0], messages[0], LinkTypes.Biblio);
            MatchSingleCall(applications[0], messages[0], LinkTypes.Pdf);
            MatchSingleCall(applications[1], messages[1], LinkTypes.Biblio);
            MatchSingleCall(applications[1], messages[1], LinkTypes.Pdf);
            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.ScheduleInitialisationFailure.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();

            void MatchSingleCall(string applicationId, Message message, string linkType)
            {
                var expectedLink = message.Links.For(linkType);
                var applicationDownloadMatcher = Arg.Is<ApplicationDownload>(x => x.ApplicationId == applicationId);
                var linkMatcher = Arg.Is<LinkInfo>(x => x.Link == expectedLink.Link && x.LinkType == expectedLink.LinkType);
                runner.DocumentDownload.Received(1).DownloadIfRequired(applicationDownloadMatcher, linkMatcher, message.Meta.ServiceId);
            }
        }

        [Fact]
        public void ApplicationDoesNotDownloadsBiblioIfOlderThanDb()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, _) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
            };

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(call => new[] { call.ArgAt<string>(0) });
            runner.BufferedStringReader.Read(applications[0]).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(applications[1]).Returns(JsonConvert.SerializeObject(messages[1]));

            runner.BiblioStorage.GetFileStoreBiblioInfo(applications[0]).Returns((new FileStore(), Fixture.FutureDate()));
            runner.BiblioStorage.GetFileStoreBiblioInfo(applications[1]).Returns((new FileStore(), Fixture.PastDate()));

            runner.Execute(dueSchedule);
            var r = runner.GetTrace();

            runner.DocumentDownload.Received(3).DownloadIfRequired(Arg.Any<ApplicationDownload>(), Arg.Any<LinkInfo>(), Arg.Any<string>());
            MatchSingleCall(applications[0], messages[0], LinkTypes.Biblio, false);
            MatchSingleCall(applications[0], messages[0], LinkTypes.Pdf);
            MatchSingleCall(applications[1], messages[1], LinkTypes.Biblio);
            MatchSingleCall(applications[1], messages[1], LinkTypes.Pdf);
            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.BiblioStorage.Received(2).ValidateBiblio(Session, Arg.Any<ApplicationDownload>());
            runner.BiblioStorage.Received(1).StoreBiblio(Arg.Any<ApplicationDownload>(), Arg.Any<DateTime>());

            runner.ScheduleInitialisationFailure.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();

            void MatchSingleCall(string applicationId, Message message, string linkType, bool received = true)
            {
                var expectedLink = message.Links.For(linkType);
                var applicationDownloadMatcher = Arg.Is<ApplicationDownload>(x => x.ApplicationId == applicationId);
                var linkMatcher = Arg.Is<LinkInfo>(x => x.Link == expectedLink.Link && x.LinkType == expectedLink.LinkType);
                if (received)
                    runner.DocumentDownload.Received(1).DownloadIfRequired(applicationDownloadMatcher, linkMatcher, message.Meta.ServiceId);
                else
                    runner.DocumentDownload.DidNotReceive().DownloadIfRequired(applicationDownloadMatcher, linkMatcher, message.Meta.ServiceId);
            }
        }

        [Fact]
        public void ApplicationDownload()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, biblioFiles) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
                builder.RegisterType<ProcessApplicationDocuments>().As<IProcessApplicationDocuments>();
            };

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.ArtifactsLocationResolver.ResolveFiles(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.BiblioStorage.GetFileStoreBiblioInfo(Arg.Any<string>()).Returns(call => (new FileStore() { Path = call.ArgAt<string>(0) }, Fixture.PastDate()));
            runner.BiblioStorage.Read(Arg.Any<ApplicationDownload>()).Returns(call => biblioFiles.Single(_ => _.Summary.AppId == call.ArgAt<ApplicationDownload>(0).ApplicationId));

            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(FilesReturn(applications, biblioFiles));
            runner.BufferedStringReader.Read(Arg.Is<string>(_ => _.Contains(applications[0]))).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(Arg.Is<string>(_ => _.Contains(applications[1]))).Returns(JsonConvert.SerializeObject(messages[1]));

            runner.Execute(dueSchedule);

            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.DocumentDownload.Received(4).DownloadIfRequired(Application, Arg.Any<LinkInfo>(), Arg.Any<string>());
            runner.DetailsWorkflow.Received(2).ConvertNotifyAndSendDocsToDms(Session, Application);

            runner.ApplicationDownloadFailed.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Application);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ApplicationDownloadMockedExecution()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, _) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
            };

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(call => new[] { call.ArgAt<string>(0) });
            runner.BufferedStringReader.Read(applications[0]).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(applications[1]).Returns(JsonConvert.SerializeObject(messages[1]));

            runner.Execute(dueSchedule);

            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.DocumentDownload.Received(4).DownloadIfRequired(Application, Arg.Any<LinkInfo>(), Arg.Any<string>());
            runner.ProcessApplicationDocuments.Received(2).ProcessDownloadedDocuments(Session, Application);

            runner.ApplicationDownloadFailed.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Application);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ApplicationListFailsIfBiblioActivityNotFound()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, _) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
            };

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(call => new[] { call.ArgAt<string>(0) });
            runner.BufferedStringReader.Read(applications[0]).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(applications[1]).Returns(JsonConvert.SerializeObject(messages[1]));
            runner.BiblioStorage.ValidateBiblio(Session, Application).Throws(new Exception());

            runner.Execute(dueSchedule);

            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.ApplicationDownloadFailed.Received(2).SaveArtifactAndNotify(Application);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.ScheduleInitialisationFailure.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void FailureInMockedApplicationListHandledCorrectly()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();

            runner.AdditionalWireUp = builder => { builder.RegisterType<Messages>().As<IMessages>(); };
            runner.ApplicationList.DispatchDownload(Session).ThrowsForAnyArgs(new Exception());

            runner.Execute(dueSchedule);

            runner.ScheduleInitialisationFailure.Received(1).SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.FailureLogger.Received(2).LogSessionError(Arg.Any<ExceptionContext>(), Session);
        }

        [Fact]
        public void FailureInMockedMessageRetrieve()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();

            runner.Messages.Retrieve(Session).ThrowsForAnyArgs(new Exception());

            runner.Execute(dueSchedule);

            runner.Messages.Received(2).Retrieve(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.PrivatePairRuntimeEvents.DidNotReceiveWithAnyArgs().EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.ScheduleInitialisationFailure.Received(1).SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.FailureLogger.Received(2).LogSessionError(Arg.Any<ExceptionContext>(), Session);
        }

        [Fact]
        public void MessageRetrieve()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();

            runner.AdditionalWireUp = builder => { builder.RegisterType<Messages>().As<IMessages>(); };

            runner.Execute(dueSchedule);

            runner.ApplicationList.Received(1).DispatchDownload(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.ScheduleInitialisationFailure.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.FailureLogger.DidNotReceiveWithAnyArgs().LogSessionError(Arg.Any<ExceptionContext>(), Session);
        }

        [Fact]
        public void NormalProcessingToMockedMessageRetrieve()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            runner.Execute(dueSchedule);

            runner.Messages.Received(1).Retrieve(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.ScheduleInitialisationFailure.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.FailureLogger.DidNotReceiveWithAnyArgs().LogSessionError(Arg.Any<ExceptionContext>(), Session);
        }

        [Fact]
        public void ProcessApplication()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, biblioFiles) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
                builder.RegisterType<ProcessApplicationDocuments>().As<IProcessApplicationDocuments>();
                builder.RegisterType<DetailsWorkflow>().As<IDetailsWorkflow>();
                builder.RegisterType<NewCaseDetailsAvailableNotification>().AsSelf();
            };
            runner.BuildDmsIntegrationWorkflows.BuildPrivatePair(Application).Returns(DefaultActivity.NoOperation());

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.ArtifactsLocationResolver.ResolveFiles(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.BiblioStorage.GetFileStoreBiblioInfo(Arg.Any<string>()).Returns(call => (new FileStore() { Path = call.ArgAt<string>(0) }, Fixture.PastDate()));
            runner.BiblioStorage.Read(Arg.Any<ApplicationDownload>()).Returns(call => biblioFiles.Single(_ => _.Summary.AppId == call.ArgAt<ApplicationDownload>(0).ApplicationId));

            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(FilesReturn(applications, biblioFiles));
            runner.BufferedStringReader.Read(Arg.Is<string>(_ => _.Contains(applications[0]))).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(Arg.Is<string>(_ => _.Contains(applications[1]))).Returns(JsonConvert.SerializeObject(messages[1]));

            var xmlPath = Fixture.String();
            runner.ArtifactsLocationResolver.Resolve(Application, PtoAccessFileNames.CpaXml).Returns(xmlPath);
            runner.BufferedStringReader.Read(xmlPath).Returns(CpaXml);

            runner.Execute(dueSchedule);

            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.DocumentDownload.Received(4).DownloadIfRequired(Application, Arg.Any<LinkInfo>(), Arg.Any<string>());
            runner.FailureLogger.DidNotReceiveWithAnyArgs().LogApplicationDownloadError(Arg.Any<ExceptionContext>(), Application);
            runner.ApplicationDownloadFailed.DidNotReceiveWithAnyArgs().SaveArtifactAndNotify(Application);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ProcessApplicationFailuresAreRecorded()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, biblioFiles) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
                builder.RegisterType<ProcessApplicationDocuments>().As<IProcessApplicationDocuments>();
                builder.RegisterType<DetailsWorkflow>().As<IDetailsWorkflow>();
                builder.RegisterType<NewCaseDetailsAvailableNotification>().AsSelf();
            };
            runner.BuildDmsIntegrationWorkflows.BuildPrivatePair(Application).Returns(DefaultActivity.NoOperation());

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.ArtifactsLocationResolver.ResolveFiles(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.BiblioStorage.Read(Application).Returns(call => biblioFiles.Single(_ => _.Summary.AppId == call.ArgAt<ApplicationDownload>(0).ApplicationId));

            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(FilesReturn(applications, biblioFiles));
            runner.BufferedStringReader.Read(Arg.Is<string>(_ => _.Contains(applications[0]))).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(Arg.Is<string>(_ => _.Contains(applications[1]))).Returns(JsonConvert.SerializeObject(messages[1]));

            runner.Execute(dueSchedule);
            // Execution should fail at CpaXml conversion as they have not been configured in this Fact.

            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            // Given retry=2, the failure logger is called twice for each of the 2 applications.
            runner.FailureLogger.Received(4).LogApplicationDownloadError(Arg.Any<ExceptionContext>(), Application);

            // Each poisoned application gets a SaveArtifact and Notify
            runner.ApplicationDownloadFailed.Received(2).SaveArtifactAndNotify(Application);
        }

        [Fact]
        public void ProgressToNextApplicationIfCurrentFailed()
        {
            var (runner, dueSchedule) = SetupRunnerAndSchedule();
            var (applications, messages, biblioFiles) = Data();

            runner.AdditionalWireUp = builder =>
            {
                builder.RegisterType<Messages>().As<IMessages>();
                builder.RegisterType<ApplicationList>().As<IApplicationList>();
                builder.RegisterType<ApplicationDocuments>().As<IApplicationDocuments>();
                builder.RegisterType<ProcessApplicationDocuments>().As<IProcessApplicationDocuments>();
                builder.RegisterType<DetailsWorkflow>().As<IDetailsWorkflow>();
                builder.RegisterType<NewCaseDetailsAvailableNotification>().AsSelf();
            };

            runner.CorrelationIdUpdator.When(x => x.UpdateIfRequired(Arg.Is<Inprotech.Integration.Case>(c => c.ApplicationNumber == applications[0])))
                  .Do(x => throw new MultiplePossibleInprotechCasesException());

            runner.BuildDmsIntegrationWorkflows.BuildPrivatePair(Application).Returns(DefaultActivity.NoOperation());

            runner.FileSystem.Folders(Arg.Any<string>()).Returns(applications);

            runner.ArtifactsLocationResolver.Resolve(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.ArtifactsLocationResolver.ResolveFiles(Application).Returns(call => call.ArgAt<ApplicationDownload>(0).ApplicationId);
            runner.BiblioStorage.GetFileStoreBiblioInfo(Arg.Any<string>()).Returns(call => (new FileStore() { Path = call.ArgAt<string>(0) }, Fixture.Today()));
            runner.BiblioStorage.Read(Arg.Any<ApplicationDownload>()).Returns(call => biblioFiles.Single(_ => _.Summary.AppId == call.ArgAt<ApplicationDownload>(0).ApplicationId));

            runner.FileSystem.Files(Arg.Any<string>(), Arg.Any<string>()).Returns(FilesReturn(applications, biblioFiles));
            runner.BufferedStringReader.Read(Arg.Is<string>(_ => _.Contains(applications[0]))).Returns(JsonConvert.SerializeObject(messages[0]));
            runner.BufferedStringReader.Read(Arg.Is<string>(_ => _.Contains(applications[1]))).Returns(JsonConvert.SerializeObject(messages[1]));

            var xmlPath = Fixture.String();
            runner.ArtifactsLocationResolver.Resolve(Application, PtoAccessFileNames.CpaXml).Returns(xmlPath);
            runner.BufferedStringReader.Read(xmlPath).Returns(CpaXml);

            runner.Execute(dueSchedule);

            // Error MultiplePossibleInprotechCasesException should prevent this from being called.
            // And the error is recorded accordingly, the logger runs twice due to retry settings.
            runner.BuildDmsIntegrationWorkflows
                  .DidNotReceive()
                  .BuildPrivatePair(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applications[0]));
            runner.FailureLogger.Received(2).LogApplicationDownloadError(Arg.Any<ExceptionContext>(), Application);
            runner.ApplicationDownloadFailed.Received(1).SaveArtifactAndNotify(Application);

            // Second application in the workflow should continue to download
            // ConvertNotifyAndSendDocsToDms should call BuildDmsIntegrationWorkflow for the second application.
            runner.BuildDmsIntegrationWorkflows
                  .Received()
                  .BuildPrivatePair(Arg.Is<ApplicationDownload>(a => a.ApplicationId == applications[1]));

            runner.PrivatePairRuntimeEvents.Received(1).TrackCaseProgress(Session, applications.Length);
            runner.PrivatePairRuntimeEvents.Received(1).EndSession(Session).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ValidateInnographySettingsFailure()
        {
            var schedule = SetupSchedule();
            var sessionGuid = Guid.NewGuid();

            var runner = new DueScheduleDependableWireup(Db);
            runner.EnsureScheduleValid.When(x => x.ValidateRequiredSettings(Arg.Any<Session>())).Throw<ArgumentException>();

            var dueSchedule = Activity.Run<DueSchedule>(_ => _.Run(schedule.Id, sessionGuid));

            runner.Execute(dueSchedule);

            runner.Messages.DidNotReceiveWithAnyArgs().Retrieve(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.PrivatePairRuntimeEvents.DidNotReceiveWithAnyArgs().EndSession(Session).IgnoreAwaitForNSubstituteAssertion();

            runner.ScheduleInitialisationFailure.Received(1).SaveArtifactAndNotify(Session).IgnoreAwaitForNSubstituteAssertion();
            runner.FailureLogger.Received(2).LogSessionError(Arg.Any<ExceptionContext>(), Session);
        }
    }
}