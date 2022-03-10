using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingRequestLogReaderFacts
    {
        public class RetrieveMethod : FactBase
        {
            [Fact]
            public void ReturnsAll()
            {
                new PolicingLog
                {
                    StartDateTime = Fixture.Today(),
                    PolicingName = Fixture.String()
                }.In(Db);

                Assert.Equal(1, new PolicingRequestLogReaderFixture(Db).Subject.Retrieve().Count());
            }

            [Fact]
            public void ReturnsPolicingQueueItem()
            {
#pragma warning disable 618
                var p = new PolicingLog
#pragma warning restore 618
                {
                    StartDateTime = Fixture.Today(),
                    FailMessage = Fixture.String(),
                    FinishDateTime = Fixture.Today(),
                    FromDate = Fixture.Today(),
                    NumberOfDays = Fixture.Short(),
                    PolicingName = Fixture.String()
                }.In(Db);

                var r = new PolicingRequestLogReaderFixture(Db).Subject.Retrieve().Single();

                Assert.Equal(p.StartDateTime, r.StartDateTime);
                Assert.Equal(p.FailMessage, r.FailMessage);
                Assert.Equal(p.FinishDateTime, r.FinishDateTime);
                Assert.Equal(p.FromDate, r.FromDate);
                Assert.Equal(p.NumberOfDays, r.NumberOfDays);
                Assert.Equal(p.PolicingName, r.PolicingName);
                Assert.Equal(false, r.CanDelete);
            }
        }

        public class PolicingRequestLogItemFacts
        {
            [Fact]
            public void TimeTaken()
            {
                var p = new PolicingRequestLogItem
                {
                    StartDateTime = Fixture.Today(),
                    FinishDateTime = Fixture.Today().AddHours(2)
                };

                Assert.Equal(TimeSpan.FromHours(2), p.TimeTaken);
            }
        }

        public class AllowableFiltersMethod : FactBase
        {
            [Fact]
            public void ReturnsDistinctFilterableOptionsForPolicingName()
            {
                new PolicingLog
                {
                    StartDateTime = Fixture.Today(),
                    PolicingName = "P1"
                }.In(Db);

                new PolicingLog
                {
                    StartDateTime = Fixture.Today().AddHours(1),
                    PolicingName = "P2"
                }.In(Db);

                new PolicingLog
                {
                    StartDateTime = Fixture.Today().AddHours(2),
                    PolicingName = "P2"
                }.In(Db);

                var r = new PolicingRequestLogReaderFixture(Db).Subject.AllowableFilters("policingName", CommonQueryParameters.Default).ToArray();

                Assert.Equal(2, r.Length);

                Assert.Equal("P1", r[0].Code);
                Assert.Equal("P2", r[1].Code);

                Assert.Equal("P1", r[0].Description);
                Assert.Equal("P2", r[1].Description);
            }

            [Fact]
            public void ReturnsDistinctFilterableOptionsForStatus()
            {
                new PolicingLog
                {
                    StartDateTime = Fixture.Today(),
                    FailMessage = "Fail message",
                    PolicingName = "Test1"
                }.In(Db);

                new PolicingLog
                {
                    StartDateTime = Fixture.Today().AddHours(1),
                    FinishDateTime = Fixture.Today().AddHours(2),
                    PolicingName = "Test2"
                }.In(Db);

                new PolicingLog
                {
                    StartDateTime = Fixture.Today().AddHours(2),
                    PolicingName = "Test3"
                }.In(Db);

                new PolicingLog
                {
                    StartDateTime = Fixture.Today().AddHours(2),
                    PolicingName = "Test4"
                }.In(Db);

                var r = new PolicingRequestLogReaderFixture(Db).Subject.AllowableFilters("status", CommonQueryParameters.Default).ToArray();

                Assert.Equal(3, r.Length);

                Assert.Equal("completed", r[0].Code);
                Assert.Equal("error", r[1].Code);
                Assert.Equal("inProgress", r[2].Code);

                Assert.Equal("completed", r[0].Description);
                Assert.Equal("error", r[1].Description);
                Assert.Equal("inProgress", r[2].Description);
            }

            [Fact]
            public void ThrowsIfFieldProvidedIsNotSupportedForFiltering()
            {
                Assert.Throws<NotSupportedException>(() => { new PolicingRequestLogReaderFixture(Db).Subject.AllowableFilters(Fixture.String(), CommonQueryParameters.Default); });
            }
        }

        public class GetInProgressRequests : FactBase
        {
            public GetInProgressRequests()
            {
                _f = new PolicingRequestLogReaderFixture(Db);
            }

            readonly PolicingRequestLogReaderFixture _f;
            readonly string _policingName = "PolicingRequest1";

            [Fact]
            public void DoesNotReturnsRequestsDateTimeIfCompleted()
            {
                new PolicingRequest {Name = _policingName, IsSystemGenerated = 0}.In(Db);
                new PolicingLog {PolicingName = _policingName, StartDateTime = Fixture.Tuesday, FinishDateTime = Fixture.Tuesday}.In(Db);

                var result = _f.Subject.GetInProgressRequests(new DateTime[] { })?.ToArray();

                Assert.NotNull(result);
                Assert.Empty(result);
            }

            [Fact]
            public void DoesNotReturnsRequestsDateTimeIfInError()
            {
                new PolicingRequest {Name = _policingName, IsSystemGenerated = 0}.In(Db);
                new PolicingLog {PolicingName = _policingName, StartDateTime = Fixture.Tuesday, FailMessage = "Failed"}.In(Db);

                var result = _f.Subject.GetInProgressRequests(new DateTime[] { })?.ToArray();

                Assert.NotNull(result);
                Assert.Empty(result);
            }

            [Fact]
            public void DoesNotReturnsRequestsDateTimeIfSysGenerated()
            {
                new PolicingRequest {Name = _policingName, IsSystemGenerated = 1}.In(Db);
                new PolicingLog {PolicingName = _policingName, StartDateTime = Fixture.Tuesday}.In(Db);

                var result = _f.Subject.GetInProgressRequests(new DateTime[] { })?.ToArray();

                Assert.NotNull(result);
                Assert.Empty(result);
            }

            [Fact]
            public void ReturnsRequestsDateTimeCurrentlyInProgress()
            {
                new PolicingRequest {Name = _policingName, IsSystemGenerated = 0}.In(Db);
                new PolicingLog {PolicingName = _policingName, StartDateTime = Fixture.Tuesday}.In(Db);

                var result = _f.Subject.GetInProgressRequests(new DateTime[] { })?.ToArray();

                Assert.NotNull(result);
                Assert.Single(result);
                Assert.Equal(Fixture.Tuesday, result.First());
            }

            [Fact]
            public void ReturnsRequestsDateTimeCurrentlyInProgressForPassedDateTimesOnly()
            {
                new PolicingRequest {Name = _policingName, IsSystemGenerated = 0}.In(Db);
                new PolicingLog {PolicingName = _policingName, StartDateTime = Fixture.Tuesday}.In(Db);
                new PolicingLog {PolicingName = _policingName, StartDateTime = Fixture.Monday}.In(Db);

                var result = _f.Subject.GetInProgressRequests(new[] {Fixture.Monday})?.ToArray();

                Assert.NotNull(result);
                Assert.Single(result);
                Assert.Equal(Fixture.Monday, result.First());
            }
        }

        public class PolicingRequestLogReaderFixture : IFixture<PolicingRequestLogReader>
        {
            public PolicingRequestLogReaderFixture(InMemoryDbContext db)
            {
                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.Filter(Arg.Any<IEnumerable<PolicingRequestLogItem>>(), Arg.Any<CommonQueryParameters>())
                                  .Returns(x => x[0]);
                InprotechVersionChecker = Substitute.For<IInprotechVersionChecker>();
                InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(true);

                Subject = new PolicingRequestLogReader(db, CommonQueryService, InprotechVersionChecker);
            }

            public ICommonQueryService CommonQueryService { get; set; }
            
            public IInprotechVersionChecker InprotechVersionChecker { get; set; }

            public PolicingRequestLogReader Subject { get; set; }
        }
    }
}