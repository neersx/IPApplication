using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class WipWarningsFacts
    {
        public class AllowWipFor : FactBase
        {
            [Fact]
            public async Task ReturnsFalseIfNoCaseFound()
            {
                var f = new WipWarningsFixture(Db);
                Assert.False(await f.Subject.AllowWipFor(Fixture.Integer()));
            }

            [Fact]
            public async Task ReturnsTrueIfNoCaseStatus()
            {
                var @case = new CaseBuilder { HasNoDefaultStatus = true}.Build().In(Db);
                var f = new WipWarningsFixture(Db);
                var result = await f.Subject.AllowWipFor(@case.Id);
                Assert.True(result);
            }

            [Fact]
            public async Task ReturnsFalseIfCaseStatusIsPreventWip()
            {
                var restrictedStatus = new StatusBuilder().WithWipRestriction().Build().In(Db);
                new CaseBuilder { HasNoDefaultStatus = true}.Build().In(Db);
                var case2 = new CaseBuilder
                            {
                                Status = restrictedStatus
                            }.Build().In(Db);
                var case3 = new CaseBuilder().Build().In(Db);

                var f = new WipWarningsFixture(Db);
                var result = await f.Subject.AllowWipFor(case2.Id);
                Assert.False(result);

                result = await f.Subject.AllowWipFor(case3.Id);
                Assert.True(result);
            }
        }

        public class HasDebtorRestriction : FactBase
        {
            [Theory]
            [InlineData(KnownDebtorRestrictions.DisplayError, true, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarning, true, false)]
            [InlineData(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, true, false)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, true, false)]
            [InlineData(KnownDebtorRestrictions.DisplayError, false, false)]
            [InlineData(KnownDebtorRestrictions.DisplayWarning, false, false)]
            [InlineData(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, false, false)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, false, false)]
            public async Task ReturnsTrueForErrorOnly(short restriction, bool restrictOnWip, bool expected)
            {
                var caseKey = Fixture.Integer();
                var @case = new CaseBuilder().BuildWithId(caseKey).In(Db);
                var debtorStatus = new DebtorStatusBuilder {RestrictionAction = restriction}.Build().In(Db);
                var debtor = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus}.BuildForName(debtor).In(Db);
                var debtorNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor, IsNameRestricted = 1}.Build().In(Db);
                new CaseNameBuilder(Db) {NameType = debtorNameType, Name = debtor}.BuildWithCase(@case).In(Db);

                var f = new WipWarningsFixture(Db);
                f.Now().Returns(Fixture.Today());
                f.SiteControl.Read<bool>(SiteControls.RestrictOnWIP).Returns(restrictOnWip);
                Assert.Equal(expected, await f.Subject.HasDebtorRestriction(caseKey));
                f.SiteControl.Received(1).Read<bool>(SiteControls.RestrictOnWIP);
            }

        }

        public class HasNameRestriction : FactBase
        {
            [Theory]
            [InlineData(KnownDebtorRestrictions.DisplayError, true, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarning, true, false)]
            [InlineData(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, true, false)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, true, false)]
            [InlineData(KnownDebtorRestrictions.DisplayError, false, false)]
            [InlineData(KnownDebtorRestrictions.DisplayWarning, false, false)]
            [InlineData(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, false, false)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, false, false)]
            public async Task ReturnsTrueForErrorOnly(short restriction, bool restrictOnWip, bool expected)
            {
                var debtorStatus = new DebtorStatusBuilder {RestrictionAction = restriction}.Build().In(Db);
                var debtor = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus}.BuildForName(debtor).In(Db);

                var f = new WipWarningsFixture(Db);
                f.Now().Returns(Fixture.Today());
                f.SiteControl.Read<bool>(SiteControls.RestrictOnWIP).Returns(restrictOnWip);
                Assert.Equal(expected, await f.Subject.HasNameRestriction(debtor.Id));
                f.SiteControl.Received(1).Read<bool>(SiteControls.RestrictOnWIP);
            }
        }

        class WipWarningsFixture : IFixture<IWipWarnings>
        {
            public WipWarningsFixture(InMemoryDbContext db)
            {
                Now = Substitute.For<Func<DateTime>>();
                SiteControl = Substitute.For<ISiteControlReader>();
                Subject = new WipWarnings(db, Now, SiteControl);
            }

            public ISiteControlReader SiteControl { get; set; }

            public IWipWarnings Subject { get; }
            public Func<DateTime> Now { get; set; }
        }
    }
}