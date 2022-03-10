using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.DocumentGeneration
{
    public class QueueItemsFacts
    {
        public class ForProcessingMethod : FactBase
        {
            [Fact]
            public void ShouldReturnEligibleRequestsForProcessing()
            {
                new CaseActivityRequest
                {
                    CaseId = Tests.Fixture.Integer(),
                    LetterNo = Tests.Fixture.Short(),
                    HoldFlag = 0,
                    Processed = 0
                }.In(Db);

                var f = new Fixture(Db);

                var subject = f.Subject;

                var r = subject.ForProcessing().ToArray();

                Assert.Single(r);
            }

            [Fact]
            public void ShouldExcludeThoseStillBeingPoliced()
            {
                var caseId = Tests.Fixture.Integer();

                new CaseActivityRequest
                {
                    CaseId = caseId,
                    LetterNo = Tests.Fixture.Short(),
                    HoldFlag = 0,
                    Processed = 0
                }.In(Db);

                new PolicingRequest
                {
                    CaseId = caseId,
                    IsSystemGenerated = 1
                }.In(Db);

                var f = new Fixture(Db);

                var subject = f.Subject;

                var r = subject.ForProcessing().ToArray();

                Assert.Empty(r);
            }

            [Fact]
            public void ShouldExcludeOnHoldRequests()
            {
                new CaseActivityRequest
                {
                    CaseId = Tests.Fixture.Integer(),
                    LetterNo = Tests.Fixture.Short(),
                    HoldFlag = 1,
                    Processed = 0
                }.In(Db);

                var f = new Fixture(Db);

                var subject = f.Subject;

                var r = subject.ForProcessing().ToArray();

                Assert.Empty(r);
            }

            [Fact]
            public void ShouldExcludeProcessedRequests()
            {
                new CaseActivityRequest
                {
                    CaseId = Tests.Fixture.Integer(),
                    LetterNo = Tests.Fixture.Short(),
                    HoldFlag = 0,
                    Processed = 1
                }.In(Db);

                var f = new Fixture(Db);

                var subject = f.Subject;

                var r = subject.ForProcessing().ToArray();

                Assert.Empty(r);
            }

            [Fact]
            public void ShouldExcludeNonCaseRequests()
            {
                new CaseActivityRequest
                {
                    LetterNo = Tests.Fixture.Short(),
                    HoldFlag = 0,
                    Processed = 0
                }.In(Db);

                var f = new Fixture(Db);

                var subject = f.Subject;

                var r = subject.ForProcessing().ToArray();

                Assert.Empty(r);
            }

            [Fact]
            public void ShouldExcludeNonLetterGenerationRequests()
            {
                new CaseActivityRequest
                {
                    CaseId = Tests.Fixture.Integer(),
                    HoldFlag = 1,
                    Processed = 0
                }.In(Db);

                var f = new Fixture(Db);

                var subject = f.Subject;

                var r = subject.ForProcessing().ToArray();

                Assert.Empty(r);
            }
        }

        public class HoldMethod : FactBase
        {
            [Fact]
            public async Task ShouldSetHoldFlagTo1()
            {
                var f = new Fixture(Db);

                var subject = f.Subject;

                await subject.Hold(new CaseActivityRequest().In(Db).Id);

                Assert.Equal(1, Db.Set<CaseActivityRequest>().Single().HoldFlag);
            }
        }

        public class ErrorMethod : FactBase
        {
            [Fact]
            public async Task ShouldRecordSystemMessage()
            {
                var errorMessage = Tests.Fixture.String();

                var f = new Fixture(Db);

                var subject = f.Subject;

                await subject.Error(new CaseActivityRequest().In(Db).Id, errorMessage);

                Assert.Equal(errorMessage, Db.Set<CaseActivityRequest>().Single().SystemMessage);
            }

            [Fact]
            public async Task ShouldTruncateErrorMessageTo254ForClassicDocumentGeneratorCompatibility()
            {
                var errorMessage = Tests.Fixture.RandomString(1000);

                var f = new Fixture(Db);

                var subject = f.Subject;

                await subject.Error(new CaseActivityRequest().In(Db).Id, errorMessage);

                Assert.StartsWith(Db.Set<CaseActivityRequest>().Single().SystemMessage, errorMessage);

                Assert.Equal(254, Db.Set<CaseActivityRequest>().Single().SystemMessage.Length);
            }
        }

        public class CompleteMethod : FactBase
        {
            [Fact]
            public async Task ShouldMoveRequestToHistoryWithFlagsSet()
            {
                var f = new Fixture(Db);

                var fileName = Tests.Fixture.String();

                var subject = f.Subject;

                await subject.Complete(new CaseActivityRequest().In(Db).Id, fileName);

                Assert.Equal(Tests.Fixture.Today(), Db.Set<CaseActivityHistory>().Single().WhenOccurred);
                Assert.Equal(1, Db.Set<CaseActivityHistory>().Single().Processed);
                Assert.Equal(fileName, Db.Set<CaseActivityHistory>().Single().FileName);
                Assert.Empty(Db.Set<CaseActivityRequest>());
            }
        }

        public class Fixture : IFixture<QueueItems>
        {
            public Fixture(InMemoryDbContext db)
            {
                Mapper = Substitute.For<IActivityRequestHistoryMapper>();

                Mapper.CopyAsHistory(Arg.Any<CaseActivityRequest>(), Arg.Any<Action<CaseActivityRequest, CaseActivityHistory>>())
                      .Returns(x =>
                      {
                          var action = (Action<CaseActivityRequest, CaseActivityHistory>) x[1];

                          var copied = new CaseActivityHistory().In(db);

                          action((CaseActivityRequest) x[0], copied);

                          return copied;
                      });

                Subject = new QueueItems(db, Tests.Fixture.Today, Mapper);
            }

            public IActivityRequestHistoryMapper Mapper { get; set; }

            public QueueItems Subject { get; }
        }
    }
}