using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Forecast;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

[assembly: InternalsVisibleTo("Inprotech.Web")]

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingRequestControllerFacts : FactBase
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ShouldGetPolicingRequest()
            {
                var requestId = Fixture.Integer();
                var f = new PolicingRequestControllerFixture(Db)
                        .WithEmptyRequestItem()
                        .WithAffectedCases();

                f.Subject.Get(requestId);

                f.PolicingRequestReader.Received(1).FetchAndConvert(requestId);
                f.PolicingRequestSps.DidNotReceiveWithAnyArgs().GetNoOfAffectedCases(requestId);
            }
        }

        public class ControllerFacts
        {
            [Fact]
            public void RequiresMaintainPolicingRequestTask()
            {
                var r = TaskSecurity.Secures<PolicingRequestController>(ApplicationTask.MaintainPolicingRequest);

                Assert.True(r);
            }
        }

        public class SaveRequestMethod : FactBase
        {
            [Fact]
            public void ShouldCheckTitleToBeNotMoreThan40Characters()
            {
                var f = new PolicingRequestControllerFixture(Db);

                var model = new PolicingRequestItem {Title = "aaaaabbbbbcccccdddddaaaaabbbbbcccccdddddEXTRA"};

                var result = f.Subject.SaveRequest(model);
                Assert.Equal("error", result.Status);
                Assert.Equal("title", result.Error.Key);
                Assert.Equal("maxlength", result.Error.Value);
            }

            [Fact]
            public void ShouldReturnErrorForDuplicateRequestTiltleWhileAddingNew()
            {
                var f = new PolicingRequestControllerFixture(Db).WithInitialData();

                var model = new PolicingRequestItem {Title = "test"};

                var result = f.Subject.SaveRequest(model);
                Assert.Equal("error", result.Status);
                Assert.Equal("title", result.Error.Key);
                Assert.Equal("notunique", result.Error.Value);

                Assert.True(Db.Set<PolicingRequest>().Count() == 2);
            }

            [Fact]
            public void ShouldRevalidateCharacteristicsBeforeSaving()
            {
                var f = new PolicingRequestControllerFixture(Db).WithValidCharacteristics()
                                                                .WithIsTitleUnique();

                var model = new PolicingRequestItem {Title = "A"};

                f.Subject.SaveRequest(model);
                f.PolicingCharacteristicsService.ReceivedWithAnyArgs(1).ValidateCharacteristics(Arg.Any<InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics>());
            }

            [Fact]
            public void ShouldRevalidateCharacteristicsBeforeUpdating()
            {
                var f = new PolicingRequestControllerFixture(Db).WithInitialData()
                                                                .WithValidCharacteristics()
                                                                .WithIsTitleUnique();

                var model = new PolicingRequestItem {RequestId = 1, Title = "A"};

                f.Subject.SaveRequest(model);
                f.PolicingCharacteristicsService.ReceivedWithAnyArgs(1).ValidateCharacteristics(Arg.Any<InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics>());
            }

            [Fact]
            public void ShouldSavePolicingRequest()
            {
                var f = new PolicingRequestControllerFixture(Db)
                        .WithValidCharacteristics()
                        .WithIsTitleUnique();

                var model = new PolicingRequestItem {Title = "test"};

                f.Subject.SaveRequest(model);
                Assert.True(Db.Set<PolicingRequest>().Any());
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldCheckTitleToBeNonEmpty()
            {
                var f = new PolicingRequestControllerFixture(Db);

                var model = new PolicingRequestItem {RequestId = 1, Title = null};

                var result = f.Subject.Update(1, model);
                Assert.Equal("error", result.Status);
                Assert.Equal("title", result.Error.Key);
                Assert.Equal("required", result.Error.Value);
            }

            [Fact]
            public void ShouldReturnErrorForDuplicateRequestTiltleWhileUpdating()
            {
                var f = new PolicingRequestControllerFixture(Db)
                    .WithInitialData();

                var model = new PolicingRequestItem {RequestId = 1, Title = "test2"};

                var result = f.Subject.Update(1, model);
                Assert.Equal("error", result.Status);
                Assert.Equal("title", result.Error.Key);
                Assert.Equal("notunique", result.Error.Value);
            }

            [Fact]
            public void ShouldUpdatePolicingRequest()
            {
                var f = new PolicingRequestControllerFixture(Db).WithInitialData()
                                                                .WithValidCharacteristics()
                                                                .WithIsTitleUnique();

                var model = new PolicingRequestItem {Title = "Updated", RequestId = 1};
                f.PolicingRequestSps.GetNoOfAffectedCases(1).Returns(new PolicingRequestAffectedCases {IsSupported = true, NoOfCases = 3});

                var result = f.Subject.Update(1, model);
                Assert.Equal("success", result.Status);
                Assert.Equal(1, result.RequestId);

                var request = Db.Set<PolicingRequest>().Single(_ => _.RequestId == 1);
                Assert.Equal("Updated", request.Name);
            }
        }

        public class DeleteRequestsMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteAllPolicingRequestsAndReturnSuccess()
            {
                var f = new PolicingRequestControllerFixture(Db).WithInitialData(1, 2);

                var result = f.Subject.DeleteRequests(new[] {1, 2});
                Assert.Equal("success", result.Status);
                Assert.Empty(result.NotDeletedIds);
                Assert.Null(result.Error);

                var requests = Db.Set<PolicingRequest>().ToArray();
                Assert.Empty(requests);
            }

            [Fact]
            public void ShouldDeleteDeletablePolicingRequestsAndReturnPartialSuccess()
            {
                var f = new PolicingRequestControllerFixture(Db).WithInitialData(1, 2);
                new PolicingLog {PolicingName = "test1", FinishDateTime = null, FailMessage = null, StartDateTime = Fixture.Today()}.In(Db);

                var result = f.Subject.DeleteRequests(new[] {1, 2});
                Assert.Equal("partialSuccess", result.Status);
                Assert.Contains(1, (int[]) result.NotDeletedIds);
                Assert.DoesNotContain(2, (int[]) result.NotDeletedIds);
                Assert.Equal("alreadyInUse", result.Error);

                var requests = Db.Set<PolicingRequest>().ToArray();
                Assert.Single(requests);
                Assert.Equal(1, requests.First().RequestId);
            }

            [Fact]
            public void ShouldReturnErrorSinceNoDeletableRequests()
            {
                var f = new PolicingRequestControllerFixture(Db).WithInitialData(1, 2);
                new PolicingLog {PolicingName = "test1", FinishDateTime = null, FailMessage = null, StartDateTime = Fixture.Today()}.In(Db);
                new PolicingLog {PolicingName = "test2", FinishDateTime = null, FailMessage = null, StartDateTime = Fixture.Today()}.In(Db);

                var result = f.Subject.DeleteRequests(new[] {1, 2});
                Assert.Equal("error", result.Status);
                Assert.Contains(1, (int[]) result.NotDeletedIds);
                Assert.Contains(2, (int[]) result.NotDeletedIds);
                Assert.Equal("alreadyInUse", result.Error);

                var requests = Db.Set<PolicingRequest>().ToArray();
                Assert.Equal(2, requests.Length);
            }
        }

        public class RunNowMethod : FactBase
        {
            [Fact]
            public async Task ShouldRunPolicingRequestNowWithAffectedCases()
            {
                var requestId = Fixture.Integer();

                var f = new PolicingRequestControllerFixture(Db).WithInitialData(requestId);

                await f.Subject.RunNow(requestId, PolicingRequestController.PolicingRequestRunType.SeparateCases);

                f.PolicingRequestSps.Received(1).CreatePolicingForCasesFromRequest(requestId)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldRunPolicingRequestNowWithSingleRequest()
            {
                var f = new PolicingRequestControllerFixture(Db).WithInitialData();

                await f.Subject.RunNow(1, PolicingRequestController.PolicingRequestRunType.OneRequest);

                f.PolicingEngine.Received(1).PoliceAsync(Fixture.Today(), 0);
            }
        }

        public class RetrieveMethod : FactBase
        {
            [Fact]
            public void ShouldCallProcedureToCheckFeatureAvailability()
            {
                var f = new PolicingRequestControllerFixture(Db).WithInitialData().WithAffectedCases();
                f.Subject.Retrieve();
                f.PolicingRequestSps.Received(1).GetNoOfAffectedCases(0, true);
            }
        }

        public class PolicingRequestsMethod : FactBase
        {
            [Fact]
            public void ShouldReturnPolicingRequests()
            {
                var f = new PolicingRequestControllerFixture(Db);
                new PolicingRequest(null)
                {
                    RequestId = 1,
                    DateEntered = Fixture.Today(),
                    SequenceNo = 0,
                    IsSystemGenerated = 0,
                    Name = "test"
                }.In(Db);
                new PolicingRequest(null)
                {
                    RequestId = 2,
                    Name = "test2",
                    IsSystemGenerated = 1
                }.In(Db);

                var data = Db.Set<PolicingRequest>().Where(_ => _.RequestId == 1);
                f.PolicingRequestReader.FetchAll(Arg.Any<int[]>()).Returns(data);

                var r = f.Subject.PolicingRequests(null);

                Assert.Equal(1, r.Data.Count());
            }
        }

        public class ValidationMethods : FactBase
        {
            [Fact]
            public void ShouldCallCharacteristicsValidator()
            {
                var characteristics = new InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics
                {
                    Action = "A",
                    CaseCategory = "C",
                    CaseType = "T",
                    DateOfLaw = "D",
                    Jurisdiction = "J",
                    PropertyType = "P",
                    SubType = "S"
                };
                var f = new PolicingRequestControllerFixture(Db);

                f.Subject.ValidateCharacteristics(characteristics);

                f.PolicingCharacteristicsService.Received(1).ValidateCharacteristics(characteristics);
            }

            [Fact]
            public void ShouldGetNextLettersDate()
            {
                var f = new PolicingRequestControllerFixture(Db);

                var r = f.Subject.GetLettersDate(Fixture.PastDate());
                Assert.Equal(r, Fixture.Today());
            }
        }

        public class PolicingRequestControllerFixture : IFixture<PolicingRequestController>
        {
            readonly InMemoryDbContext _db;
            public IEnumerable<PolicingRequest> Data;
            public IPolicingCharacteristicsService PolicingCharacteristicsService;
            public IPolicingEngine PolicingEngine;
            public IPolicingRequestReader PolicingRequestReader;
            public IPolicingRequestSps PolicingRequestSps;

            public PolicingRequestControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                var resolver = Substitute.For<IPreferredCultureResolver>();

                PolicingEngine = Substitute.For<IPolicingEngine>();

                PolicingRequestReader = Substitute.For<IPolicingRequestReader>();

                PolicingRequestSps = Substitute.For<IPolicingRequestSps>();

                PolicingCharacteristicsService = Substitute.For<IPolicingCharacteristicsService>();

                var policingRequestDateCalculator = Substitute.For<IPolicingRequestDateCalculator>();

                var now = Substitute.For<Func<DateTime>>();
                now().ReturnsForAnyArgs(Fixture.Today());

                policingRequestDateCalculator.GetLettersDate(Arg.Any<DateTime>()).Returns(Fixture.Today());

                Subject = new PolicingRequestController(_db, resolver, now, PolicingEngine, PolicingRequestReader, PolicingRequestSps, policingRequestDateCalculator, PolicingCharacteristicsService);
            }

            public PolicingRequestController Subject { get; }

            public PolicingRequestControllerFixture WithInitialData(int requestId = 1)
            {
                new PolicingRequest(null)
                {
                    RequestId = requestId,
                    DateEntered = Fixture.Today(),
                    SequenceNo = 0,
                    IsSystemGenerated = 0,
                    Name = "test"
                }.In(_db);
                new PolicingRequest(null)
                {
                    RequestId = requestId + 1,
                    Name = "test2"
                }.In(_db);
                Data = _db.Set<PolicingRequest>().ToArray();

                var dataToReturn = _db.Set<PolicingRequest>().Single(_ => _.RequestId == requestId);

                PolicingRequestReader.Fetch(Arg.Any<int>()).Returns(dataToReturn);

                return this;
            }

            public PolicingRequestControllerFixture WithInitialData(params int[] requestIds)
            {
                foreach (var i in requestIds)
                {
                    new PolicingRequest(null)
                    {
                        RequestId = i,
                        DateEntered = Fixture.Today(),
                        IsSystemGenerated = 0,
                        Name = "test" + i
                    }.In(_db);
                }

                Data = _db.Set<PolicingRequest>();

                PolicingRequestReader.FetchAll(Arg.Any<int[]>())
                                     .Returns(_db.Set<PolicingRequest>().Where(_ => requestIds.Contains(_.RequestId)));

                return this;
            }

            public PolicingRequestControllerFixture WithValidCharacteristics()
            {
                var data = new
                {
                    CaseCategory = new ValidatedCharacteristic(),
                    PropertyType = new ValidatedCharacteristic(),
                    Action = new ValidatedCharacteristic(),
                    SubType = new ValidatedCharacteristic()
                };
                PolicingCharacteristicsService.ValidateCharacteristics(Arg.Any<InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics>())
                                              .Returns(data);

                return this;
            }

            public PolicingRequestControllerFixture WithIsTitleUnique(bool result = true)
            {
                PolicingRequestReader.IsTitleUnique(Arg.Any<string>(), Arg.Any<int?>()).Returns(result);

                return this;
            }

            public PolicingRequestControllerFixture WithEmptyRequestItem()
            {
                PolicingRequestReader.FetchAndConvert(Arg.Any<int>()).ReturnsForAnyArgs(new PolicingRequestItem());
                return this;
            }

            public PolicingRequestControllerFixture WithAffectedCases()
            {
                PolicingRequestSps.GetNoOfAffectedCases(Arg.Any<int>()).ReturnsForAnyArgs(new PolicingRequestAffectedCases
                {
                    NoOfCases = 5,
                    IsSupported = true
                });

                return this;
            }
        }
    }
}