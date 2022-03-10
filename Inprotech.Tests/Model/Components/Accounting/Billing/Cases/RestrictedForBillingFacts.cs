using System.Linq;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Cases
{
    public class RestrictedForBillingFacts
    {
        static RestrictedForBilling CreateSubject(IDbContext db)
        {
            var caseStatusValidator = Substitute.For<ICaseStatusValidator>();
            caseStatusValidator.GetCasesRestrictedForBilling(Arg.Any<int[]>())
                               .Returns(db.Set<Case>());

            return new RestrictedForBilling(db, caseStatusValidator);
        }

        static Case CreateCaseWith(short? statusId = null)
        {
            return new()
            {
                Irn = Fixture.String(),
                Title = Fixture.String(),
                CurrentOfficialNumber = Fixture.String(),
                StatusCode = statusId
            };
        }

        public class RetrieveMethodWithCaseDataCollection : FactBase
        {
            [Fact]
            public void ShouldReturnRestrictedCasesWithStatusName()
            {
                var restrictedStatus1 = new Status {Name = Fixture.String()}.In(Db);

                var restrictedCase1 = CreateCaseWith(restrictedStatus1.Id).In(Db);
                var restrictedCase2 = CreateCaseWith(restrictedStatus1.Id).In(Db);
                var nonRestrictedCase = CreateCaseWith().In(Db);

                var subject = CreateSubject(Db);

                var r = subject.Retrieve(new[]
                {
                    new CaseData {CaseId = restrictedCase1.Id},
                    new CaseData {CaseId = restrictedCase2.Id},
                    new CaseData {CaseId = nonRestrictedCase.Id}
                }).ToArray();

                Assert.Equal(2, r.Length);

                Assert.Equal(restrictedCase1.Id, r[0].CaseId);
                Assert.Equal(restrictedCase1.Irn, r[0].CaseReference);
                Assert.Equal(restrictedCase1.Title, r[0].Title);
                Assert.Equal(restrictedCase1.CurrentOfficialNumber, r[0].OfficialNumber);
                Assert.Equal(restrictedStatus1.Name, r[0].CaseStatus);

                Assert.Equal(restrictedCase2.Id, r[1].CaseId);
                Assert.Equal(restrictedCase2.Irn, r[1].CaseReference);
                Assert.Equal(restrictedCase2.Title, r[1].Title);
                Assert.Equal(restrictedCase2.CurrentOfficialNumber, r[1].OfficialNumber);
                Assert.Equal(restrictedStatus1.Name, r[0].CaseStatus);
            }
        }

        public class RetrieveMethodWithCaseIds : FactBase
        {
            [Fact]
            public void ShouldReturnRestrictedCasesWithStatusName()
            {
                var restrictedStatus1 = new Status {Name = Fixture.String()}.In(Db);

                var restrictedCase1 = CreateCaseWith(restrictedStatus1.Id).In(Db);
                var restrictedCase2 = CreateCaseWith(restrictedStatus1.Id).In(Db);
                var nonRestrictedCase = CreateCaseWith().In(Db);

                var subject = CreateSubject(Db);

                var r = subject.Retrieve(new[]
                {
                    restrictedCase1.Id,
                    restrictedCase2.Id,
                    nonRestrictedCase.Id
                }).ToArray();

                Assert.Equal(2, r.Length);

                Assert.Equal(restrictedCase1.Id, r[0].CaseId);
                Assert.Equal(restrictedCase1.Irn, r[0].CaseReference);
                Assert.Equal(restrictedCase1.Title, r[0].Title);
                Assert.Equal(restrictedCase1.CurrentOfficialNumber, r[0].OfficialNumber);
                Assert.Equal(restrictedStatus1.Name, r[0].CaseStatus);

                Assert.Equal(restrictedCase2.Id, r[1].CaseId);
                Assert.Equal(restrictedCase2.Irn, r[1].CaseReference);
                Assert.Equal(restrictedCase2.Title, r[1].Title);
                Assert.Equal(restrictedCase2.CurrentOfficialNumber, r[1].OfficialNumber);
                Assert.Equal(restrictedStatus1.Name, r[0].CaseStatus);
            }
        }
    }
}