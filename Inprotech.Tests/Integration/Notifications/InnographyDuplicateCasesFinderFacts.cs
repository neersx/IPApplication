using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Integration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class InnographyDuplicateCasesFinderFacts : FactBase
    {
        [Fact]
        public async Task AppropriateMethodsAreCalled()
        {
            const int notificationIdInQuestion = 1;
            var innographyId = "Winterfell";

            var notificationIds = new[] {1, 2, 3, 4};
            var f = new InnographyDuplicateCasesFinderFixture(Db).WithCaseNotifications(notificationIds)
                                                                 .WithInnographyId(innographyId)
                                                                 .WithCase(innographyId)
                                                                 .WithCase(innographyId);

            var result = (await f.Subject.FindFor(notificationIdInQuestion)).ToList();

            f.CpaXmlProvider.Received(1).For(notificationIdInQuestion).IgnoreAwaitForNSubstituteAssertion();
            f.InnographyIdFromCpaXml.Received(1).Resolve(Arg.Any<string>());

            var notificationInQuestion = Db.Set<CaseNotification>().Single(_ => _.Id == notificationIdInQuestion);
            var caseIds = Db.Set<CpaGlobalIdentifier>().Where(_ => _.InnographyId == innographyId).Select(_ => _.CaseId).ToArray();

            Assert.Equal(3, result.Count);
            Assert.Contains(notificationInQuestion.Case.CorrelationId.Value, result);
            Assert.Contains(caseIds.First(), result);
            Assert.Contains(caseIds.Last(), result);
        }
    }

    public class InnographyDuplicateCasesFinderFixture : IFixture<InnographyDuplicateCasesFinder>
    {
        readonly InMemoryDbContext _db;

        public InnographyDuplicateCasesFinderFixture(InMemoryDbContext db)
        {
            _db = db;

            CpaXmlProvider = Substitute.For<ICpaXmlProvider>();

            InnographyIdFromCpaXml = Substitute.For<IInnographyIdFromCpaXml>();

            Subject = new InnographyDuplicateCasesFinder(_db, _db, CpaXmlProvider, InnographyIdFromCpaXml);
        }

        public IInnographyIdFromCpaXml InnographyIdFromCpaXml { get; }

        public ICpaXmlProvider CpaXmlProvider { get; }

        public InnographyDuplicateCasesFinder Subject { get; }

        public InnographyDuplicateCasesFinderFixture WithCaseNotifications(IEnumerable<int> notificationIds)
        {
            foreach (var notificationId in notificationIds)
            {
                var inprotechCase = new CaseBuilder().Build().In(_db);
                new CaseNotification {Id = notificationId, Case = new Case {CorrelationId = inprotechCase.Id}.In(_db)}.In(_db);
            }

            return this;
        }

        public InnographyDuplicateCasesFinderFixture WithInnographyId(string innographyId)
        {
            InnographyIdFromCpaXml.Resolve(Arg.Any<string>()).Returns(innographyId);

            return this;
        }

        public InnographyDuplicateCasesFinderFixture WithCase(string innographyId)
        {
            var @case = new CaseBuilder().Build().In(_db);
            new CpaGlobalIdentifier {CaseId = @case.Id, InnographyId = innographyId, IsActive = true}.In(_db);

            return this;
        }
    }
}