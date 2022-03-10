using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Restrictions
{
    public class CaseNameWithDebtorStatusFacts
    {
        public class CaseNamesWithDebtorStatusFixture : IFixture<CaseNamesWithDebtorStatus>
        {
            public CaseNamesWithDebtorStatusFixture()
            {
                RestrictableCaseNames = Substitute.For<IRestrictableCaseNames>();

                Subject = new CaseNamesWithDebtorStatus(RestrictableCaseNames);
            }

            public IRestrictableCaseNames RestrictableCaseNames { get; set; }
            public CaseNamesWithDebtorStatus Subject { get; }
        }

        public class ForMethod : FactBase
        {
            public class CaseWithName
            {
                readonly InMemoryDbContext _db;

                public CaseWithName(InMemoryDbContext db)
                {
                    _db = db;
                    Case = new CaseBuilder().Build().In(db);

                    var existingName = new NameBuilder(db).Build().In(db);

                    CaseName = new CaseNameBuilder(db)
                    {
                        Name = existingName,
                        Case = Case
                    }.Build().In(db);

                    Case.CaseNames.Add(CaseName);

                    existingName.ClientDetail = new ClientDetailBuilder().BuildForName(existingName).In(db);
                }

                public Case Case { get; }
                public CaseName CaseName { get; }

                public CaseWithName WithDebtorStatus()
                {
                    CaseName.Name.ClientDetail.DebtorStatus = new DebtorStatusBuilder().Build().In(_db);
                    return this;
                }
            }

            [Fact]
            public void IgnoresNamesWithoutDebtorStatus()
            {
                var c = new CaseWithName(Db);

                var f = new CaseNamesWithDebtorStatusFixture();
                f.RestrictableCaseNames.For(c.Case).Returns(new[] {c.CaseName});

                var result = f.Subject.For(c.Case);

                Assert.False(result.Any());
            }

            [Fact]
            public void ReturnsNamesWithDebtorStatus()
            {
                var c = new CaseWithName(Db).WithDebtorStatus();

                var f = new CaseNamesWithDebtorStatusFixture();
                f.RestrictableCaseNames.For(c.Case).Returns(new[] {c.CaseName});

                var result = f.Subject.For(c.Case);

                Assert.Contains(result, r => r.CaseName.Equals(c.CaseName));
            }
        }
    }
}