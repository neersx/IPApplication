using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Policing;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class ErrorReaderFacts
    {
        public class ReadMethod : FactBase
        {
            [Fact]
            public void ReturnsPolicingErrorsForTheCase()
            {
                var f = new ErrorReaderFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);

                f.PolicingQueue.GetPolicingInQueueItemsInfo(Arg.Any<int[]>())
                 .Returns(new[]
                 {
                     new PolicingItemInQueue {CaseId = @case.Id, Earliest = Fixture.PastDate()}
                 }.AsQueryable());
                new PolicingErrorBuilder(Db)
                {
                    CaseId = @case.Id,
                    ErrorMessage = "Oh bummer!",
                    LastModified = Fixture.Today() /* indicates the error occurs after the request */
                }.Build();

                var r = f.Subject.Read(new[] {@case.Id}, 5);
                var totalErrorItemsCount = r[@case.Id].TotalErrorItemsCount;
                var message = r[@case.Id].ErrorItems.Cast<PolicingErrorItem>().First().Message;
                Assert.Equal(1, totalErrorItemsCount);
                Assert.Equal("Oh bummer!", message);
            }

            [Fact]
            public void ReturnsPolicingErrorsForTheMultipleCases()
            {
                var f = new ErrorReaderFixture(Db);
                var case1 = new CaseBuilder().Build().In(Db);
                var case2 = new CaseBuilder().Build().In(Db);

                f.PolicingQueue.GetPolicingInQueueItemsInfo(Arg.Any<int[]>())
                 .Returns(new[]
                 {
                     new PolicingItemInQueue {CaseId = case1.Id, Earliest = Fixture.PastDate()},
                     new PolicingItemInQueue {CaseId = case2.Id, Earliest = Fixture.PastDate()}
                 }.AsQueryable());

                new PolicingErrorBuilder(Db)
                {
                    CaseId = case1.Id,
                    ErrorMessage = "Oh bummer 1!"
                }.Build();

                new PolicingErrorBuilder(Db)
                {
                    CaseId = case2.Id,
                    ErrorMessage = "Oh bummer 2!"
                }.Build();

                var r = f.Subject.Read(new[] {case1.Id, case2.Id}, 5);
                Assert.Equal(1, r[case1.Id].TotalErrorItemsCount);
                Assert.Equal("Oh bummer 1!", r[case1.Id].ErrorItems.Cast<PolicingErrorItem>().First().Message);

                Assert.Equal(1, r[case2.Id].TotalErrorItemsCount);
                Assert.Equal("Oh bummer 2!", r[case2.Id].ErrorItems.Cast<PolicingErrorItem>().First().Message);
            }

            [Fact]
            public void ShouldNotReturnPolicingErrorsEarlierThanTheFirstItemForTheCaseStillInTheQueue()
            {
                var f = new ErrorReaderFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);

                new PolicingError(Fixture.PastDate(), 1)
                {
                    Case = @case,
                    CaseId = @case.Id,
                    Message = "Oh bummer!"
                }.In(Db);

                new PolicingRequest(@case.Id)
                {
                    DateEntered = Fixture.Today()
                }.In(Db);

                Assert.Empty(f.Subject.Read(new[] {@case.Id}, 5));
            }

            [Fact]
            public void ShouldNotReturnPolicingErrorsFromAnotherCase()
            {
                var f = new ErrorReaderFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var other = new CaseBuilder().Build().In(Db);

                new PolicingError(Fixture.PastDate(), 1)
                {
                    Case = other,
                    CaseId = other.Id,
                    Message = "Oh bummer!"
                }.In(Db);

                new PolicingRequest(other.Id)
                {
                    DateEntered = Fixture.PastDate()
                }.In(Db);

                Assert.Empty(f.Subject.Read(new[] {@case.Id}, 5));
            }

            [Fact]
            public void ShouldReturnOnlyRequestedNumberOfItems()
            {
                var f = new ErrorReaderFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);

                f.PolicingQueue.GetPolicingInQueueItemsInfo(Arg.Any<int[]>())
                 .Returns(new[]
                 {
                     new PolicingItemInQueue {CaseId = @case.Id, Earliest = Fixture.PastDate()}
                 }.AsQueryable());

                new PolicingErrorBuilder(Db)
                {
                    CaseId = @case.Id,
                    ErrorMessage = "Oh bummer 1!"
                }.Build();

                new PolicingErrorBuilder(Db)
                {
                    CaseId = @case.Id,
                    ErrorMessage = "Oh bummer 1!"
                }.Build();

                new PolicingErrorBuilder(Db)
                {
                    CaseId = @case.Id,
                    ErrorMessage = "Oh bummer 1!"
                }.Build();

                const int justTheTop2Items = 2;
                var r = f.Subject.Read(new[] {@case.Id}, justTheTop2Items)[@case.Id];

                Assert.Equal(3, r.TotalErrorItemsCount);
                Assert.Equal(justTheTop2Items, r.ErrorItems.Count());
            }
        }

        public class ForMethod : FactBase
        {
            [Fact]
            public void ReturnsPolicingErrorsForTheCase()
            {
                var f = new ErrorReaderFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);

                new PolicingErrorBuilder(Db)
                {
                    CaseId = @case.Id,
                    ErrorMessage = "Oh bummer!",
                    LastModified = Fixture.Today() /* indicates the error occurs after the request */
                }.Build();

                f.PolicingQueue.GetPolicingInQueueItemsInfo(Arg.Any<int[]>())
                 .Returns(new[]
                 {
                     new PolicingItemInQueue {CaseId = @case.Id, Earliest = Fixture.PastDate()}
                 }.AsQueryable());

                Assert.Equal("Oh bummer!", f.Subject.For(@case.Id).Single().Message);
            }

            [Fact]
            public void ShouldNotReturnPolicingErrorsEarlierThanTheFirstItemForTheCaseStillInTheQueue()
            {
                var f = new ErrorReaderFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);

                new PolicingError(Fixture.PastDate(), 1)
                {
                    Case = @case,
                    CaseId = @case.Id,
                    Message = "Oh bummer!"
                }.In(Db);

                f.PolicingQueue.GetPolicingInQueueItemsInfo(Arg.Any<int[]>())
                 .Returns(new[]
                 {
                     new PolicingItemInQueue {CaseId = @case.Id, Earliest = Fixture.Today()}
                 }.AsQueryable());

                Assert.Empty(f.Subject.For(@case.Id));
            }

            [Fact]
            public void ShouldNotReturnPolicingErrorsFromAnotherCase()
            {
                var f = new ErrorReaderFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var other = new CaseBuilder().Build().In(Db);

                new PolicingError(Fixture.PastDate(), 1)
                {
                    Case = other,
                    CaseId = other.Id,
                    Message = "Oh bummer!"
                }.In(Db);

                f.PolicingQueue.GetPolicingInQueueItemsInfo(Arg.Any<int[]>())
                 .Returns(new[]
                 {
                     new PolicingItemInQueue {CaseId = other.Id, Earliest = Fixture.PastDate()}
                 }.AsQueryable());

                Assert.Empty(f.Subject.For(@case.Id));
            }
        }

        public class PolicingErrorItemFacts
        {
            [Fact]
            public void ReturnBaseDescriptionIfSpecificDescriptionNotExists()
            {
                var error = new PolicingErrorItem
                {
                    SpecificDescription = null,
                    BaseDescription = "B"
                };

                Assert.Equal("B", error.EventDescription);
            }

            [Fact]
            public void ReturnSpecificEventDescriptionOverDefaultEventDescription()
            {
                var error = new PolicingErrorItem
                {
                    SpecificDescription = "A",
                    BaseDescription = "B"
                };

                Assert.Equal("A", error.EventDescription);
            }
        }

        public class ErrorReaderFixture : IFixture<ErrorReader>
        {
            public ErrorReaderFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                PolicingQueue = Substitute.For<IPolicingQueue>();

                Subject = new ErrorReader(db, PreferredCultureResolver, PolicingQueue);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; }

            public IPolicingQueue PolicingQueue { get; }

            public ErrorReader Subject { get; }
        }
    }
}