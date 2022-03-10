using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Documents;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Components.DocumentGeneration.Classic;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.DocumentGeneration.Classic
{
    public class DocumentGeneratorFacts
    {
        public class QueueDocumentFromAnotherActivityMethod : FactBase
        {
            [Fact]
            public async Task ShouldCopyFromActivityHistoryThenEnqueueWithFlagsReset()
            {
                var f = new DocumentGeneratorFixture(Db);

                await f.Subject.QueueDocument(new CaseActivityRequest
                {
                    HoldFlag = Fixture.Short(),
                    Processed = Fixture.Short(),
                    SystemMessage = Fixture.String()
                }.In(Db).Id, (x, y) => { });

                var r = Db.Set<CaseActivityRequest>().Last();
                var o = Db.Set<CaseActivityRequest>().First();

                Assert.NotEqual(o, r);
                Assert.Equal(0, r.HoldFlag);
                Assert.Equal(0, r.Processed);
                Assert.Null(r.SystemMessage);
            }

            [Fact]
            public async Task ShouldAllowAdditionalFieldsTobeSetInTheEnqueuedRequest()
            {
                var f = new DocumentGeneratorFixture(Db);

                await f.Subject.QueueDocument(new CaseActivityRequest
                {
                    EmailOverride = Fixture.String()
                }.In(Db).Id, (x, y) =>
                {
                    y.EmailOverride = "abc";
                });

                var r = Db.Set<CaseActivityRequest>().Last();
                var o = Db.Set<CaseActivityRequest>().First();

                Assert.Equal("abc", r.EmailOverride);
                Assert.NotEqual("abc", o.EmailOverride);
            }
        }

        public class QueueChecklistQuestionDocumentMethod : FactBase
        {
            [Fact]
            public void ShouldGenerateChecklistDocument()
            {
                var f = new DocumentGeneratorFixture(Db);
                var @case = new CaseBuilder().Build();
                var document = new DocumentBuilder().Build();
                f.SecurityContext.User.Returns(new User(Fixture.String(), false));
                f.Now().Returns(Fixture.Today());

                f.Subject.QueueChecklistQuestionDocument(@case, Fixture.Short(), Fixture.Integer(), Fixture.Short(), document);
                var results = @case.PendingRequests.Where(v => v.LetterNo == document.Id).ToList();

                Assert.Equal(results.Count, 1);
                Assert.Equal(results[0].LetterDate, Fixture.Today());
            }

            [Fact]
            public void ShouldThrowExceptionWhenNoCase()
            {
                var f = new DocumentGeneratorFixture(Db);
                var document = new DocumentBuilder().Build();
                f.SecurityContext.User.Returns(new User(Fixture.String(), false));

                Assert.Throws<ArgumentNullException>(() => { f.Subject.QueueChecklistQuestionDocument(null, Fixture.Short(), Fixture.Integer(), Fixture.Short(), document); });
            }

            [Fact]
            public void ShouldThrowExceptionWhenNoDocument()
            {
                var f = new DocumentGeneratorFixture(Db);
                var @case = new CaseBuilder().Build();
                f.SecurityContext.User.Returns(new User(Fixture.String(), false));

                Assert.Throws<ArgumentNullException>(() => { f.Subject.QueueChecklistQuestionDocument(@case, Fixture.Short(), Fixture.Integer(), Fixture.Short(), null); });
            }
        }
    }

    public class DocumentGeneratorFixture : IFixture<DocumentGenerator>
    {
        public DocumentGeneratorFixture(InMemoryDbContext db)
        {
            DbContext = db;
            SecurityContext = Substitute.For<ISecurityContext>();
            Now = Substitute.For<Func<DateTime>>();
            ActivityRequestHistoryMapper = Substitute.For<IActivityRequestHistoryMapper>();
            ActivityRequestHistoryMapper.CopyAsNewRequest(Arg.Any<CaseActivityRequest>(), Arg.Any<Action<CaseActivityRequest, CaseActivityRequest>>())
                                        .Returns(x =>
                                        {
                                            var action = (Action<CaseActivityRequest, CaseActivityRequest>) x[1];

                                            var copied = new CaseActivityRequest().In(db);

                                            action((CaseActivityRequest) x[0], copied);

                                            return copied;
                                        });

            Subject = new DocumentGenerator(DbContext, SecurityContext, Now, ActivityRequestHistoryMapper);
        }

        public IActivityRequestHistoryMapper ActivityRequestHistoryMapper { get; set; }

        public IDbContext DbContext { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public Func<DateTime> Now { get; set; }
        public DocumentGenerator Subject { get; set; }
    }
}