using System;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Search.Export;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class PatentsDownloadFacts
    {
        public class ProcessMethod : FactBase
        {
            readonly DataDownload _d1 = new DataDownload
            {
                Case = new EligibleCase
                {
                    ApplicationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    CaseKey = Fixture.Integer(),
                    PropertyType = KnownPropertyTypes.Patent
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
                    PropertyType = KnownPropertyTypes.Patent
                }
            };

            [Fact]
            public async Task DispatchDetailsUnavailableWhenMatchConfidenceIsLow()
            {
                var ipIdResults = new[]
                {
                    new IpIdResult
                    {
                        Confidence = "low",
                        Message = "Matched",
                        ClientIndex = _d1.Case.CaseKey.ToString(),
                        PublicData = new PatentData()
                    },
                    new IpIdResult
                    {
                        Confidence = "low",
                        Message = "Matched",
                        ClientIndex = _d2.Case.CaseKey.ToString(),
                        PublicData = new PatentData()
                    }
                };

                var validationResult = new[]
                {
                    new ValidationResult
                    {
                        ClientIndex = ipIdResults[0].ClientIndex,
                        InnographyId = ipIdResults[0].IpId
                    },
                    new ValidationResult
                    {
                        ClientIndex = ipIdResults[1].ClientIndex,
                        InnographyId = ipIdResults[1].IpId
                    }
                };

                var fixture = new PatentsDownloadFixture(Db)
                              .WithDataToDownload(_d1, _d2)
                              .WithEquivalentEligibleCase(_d1)
                              .WithEquivalentEligibleCase(_d2)
                              .WithIdsResult(ipIdResults)
                              .WithVerificationResult(validationResult);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

                var r = await fixture.Subject.Process(Fixture.Long());

                fixture.InnographyDataMatchingClient.Received(1)
                       .IpIdApi(Arg.Is<InnographyIdApiRequest>(_ => _.PatentData.Length == 2))
                       .IgnoreAwaitForNSubstituteAssertion();

                var ag = (ActivityGroup)r;

                Assert.False(ag.IsParallel);
                Assert.Single(ag.Items);
                Assert.Equal("DetailsUnavailable.DiscardNofitications", ((SingleActivity)ag.Items.Single()).TypeAndMethod());
                Assert.Equal(new[]
                {
                    _d1.Case.CaseKey,
                    _d2.Case.CaseKey
                }, (int[])((SingleActivity)ag.Items.Single()).Arguments[1]);
            }

            [Fact]
            public async Task DispatchDetailsUnavailableWhenNonMatch()
            {
                var ipIdResults = new[]
                {
                    new IpIdResult
                    {
                        Confidence = "low",
                        Message = "Matched",
                        ClientIndex = _d1.Case.CaseKey.ToString(),
                        PublicData = new PatentData()
                    }
                };

                var validationResults = new ValidationResult[0];

                var fixture = new PatentsDownloadFixture(Db)
                              .WithDataToDownload(_d1)
                              .WithEquivalentEligibleCase(_d1)
                              .WithIdsResult(ipIdResults)
                              .WithVerificationResult(validationResults);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1});

                var r = await fixture.Subject.Process(Fixture.Long());

                fixture.InnographyDataMatchingClient.Received(1)
                       .IpIdApi(Arg.Is<InnographyIdApiRequest>(_ => _.PatentData.Length == 1))
                       .IgnoreAwaitForNSubstituteAssertion();

                var ag = (ActivityGroup)r;

                Assert.False(ag.IsParallel);
                Assert.Single(ag.Items);

                var detailsUnavailable = (SingleActivity)ag.Items.Single();
                Assert.Equal("DetailsUnavailable.DiscardNofitications", detailsUnavailable.TypeAndMethod());
            }

            [Fact]
            public async Task DispatchDownloadedCaseActivityForEachMediumOrHighMatchItems()
            {
                var ipIdResults = new[]
                {
                    new IpIdResult
                    {
                        Confidence = "high",
                        Message = "Matched",
                        ClientIndex = _d1.Case.CaseKey.ToString(),
                        PublicData = new PatentData(),
                        IpId = Fixture.Integer().ToString()
                    },
                    new IpIdResult
                    {
                        Confidence = "medium",
                        Message = "Matched",
                        ClientIndex = _d2.Case.CaseKey.ToString(),
                        PublicData = new PatentData(),
                        IpId = Fixture.Integer().ToString()
                    }
                };

                var validationResult = new[]
                {
                    new ValidationResult
                    {
                        ClientIndex = ipIdResults[0].ClientIndex,
                        InnographyId = ipIdResults[0].IpId
                    },
                    new ValidationResult
                    {
                        ClientIndex = ipIdResults[1].ClientIndex,
                        InnographyId = ipIdResults[1].IpId
                    }
                };

                var fixture = new PatentsDownloadFixture(Db)
                              .WithDataToDownload(_d1, _d2)
                              .WithEquivalentEligibleCase(_d1)
                              .WithEquivalentEligibleCase(_d2)
                              .WithIdsResult(ipIdResults)
                              .WithVerificationResult(validationResult);

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1,_d2});

                var r = await fixture.Subject.Process(Fixture.Long());

                fixture.InnographyDataMatchingClient.Received(1)
                       .IpIdApi(Arg.Is<InnographyIdApiRequest>(_ => _.PatentData.Length == 2))
                       .IgnoreAwaitForNSubstituteAssertion();

                var ag = (ActivityGroup)r;

                Assert.False(ag.IsParallel);
                Assert.Equal(2, ag.Items.Count());

                var item1 = (SingleActivity)ag.Items.First();
                var item2 = (SingleActivity)ag.Items.Last();

                Assert.Equal("IDownloadedCase.Process", item1.TypeAndMethod());
                Assert.Equal(_d1.Case.CaseKey, ((DataDownload)item1.Arguments[0]).Case.CaseKey);
                Assert.True((bool)item1.Arguments[1]);

                Assert.Equal("IDownloadedCase.Process", item2.TypeAndMethod());
                Assert.Equal(_d2.Case.CaseKey, ((DataDownload)item2.Arguments[0]).Case.CaseKey);
                Assert.False((bool)item2.Arguments[1]);
            }

            [Fact]
            public async Task SendDatesAsNullOrIso8301()
            {
                var fixture = new PatentsDownloadFixture(Db)
                              .WithDataToDownload(_d1)
                              .WithEquivalentEligibleCase(_d1,
                                                          applicationDate: null,
                                                          publicationDate: Fixture.Today(),
                                                          registrationDate: Fixture.PastDate())
                              .WithIdsResult()
                              .WithVerificationResult();

                fixture.JobArgsStorage.GetAsync<DataDownload[]>(Arg.Any<long>()).ReturnsForAnyArgs(new[] {_d1});

                await fixture.Subject.Process(Fixture.Long());

                fixture.InnographyDataMatchingClient.Received(1)
                       .IpIdApi(
                                Arg.Is<InnographyIdApiRequest>(_ =>
                                                                   _.PatentData.Single().ApplicationDate == null &&
                                                                   _.PatentData.Single().PublicationDate == Fixture.Today().ToString("yyyy-MM-dd") &&
                                                                   _.PatentData.Single().GrantDate == Fixture.PastDate().ToString("yyyy-MM-dd")))
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class PatentsDownloadFixture : IFixture<PatentsDownload>
        {
            readonly InMemoryDbContext _db;
            readonly EligibleCase[] _cases = new EligibleCase[0];
            IpIdResult[] _ipIdResults;
            ValidationResult[] _validationResults;

            public PatentsDownloadFixture(InMemoryDbContext db)
            {
                _db = db;
                BufferedStringReader = Substitute.For<IBufferedStringReader>();

                InnographyDataMatchingClient = Substitute.For<IInnographyPatentsDataMatchingClient>();
                InnographyDataValidationClient = Substitute.For<IInnographyPatentsDataValidationClient>();
                EligibleInnographyItems = Substitute.For<IEligiblePatentItems>();
                JobArgsStorage = Substitute.For<IJobArgsStorage>();
                BackgroundProcessLogger = Substitute.For<IBackgroundProcessLogger<PatentsDownload>>();
                InnographyValidationRequestMapping = Substitute.For<IInnographyPatentsValidationRequestMapping>();

                Subject = new PatentsDownload(InnographyDataMatchingClient, InnographyDataValidationClient, InnographyValidationRequestMapping,
                                              EligibleInnographyItems, JobArgsStorage, BackgroundProcessLogger);
            }
            public IInnographyPatentsValidationRequestMapping InnographyValidationRequestMapping { get; set; }

            public IEligiblePatentItems EligibleInnographyItems { get; set; }

            public IJobArgsStorage JobArgsStorage { get; set; }

            public IBufferedStringReader BufferedStringReader { get; set; }

            public IInnographyPatentsDataMatchingClient InnographyDataMatchingClient { get; set; }

            public IInnographyPatentsDataValidationClient InnographyDataValidationClient { get; set; }

            public IBackgroundProcessLogger<PatentsDownload> BackgroundProcessLogger { get; set; }

            public PatentsDownload Subject { get; }

            public PatentsDownloadFixture WithDataToDownload(params DataDownload[] dataDownloads)
            {
                _ipIdResults = dataDownloads.Select(d => new IpIdResult
                {
                    ClientIndex = d.Case.CaseKey.ToString(),
                    IpId = Fixture.String(),
                    PublicData = new PatentData(),
                    Message = "high"
                }).ToArray();

                _validationResults = dataDownloads.Select(d => new ValidationResult
                {
                    ClientIndex = _cases.SingleOrDefault()?.CaseKey.ToString()
                }).ToArray();

                BufferedStringReader.Read(Arg.Any<string>())
                                    .Returns(JsonConvert.SerializeObject(dataDownloads));

                return this;
            }

            public PatentsDownloadFixture WithEquivalentEligibleCase(DataDownload dataDownload, string countryCode = null, string alternateCountryCode = null, DateTime? applicationDate = null, DateTime? publicationDate = null, DateTime? registrationDate = null)
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

                EligibleInnographyItems.Retrieve(Arg.Any<int[]>())
                                       .Returns(_db.Set<EligibleInnographyItem>());

                return this;
            }

            public PatentsDownloadFixture WithIdsResult(params IpIdResult[] results)
            {
                InnographyDataMatchingClient.IpIdApi(Arg.Any<InnographyIdApiRequest>())
                                            .Returns(
                                                     new InnographyApiResponse<IpIdResult>
                                                     {
                                                         Result = results.Any() ? results : _ipIdResults
                                                     });
                return this;
            }

            public PatentsDownloadFixture WithVerificationResult(params ValidationResult[] results)
            {
                InnographyDataValidationClient.ValidationApi(Arg.Any<PatentDataValidationRequest[]>())
                                              .Returns(
                                                       new InnographyApiResponse<ValidationResult>
                                                       {
                                                           Result = results.Any() ? results : _validationResults
                                                       });
                return this;
            }
        }
    }
}