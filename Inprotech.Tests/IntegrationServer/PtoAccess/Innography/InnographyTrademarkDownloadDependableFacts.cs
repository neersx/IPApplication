using System;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Search.Export;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using Inprotech.Tests.Dependable;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Jobs;
using NSubstitute;
using Xunit;
using Xunit.Abstractions;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    [Collection("Dependable")]
    public class InnographyTrademarkDownloadDependableFacts : FactBase
    {
        readonly ITestOutputHelper _output;

        readonly DataDownload _d1 = new DataDownload
        {
            Case = new EligibleCase
            {
                ApplicationNumber = Fixture.String(),
                PublicationNumber = Fixture.String(),
                RegistrationNumber = Fixture.String(),
                CaseKey = Fixture.Integer(),
                PropertyType = KnownPropertyTypes.TradeMark
            }
        };

        readonly DataDownload _d2 = new DataDownload
        {
            Case = new EligibleCase
            {
                ApplicationNumber = Fixture.String(),
                PublicationNumber = Fixture.String(),
                RegistrationNumber = Fixture.String(),
                CaseKey = Fixture.Integer(),
                PropertyType = KnownPropertyTypes.TradeMark
            }
        };

        public InnographyTrademarkDownloadDependableFacts(ITestOutputHelper output)
        {
            _output = output;
        }

        [Fact]
        public async Task ShouldNotDownloadImageWhenCaseFailsToDownload()
        {
            var ipIdResults = new[]
            {
                new TrademarkDataResponse
                {
                    ClientIndex = _d1.Case.CaseKey.ToString(),
                    IpId = Fixture.Integer().ToString()
                },
                new TrademarkDataResponse
                {
                    ClientIndex = _d2.Case.CaseKey.ToString(),
                    IpId = Fixture.Integer().ToString()
                }
            };

            var validationResult = new[]
            {
                new TrademarkDataValidationResult
                {
                    ClientIndex = ipIdResults[0].ClientIndex,
                    IpId = ipIdResults[0].IpId,
                    ApplicationNumber = new MatchingFieldData {StatusCode = TrademarkValidationStatusCodes.PublicDataMatchesUserData}
                },
                new TrademarkDataValidationResult
                {
                    ClientIndex = ipIdResults[1].ClientIndex,
                    IpId = ipIdResults[1].IpId,
                    ApplicationNumber = new MatchingFieldData {StatusCode = TrademarkValidationStatusCodes.PublicDataNotMatchesUserData}
                }
            };

            var f = new DownloadRequiredDependableWireup(Db)
                    .WithDataToDownload(_d1, _d2)
                    .WithEquivalentEligibleCase(_d1)
                    .WithEquivalentEligibleCase(_d2)
                    .WithIdsResult(ipIdResults)
                    .WithVerificationResult(validationResult);

            f.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

            f.DownloadedCase
             .When(x => x.Process(Arg.Any<DataDownload>(), Arg.Any<bool>()))
             .Do(_ => throw new Exception("exception in download"));

            var workflow = await f.Subject.Process(Fixture.Long());
            
            f.AdditionalWireUp = builder =>
            {
                builder.RegisterInstance(new ErrorLogger(f.LogEntry, f.DataDownloadLocationResolver)).AsSelf();
            };

            f.Execute(workflow);

            var trace = f.GetTrace();
            _output.WriteLine(trace);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : IDownloadedCase.Process (#0)
Exception exception in download
JobStatusChanged Running               => Failed               : IDownloadedCase.Process (#1)
JobStatusChanged Failed                => Running              : IDownloadedCase.Process (#1)
Exception exception in download
JobStatusChanged ReadyToPoison         => Poisoned             : IDownloadedCase.Process (#2)
JobStatusChanged Ready                 => Running              : IDownloadFailedNotification.Notify (#0)
JobStatusChanged Ready                 => Running              : IDownloadedCase.Process (#0)
Exception exception in download
JobStatusChanged Running               => Failed               : IDownloadedCase.Process (#1)
JobStatusChanged Failed                => Running              : IDownloadedCase.Process (#1)
Exception exception in download
JobStatusChanged ReadyToPoison         => Poisoned             : IDownloadedCase.Process (#2)
JobStatusChanged Ready                 => Running              : IDownloadFailedNotification.Notify (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), trace);

            f.DownloadedCase
             .Received()
             .Process(Arg.Any<DataDownload>(), Arg.Any<bool>())
             .IgnoreAwaitForNSubstituteAssertion();

            f.DownloadFailedNotification
             .Received(2)
             .Notify(Arg.Any<DataDownload>())
             .IgnoreAwaitForNSubstituteAssertion();

            f.InnographyTrademarksImage
             .DidNotReceive()
             .Download(Arg.Any<EligibleCase>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>());
        }

        [Fact]
        public async Task ShouldProcessAndDownloadImage()
        {
            var ipIdResults = new[]
            {
                new TrademarkDataResponse
                {
                    ClientIndex = _d1.Case.CaseKey.ToString(),
                    IpId = Fixture.Integer().ToString()
                },
                new TrademarkDataResponse
                {
                    ClientIndex = _d2.Case.CaseKey.ToString(),
                    IpId = Fixture.Integer().ToString()
                }
            };

            var validationResult = new[]
            {
                new TrademarkDataValidationResult
                {
                    ClientIndex = ipIdResults[0].ClientIndex,
                    IpId = ipIdResults[0].IpId,
                    ApplicationNumber = new MatchingFieldData {StatusCode = TrademarkValidationStatusCodes.PublicDataMatchesUserData}
                },
                new TrademarkDataValidationResult
                {
                    ClientIndex = ipIdResults[1].ClientIndex,
                    IpId = ipIdResults[1].IpId,
                    ApplicationNumber = new MatchingFieldData {StatusCode = TrademarkValidationStatusCodes.PublicDataNotMatchesUserData}
                }
            };

            var f = new DownloadRequiredDependableWireup(Db)
                    .WithDataToDownload(_d1, _d2)
                    .WithEquivalentEligibleCase(_d1)
                    .WithEquivalentEligibleCase(_d2)
                    .WithIdsResult(ipIdResults)
                    .WithVerificationResult(validationResult);

            f.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

            var workflow = await f.Subject.Process(Fixture.Long());
            
            f.AdditionalWireUp = builder =>
            {
                builder.RegisterInstance(new ErrorLogger(f.LogEntry, f.DataDownloadLocationResolver)).AsSelf();
            };

            f.Execute(workflow);

            var trace = f.GetTrace();
            _output.WriteLine(trace);

            AssertWorkflowCompletedAccordingly(@"
JobStatusChanged Ready                 => Running              : IDownloadedCase.Process (#0)
JobStatusChanged Ready                 => Running              : IInnographyTrademarksImage.Download (#0)
JobStatusChanged Ready                 => Running              : IDownloadedCase.Process (#0)
JobStatusChanged Ready                 => Running              : IInnographyTrademarksImage.Download (#0)
JobStatusChanged Ready                 => Running              : CompletedActivity.SetCompleted (#0)".TrimStart(), trace);

            f.DownloadedCase
             .Received()
             .Process(Arg.Any<DataDownload>(), Arg.Any<bool>())
             .IgnoreAwaitForNSubstituteAssertion();

            f.DownloadFailedNotification
             .DidNotReceive()
             .Notify(Arg.Any<DataDownload>())
             .IgnoreAwaitForNSubstituteAssertion();

            f.InnographyTrademarksImage
             .Received()
             .Download(Arg.Any<EligibleCase>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>());
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

    public class DownloadRequiredDependableWireup : IFixture<TrademarksDownload>
    {
        readonly InMemoryDbContext _db;
        readonly EligibleCase[] _cases = new EligibleCase[0];
        TrademarkDataResponse[] _ipIdResults;
        TrademarkDataValidationResult[] _validationResults;

        public DownloadRequiredDependableWireup(InMemoryDbContext db)
        {
            _db = db;
            TradeMarksImageClient = Substitute.For<IInnographyTradeMarksImageClient>();
            PtoAccessCase = Substitute.For<IPtoAccessCase>();
            InnographyIdUpdater = Substitute.For<IInnographyIdUpdater>();
            DetailsAvailable = Substitute.For<IDetailsAvailable>();
            NewCaseDetailsNotification = Substitute.For<INewCaseDetailsNotification>();
            RuntimeEvents = Substitute.For<IRuntimeEvents>();
            StreamWriter = Substitute.For<IChunkedStreamWriter>();
            Repository = Substitute.For<IRepository>();
            LogEntry = Substitute.For<ILogEntry>();
            DownloadedCase = Substitute.For<IDownloadedCase>();
            GlobErrors = Substitute.For<IGlobErrors>();
            ArtefactsService = Substitute.For<IArtifactsService>();
            ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();
            InnographyTrademarksImage = Substitute.For<IInnographyTrademarksImage>();
            DownloadFailedNotification = Substitute.For<IDownloadFailedNotification>();
            MatchingClient = Substitute.For<IInnographyTradeMarksDataMatchingClient>();
            DvClient = Substitute.For<IInnographyTradeMarksDataValidationClient>();
            RequestMapping = Substitute.For<IInnographyTrademarksValidationRequestMapping>();
            EligibleTrademarkItems = Substitute.For<IEligibleTrademarkItems>();
            JobArgsStorage = Substitute.For<IJobArgsStorage>();
            BackgroundLogger = Substitute.For<IBackgroundProcessLogger<TrademarksDownload>>();
            DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
            Subject = new TrademarksDownload(MatchingClient, DvClient, RequestMapping, EligibleTrademarkItems, JobArgsStorage, BackgroundLogger, DataDownloadLocationResolver);
        }

        public IInnographyTradeMarksDataMatchingClient MatchingClient { get; set; }
        public IInnographyTradeMarksDataValidationClient DvClient { get; set; }
        public IInnographyTrademarksValidationRequestMapping RequestMapping { get; set; }
        public IEligibleTrademarkItems EligibleTrademarkItems { get; set; }
        public IJobArgsStorage JobArgsStorage { get; set; }
        public IBackgroundProcessLogger<TrademarksDownload> BackgroundLogger { get; set; }
        public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }
        public IGlobErrors GlobErrors { get; set; }
        public IArtifactsService ArtefactsService { get; set; }
        public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; set; }
        public IInnographyIdUpdater InnographyIdUpdater { get; set; }
        public IDetailsAvailable DetailsAvailable { get; set; }
        public INewCaseDetailsNotification NewCaseDetailsNotification { get; set; }
        public IRuntimeEvents RuntimeEvents { get; set; }

        public ILogEntry LogEntry { get; set; }

        public IDownloadedCase DownloadedCase { get; set; }

        public IInnographyTrademarksImage InnographyTrademarksImage { get; set; }

        public IDownloadFailedNotification DownloadFailedNotification { get; set; }

        public IInnographyTradeMarksImageClient TradeMarksImageClient { get; set; }
        public IPtoAccessCase PtoAccessCase { get; set; }
        public IChunkedStreamWriter StreamWriter { get; set; }
        public IRepository Repository { get; set; }

        public TrademarksDownload Subject { get; set; }

        public string GetTrace() => _simpleLogger.Collected();

        SimpleLogger _simpleLogger;

        public Action<ContainerBuilder> AdditionalWireUp { get; set; }

        public DownloadRequiredDependableWireup WithDataToDownload(params DataDownload[] dataDownloads)
        {
            _ipIdResults = dataDownloads.Select(d => new TrademarkDataResponse
            {
                ClientIndex = d.Case.CaseKey.ToString(),
                IpId = Fixture.String()
            }).ToArray();

            _validationResults = dataDownloads.Select(d => new TrademarkDataValidationResult
            {
                ClientIndex = _cases.SingleOrDefault()?.CaseKey.ToString()
            }).ToArray();

            return this;
        }

        public DownloadRequiredDependableWireup WithEquivalentEligibleCase(DataDownload dataDownload, string countryCode = null, string alternateCountryCode = null, DateTime? applicationDate = null, DateTime? publicationDate = null, DateTime? registrationDate = null)
        {
            new EligibleInnographyItem
            {
                    ApplicationNumber = dataDownload.Case.ApplicationNumber,
                    RegistrationNumber = dataDownload.Case.RegistrationNumber,
                    PublicationNumber = dataDownload.Case.PublicationNumber,
                    CountryCode = countryCode,
                    CaseKey = dataDownload.Case.CaseKey,
                    ApplicationDate = applicationDate,
                    RegistrationDate = registrationDate,
                    PublicationDate = publicationDate
            }.In(_db);

            EligibleTrademarkItems.Retrieve(Arg.Any<int[]>())
                                       .Returns(_db.Set<EligibleInnographyItem>());

            return this;
        }

        public DownloadRequiredDependableWireup WithIdsResult(params TrademarkDataResponse[] results)
        {
            MatchingClient.MatchingApi(Arg.Any<TrademarkDataRequest[]>())
                                            .Returns(
                                                     new InnographyApiResponse<TrademarkDataResponse>
                                                     {
                                                         Result = results.Any() ? results : _ipIdResults
                                                     });
            return this;
        }

        public DownloadRequiredDependableWireup WithVerificationResult(params TrademarkDataValidationResult[] results)
        {
            DvClient.ValidationApi(Arg.Any<TrademarkDataValidationRequest[]>())
                                              .Returns(
                                                       new InnographyApiResponse<TrademarkDataValidationResult>
                                                       {
                                                           Result = results.Any() ? results : _validationResults
                                                       });
            return this;
        }

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();
            _simpleLogger = new SimpleLogger();
            builder.RegisterInstance(_simpleLogger);
            builder.RegisterInstance(ScheduleRuntimeEvents).As<IScheduleRuntimeEvents>();
            builder.RegisterInstance(ArtefactsService).As<IArtifactsService>();
            builder.RegisterInstance(GlobErrors).As<IGlobErrors>();
            builder.RegisterInstance(PtoAccessCase).As<IPtoAccessCase>();
            builder.RegisterInstance(DataDownloadLocationResolver).As<IDataDownloadLocationResolver>();
            builder.RegisterInstance(BackgroundLogger).As<IBackgroundProcessLogger<TrademarksDownload>>();
            builder.RegisterInstance(JobArgsStorage).As<IJobArgsStorage>();
            builder.RegisterInstance(EligibleTrademarkItems).As<IEligibleTrademarkItems>();
            builder.RegisterInstance(RequestMapping).As<IInnographyTrademarksValidationRequestMapping>();
            builder.RegisterInstance(EligibleTrademarkItems).As<IEligibleTrademarkItems>();
            builder.RegisterInstance(DvClient).As<IInnographyTradeMarksDataValidationClient>();
            builder.RegisterInstance(MatchingClient).As<IInnographyTradeMarksDataMatchingClient>();
            builder.RegisterInstance(TradeMarksImageClient).As<IInnographyTradeMarksImageClient>();
            builder.RegisterInstance(PtoAccessCase).As<IPtoAccessCase>();
            builder.RegisterInstance(StreamWriter).As<IChunkedStreamWriter>();
            builder.RegisterInstance(_db).As<IRepository>();
            builder.RegisterInstance(InnographyIdUpdater).As<IInnographyIdUpdater>();
            builder.RegisterInstance(DetailsAvailable).As<IDetailsAvailable>();
            builder.RegisterInstance(NewCaseDetailsNotification).As<INewCaseDetailsNotification>();
            builder.RegisterInstance(RuntimeEvents).As<IRuntimeEvents>();
            builder.RegisterInstance(DownloadedCase).As<IDownloadedCase>();
            builder.RegisterInstance(InnographyTrademarksImage).As<IInnographyTrademarksImage>();
            builder.RegisterType<DownloadRequired>().AsSelf();
            builder.RegisterInstance(DownloadFailedNotification).As<IDownloadFailedNotification>();
            builder.RegisterInstance<Func<DateTime>>(Fixture.Today).As<Func<DateTime>>();
            builder.RegisterInstance(completedActivity).AsSelf();
            AdditionalWireUp?.Invoke(builder);
            return builder.Build();
        }

        public void Execute(Activity activity)
        {
            DependableActivity.Execute(activity, WireUp, logJobStatusChanged: true);
        }
    }
}
