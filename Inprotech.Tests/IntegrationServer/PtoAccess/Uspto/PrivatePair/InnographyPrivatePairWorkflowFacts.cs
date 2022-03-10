using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;
using Xunit.Abstractions;
using Messages = Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.Messages;

#pragma warning disable 1998

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    [Collection("Dependable")]
    public class InnographyPrivatePairWorkflowFacts : FactBase
    {
        readonly ITestOutputHelper _output;

        public InnographyPrivatePairWorkflowFacts(ITestOutputHelper output)
        {
            _output = output;
        }

        Schedule SetupSchedule(ScheduleType type = ScheduleType.Scheduled)
        {
            return new Schedule
            {
                Name = Fixture.String(),
                Type = type
            }.In(Db);
        }

        [Fact]
        public async Task ShouldExecuteEndSessionWhenNoMessagesDequeued()
        {
            var schedule = SetupSchedule();
            var settings = new PrivatePairExternalSettingsBuilder()
                           .WithServiceCredential()
                           .Build();

            var f = new DueScheduleDependableWireup(Db)
                    .WithMessagesRetrieveDispatchesNormally()
                    .WithPrivatePairSettings(new InnographyPrivatePairSettingsBuilder
                    {
                        PrivatePairExternalSettings = settings
                    }.Build());

            var sessionGuid = Guid.NewGuid();

            var dueSchedule = Activity.Run<DueSchedule>(_ => _.Run(schedule.Id, sessionGuid));

            f.Execute(dueSchedule);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : DueSchedule.Run (#0)
JobStatusChanged Ready                 => Running              : IEnsureScheduleValid.ValidateRequiredSettings (#0)
JobStatusChanged Ready                 => Running              : BackgroundIdentityConfiguration.ValidateExists (#0)
JobStatusChanged Ready                 => Running              : IMessages.Retrieve (#0)
JobStatusChanged Ready                 => Running              : IMessages.DispatchMessageFilesForProcessing (#0)
JobStatusChanged Ready                 => Running              : IApplicationList.DispatchDownload (#0)
JobStatusChanged Ready                 => Running              : IPrivatePairRuntimeEvents.EndSession (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), f.GetTrace());

            f.Messages.Received(1).Retrieve(Arg.Is<Session>(_ => _.ScheduleId == schedule.Id))
             .IgnoreAwaitForNSubstituteAssertion();

            f.Messages.Received(1).DispatchMessageFilesForProcessing(Arg.Is<Session>(_ => _.ScheduleId == schedule.Id))
             .IgnoreAwaitForNSubstituteAssertion();

            // No messages, therefore no sort into application bucket activities
            f.Messages.DidNotReceive().SortIntoApplicationBucket(Arg.Any<Session>(), Arg.Any<int>())
             .IgnoreAwaitForNSubstituteAssertion();

            f.PrivatePairRuntimeEvents.Received(1).EndSession(Arg.Is<Session>(_ => _.ScheduleId == schedule.Id))
             .IgnoreAwaitForNSubstituteAssertion();

            f.ApplicationList.Received(1).DispatchDownload(Arg.Any<Session>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldFailSessionWhenMessageRetrieveEncounteredUnexpectedFailures()
        {
            var schedule = SetupSchedule();
            var serviceId = Fixture.String();
            var settings = new PrivatePairExternalSettingsBuilder()
                           .WithServiceCredential(serviceId)
                           .Build();

            var f = new DueScheduleDependableWireup(Db)
                .WithPrivatePairSettings(new InnographyPrivatePairSettingsBuilder
                {
                    PrivatePairExternalSettings = settings
                }.Build());

            f.Messages.When(_ => _.Retrieve(Arg.Any<Session>()))
             .Do(_ => throw new Exception("Bummer"));

            var sessionGuid = Guid.NewGuid();

            var dueSchedule = Activity.Run<DueSchedule>(_ => _.Run(schedule.Id, sessionGuid));

            f.AdditionalWireUp = builder =>
            {
                builder.RegisterInstance(new ScheduleInitialisationFailure(f.FileSystem, f.ScheduleRuntimeEvents, f.ArtifactsLocationResolver, f.ArtefactsService, f.ExceptionGlobber)).As<IScheduleInitialisationFailure>();
            };

            f.Execute(dueSchedule);

            var trace = f.GetTrace();

            _output.WriteLine(trace);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : DueSchedule.Run (#0)
JobStatusChanged Ready                 => Running              : IEnsureScheduleValid.ValidateRequiredSettings (#0)
JobStatusChanged Ready                 => Running              : BackgroundIdentityConfiguration.ValidateExists (#0)
JobStatusChanged Ready                 => Running              : IMessages.Retrieve (#0)
Exception Bummer
JobStatusChanged Running               => Failed               : IMessages.Retrieve (#1)
JobStatusChanged Failed                => Running              : IMessages.Retrieve (#1)
Exception Bummer
JobStatusChanged ReadyToPoison         => Poisoned             : IMessages.Retrieve (#2)
JobStatusChanged Ready                 => Running              : IScheduleInitialisationFailure.SaveArtifactAndNotify (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), trace);

            f.ScheduleRuntimeEvents.Received(1).Failed(Arg.Any<Guid>(), Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldKeepDownloadedFilesWhenDispatchingMessageFails()
        {
            var schedule = SetupSchedule();
            var serviceId = Fixture.String();
            var settings = new PrivatePairExternalSettingsBuilder()
                           .WithServiceCredential(serviceId)
                           .Build();

            var f = new DueScheduleDependableWireup(Db)
                    .WithMessagesRetrieveDispatchesNormally()
                    .WithPrivatePairSettings(new InnographyPrivatePairSettingsBuilder
                    {
                        PrivatePairExternalSettings = settings
                    }.Build());

            var expectedByteStream = new byte[0];

            f.Messages.When(_ => _.DispatchMessageFilesForProcessing(Arg.Any<Session>()))
             .Do(_ =>
                     throw new IOException("Could not read the file"));

            var messageFolder = Path.Combine("SessionFolder", "messages");

            f.FileSystem.Folders("SessionFolder").Returns(new[] { messageFolder });
            f.FileSystem.Files(messageFolder, "*.json")
             .Returns(new[]
             {
                 Path.Combine("SessionFolder", "messages", "1.json"),
                 Path.Combine("SessionFolder", "messages", "2.json")
             });

            f.ArtefactsService.CreateCompressedArchive(messageFolder)
             .Returns(expectedByteStream);

            var sessionGuid = Guid.NewGuid();

            var dueSchedule = Activity.Run<DueSchedule>(_ => _.Run(schedule.Id, sessionGuid));

            f.AdditionalWireUp = builder =>
            {
                builder.RegisterInstance(new ScheduleInitialisationFailure(f.FileSystem, f.ScheduleRuntimeEvents, f.ArtifactsLocationResolver, f.ArtefactsService, f.ExceptionGlobber)).As<IScheduleInitialisationFailure>();
            };

            f.Execute(dueSchedule);

            var trace = f.GetTrace();

            _output.WriteLine(trace);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : DueSchedule.Run (#0)
JobStatusChanged Ready                 => Running              : IEnsureScheduleValid.ValidateRequiredSettings (#0)
JobStatusChanged Ready                 => Running              : BackgroundIdentityConfiguration.ValidateExists (#0)
JobStatusChanged Ready                 => Running              : IMessages.Retrieve (#0)
JobStatusChanged Ready                 => Running              : IMessages.DispatchMessageFilesForProcessing (#0)
Exception Could not read the file
JobStatusChanged Running               => Failed               : IMessages.DispatchMessageFilesForProcessing (#1)
JobStatusChanged Failed                => Running              : IMessages.DispatchMessageFilesForProcessing (#1)
Exception Could not read the file
JobStatusChanged ReadyToPoison         => Poisoned             : IMessages.DispatchMessageFilesForProcessing (#2)
JobStatusChanged Ready                 => Running              : IScheduleInitialisationFailure.SaveArtifactAndNotify (#0)
JobStatusChanged Ready                 => Running              : IPrivatePairRuntimeEvents.EndSession (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), trace);

            f.ApplicationList.Received(0).DispatchDownload(Arg.Any<Session>()).IgnoreAwaitForNSubstituteAssertion();

            f.Messages.Received(0).SortIntoApplicationBucket(Arg.Any<Session>(), Arg.Any<int>()).IgnoreAwaitForNSubstituteAssertion();
            f.ArtefactsService.Received(1).CreateCompressedArchive(messageFolder);
            f.ScheduleRuntimeEvents.Received(1).Failed(Arg.Any<Guid>(), Arg.Any<string>(), expectedByteStream);
        }

        [Fact]
        public async Task ShouldKeepDownloadedFilesWhenMessageRetrieveFails()
        {
            var schedule = SetupSchedule();
            var serviceId = Fixture.String();
            var settings = new PrivatePairExternalSettingsBuilder()
                           .WithServiceCredential(serviceId)
                           .Build();

            var f = new DueScheduleDependableWireup(Db)
                .WithPrivatePairSettings(new InnographyPrivatePairSettingsBuilder
                {
                    PrivatePairExternalSettings = settings
                }.Build());

            var expectedByteStream = new byte[0];

            f.Messages.When(_ => _.Retrieve(Arg.Any<Session>()))
             .Do(_ => throw new Exception("Bummer"));

            var messageFolder = Path.Combine("SessionFolder", "messages");

            f.FileSystem.Folders("SessionFolder").Returns(new[] { messageFolder });
            f.FileSystem.Files(messageFolder, "*.json")
             .Returns(new[]
             {
                 Path.Combine("SessionFolder", "messages", "1.json"),
                 Path.Combine("SessionFolder", "messages", "2.json")
             });

            f.ArtefactsService.CreateCompressedArchive(messageFolder)
             .Returns(expectedByteStream);

            var sessionGuid = Guid.NewGuid();

            var dueSchedule = Activity.Run<DueSchedule>(_ => _.Run(schedule.Id, sessionGuid));

            f.AdditionalWireUp = builder =>
            {
                builder.RegisterInstance(new ScheduleInitialisationFailure(f.FileSystem, f.ScheduleRuntimeEvents, f.ArtifactsLocationResolver, f.ArtefactsService, f.ExceptionGlobber)).As<IScheduleInitialisationFailure>();
            };

            f.Execute(dueSchedule);

            var trace = f.GetTrace();

            _output.WriteLine(trace);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : DueSchedule.Run (#0)
JobStatusChanged Ready                 => Running              : IEnsureScheduleValid.ValidateRequiredSettings (#0)
JobStatusChanged Ready                 => Running              : BackgroundIdentityConfiguration.ValidateExists (#0)
JobStatusChanged Ready                 => Running              : IMessages.Retrieve (#0)
Exception Bummer
JobStatusChanged Running               => Failed               : IMessages.Retrieve (#1)
JobStatusChanged Failed                => Running              : IMessages.Retrieve (#1)
Exception Bummer
JobStatusChanged ReadyToPoison         => Poisoned             : IMessages.Retrieve (#2)
JobStatusChanged Ready                 => Running              : IScheduleInitialisationFailure.SaveArtifactAndNotify (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), trace);

            f.ArtefactsService.Received(1).CreateCompressedArchive(messageFolder);
            f.ApplicationList.Received(0).DispatchDownload(Arg.Any<Session>()).IgnoreAwaitForNSubstituteAssertion();
            f.ScheduleRuntimeEvents.Received(1).Failed(Arg.Any<Guid>(), Arg.Any<string>(), expectedByteStream);
        }

        [Fact]
        public async Task ShouldSortIntoApplicationBucketsForMessagesDequeued()
        {
            var schedule = SetupSchedule();
            var settings = new PrivatePairExternalSettingsBuilder()
                           .WithServiceCredential()
                           .Build();

            var downloadedMessageFiles = new[] { 1, 2 };

            var f = new DueScheduleDependableWireup(Db)
                    .WithMessagesRetrieveDispatchesNormally()
                    .WithMessagesDispatchesFilesForProcessing(downloadedMessageFiles)
                    .WithPrivatePairSettings(new InnographyPrivatePairSettingsBuilder
                    {
                        PrivatePairExternalSettings = settings
                    }.Build());

            var sessionGuid = Guid.NewGuid();

            var dueSchedule = Activity.Run<DueSchedule>(_ => _.Run(schedule.Id, sessionGuid));

            f.Execute(dueSchedule);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : DueSchedule.Run (#0)
JobStatusChanged Ready                 => Running              : IEnsureScheduleValid.ValidateRequiredSettings (#0)
JobStatusChanged Ready                 => Running              : BackgroundIdentityConfiguration.ValidateExists (#0)
JobStatusChanged Ready                 => Running              : IMessages.Retrieve (#0)
JobStatusChanged Ready                 => Running              : IMessages.DispatchMessageFilesForProcessing (#0)
JobStatusChanged Ready                 => Running              : IMessages.SortIntoApplicationBucket (#0)
JobStatusChanged Ready                 => Running              : IMessages.SortIntoApplicationBucket (#0)
JobStatusChanged Ready                 => Running              : IApplicationList.DispatchDownload (#0)
JobStatusChanged Ready                 => Running              : IPrivatePairRuntimeEvents.EndSession (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), f.GetTrace());

            f.Messages.Received(1).SortIntoApplicationBucket(Arg.Any<Session>(), 1)
             .IgnoreAwaitForNSubstituteAssertion();

            f.Messages.Received(1).SortIntoApplicationBucket(Arg.Any<Session>(), 2)
             .IgnoreAwaitForNSubstituteAssertion();

            f.PrivatePairRuntimeEvents.Received(1).EndSession(Arg.Is<Session>(_ => _.ScheduleId == schedule.Id))
             .IgnoreAwaitForNSubstituteAssertion();

            f.ApplicationList.Received(1).DispatchDownload(Arg.Any<Session>()).IgnoreAwaitForNSubstituteAssertion();
        }
        
        static void AssertWorkflowCompletedAccordingly(string expectedTraceLog, string actualTraceLog)
        {
            var expectedTraceSequence = expectedTraceLog.Split(new[] { Environment.NewLine }, StringSplitOptions.None);
            var actualTraceSequence = actualTraceLog.Split(new[] { Environment.NewLine }, StringSplitOptions.None);

            /*
             * Dependable workflow engine would some times emit ReadyToPoison message later than
             * the compensation action being actioned on, but given the ReadyToPoison action is preceded by a Failed message
             * the order of this trace log message is unimportant in this regard.
             *
             * It is important that the number of retries, the status of the execution are all accounted for
             */

            foreach (var expected in expectedTraceSequence)
            {
                Assert.Contains(actualTraceSequence, x => x.Equals(expected));
            }
        }
    }
}