using System;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Search.Export;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.Tests.Dependable;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;
using Xunit.Abstractions;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    [Collection("Dependable")]
    public class InnographyDownloadRequiredDependableFacts : FactBase
    {
        readonly ITestOutputHelper _output;

        public InnographyDownloadRequiredDependableFacts(ITestOutputHelper output)
        {
            _output = output;
        }

        [Fact]
        public async Task ShouldProcessPatentsAndTradeMarksDownload()
        {
            var f = new DependableWireUp();

            var workflow = await f.Subject.FromInnography(Fixture.String());

            f.AdditionalWireUp = builder =>
            {
                builder.RegisterInstance(new ErrorLogger(f.LogEntry, f.LocationResolver)).AsSelf();
            };

            f.Execute(workflow);

            var trace = f.GetTrace();

            _output.WriteLine(trace);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : IPatentsDownload.Process (#0)
JobStatusChanged Ready                 => Running              : IJobArgsStorage.CleanUpTempStorage (#0)
JobStatusChanged Ready                 => Running              : ITrademarksDownload.Process (#0)
JobStatusChanged Ready                 => Running              : IJobArgsStorage.CleanUpTempStorage (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), trace);

            f.PatentsDownload
             .Received(1)
             .Process(Arg.Any<long>());

            f.TrademarksDownload
             .Received(1)
             .Process(Arg.Any<long>());

            f.JobArgsStorage
             .Received(2)
             .CleanUpTempStorage(Arg.Any<long>());
        }

        [Fact]
        public async Task ShouldProcessTrademarksEvenIfExceptionOccursInPatentsDownload()
        {
            var f = new DependableWireUp();

            var workflow = await f.Subject.FromInnography(Fixture.String());

            f.AdditionalWireUp = builder =>
            {
                builder.RegisterInstance(new ErrorLogger(f.LogEntry, f.LocationResolver)).AsSelf();
            };

            f.PatentsDownload
             .When(x => x.Process(Arg.Any<long>()))
             .Do(_ => throw new Exception("exception in patents download"));

            f.Execute(workflow);

            var trace = f.GetTrace();

            _output.WriteLine(trace);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : IPatentsDownload.Process (#0)
Exception exception in patents download
JobStatusChanged Running               => Failed               : IPatentsDownload.Process (#1)
JobStatusChanged Failed                => Running              : IPatentsDownload.Process (#1)
Exception exception in patents download
JobStatusChanged ReadyToPoison         => Poisoned             : IPatentsDownload.Process (#2)
JobStatusChanged Ready                 => Running              : ITrademarksDownload.Process (#0)
JobStatusChanged Ready                 => Running              : IJobArgsStorage.CleanUpTempStorage (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), trace);

            f.PatentsDownload
             .Received(2)
             .Process(Arg.Any<long>());

            f.TrademarksDownload
             .Received(1)
             .Process(Arg.Any<long>());

            f.JobArgsStorage
             .Received(1)
             .CleanUpTempStorage(Arg.Any<long>());
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

    public class DependableWireUp : IFixture<DownloadRequired>
    {
        public DependableWireUp()
        {
            PatentsDownload = Substitute.For<IPatentsDownload>();
            TrademarksDownload = Substitute.For<ITrademarksDownload>();
            LogEntry = Substitute.For<ILogEntry>();
            LocationResolver = Substitute.For<IDataDownloadLocationResolver>();
            JobArgsStorage = Substitute.For<IJobArgsStorage>();
            JobArgsStorage.CreateAsync(Arg.Any<long>()).Returns(Fixture.Long());
            BufferedStringReader = Substitute.For<IBufferedStringReader>();
            BufferedStringReader.Read(Arg.Any<string>()).Returns(JsonConvert.SerializeObject(SetUpCases()));
            Subject = new DownloadRequired(BufferedStringReader, JobArgsStorage);
        }
        public IBufferedStringReader BufferedStringReader { get; set; }
        public IJobArgsStorage JobArgsStorage { get; set; }
        public IPatentsDownload PatentsDownload { get; set; }
        public ITrademarksDownload TrademarksDownload { get; set; }
        public ILogEntry LogEntry { get; set; }
        public IDataDownloadLocationResolver LocationResolver { get; set; }

        public DownloadRequired Subject { get; }

        public string GetTrace() => _simpleLogger.Collected();

        SimpleLogger _simpleLogger;

        public Action<ContainerBuilder> AdditionalWireUp { get; set; }

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();
            builder.RegisterInstance(PatentsDownload).As<IPatentsDownload>();
            builder.RegisterInstance(TrademarksDownload).As<ITrademarksDownload>();
            builder.RegisterInstance(BufferedStringReader).As<IBufferedStringReader>();
            builder.RegisterInstance(JobArgsStorage).As<IJobArgsStorage>();
            _simpleLogger = new SimpleLogger();
            builder.RegisterInstance(LogEntry).As<ILogEntry>();
            builder.RegisterInstance(LocationResolver).As<IDataDownloadLocationResolver>();
            builder.RegisterInstance(_simpleLogger);
            builder.RegisterType<DownloadRequired>().AsSelf();
            builder.RegisterInstance(completedActivity).AsSelf();
            AdditionalWireUp?.Invoke(builder);
            return builder.Build();
        }

        public void Execute(Activity activity)
        {
            DependableActivity.Execute(activity, WireUp, logJobStatusChanged: true);
        }

        DataDownload[] SetUpCases()
        {
            return new[]
            {
                new DataDownload
                {
                    Id = Guid.NewGuid(),
                    Case = new EligibleCase(Fixture.Integer(), "AU")
                    {
                        PropertyType = KnownPropertyTypes.Patent
                    }
                },
                new DataDownload
                {
                    Id = Guid.NewGuid(),
                    Case = new EligibleCase(Fixture.Integer(), "UK")
                    {
                        PropertyType = KnownPropertyTypes.TradeMark
                    }
                }
            };
        }
    }
}
