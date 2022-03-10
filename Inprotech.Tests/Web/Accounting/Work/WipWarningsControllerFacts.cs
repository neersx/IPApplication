using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Work;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class WipWarningsControllerFacts
    {
        public class GetWipWarningsForName : FactBase
        {
            [Fact]
            public async Task ChecksCreditLimitForTheName()
            {
                var nameKey = Fixture.Integer();
                var f = new WipWarningsControllerFixture(Db);
                var debtorStatus = new DebtorStatusBuilder().Build().In(Db);
                var debtor = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus}.BuildForName(debtor).In(Db);
                f.Now().Returns(Fixture.Today());
                await f.Subject.GetWipWarningsForName(nameKey, new TimeQuery {SelectedDate = Fixture.Monday});
                await f.CreditLimitCheck.Received(1).For(nameKey);
                await f.PrepaymentCheck.Received(1).ForName(nameKey);
                await f.BillingCapCheck.Received(1).ForName(nameKey, Fixture.Monday);
            }

            [Theory]
            [InlineData(KnownDebtorRestrictions.DisplayError, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarning, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, true)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, false)]
            public async Task OnlyReturnsErrorRestrictions(short restriction, bool expected)
            {
                var nameKey = Fixture.Integer();
                var f = new WipWarningsControllerFixture(Db);
                f.CreditLimitCheck.For(nameKey).Returns(new {Exceeded = false});
                var debtorStatus = new DebtorStatusBuilder {RestrictionAction = restriction}.Build().In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus, NameNo = nameKey}.Build().In(Db);
                f.Now().Returns(Fixture.Today());
                var result = await f.Subject.GetWipWarningsForName(nameKey, new TimeQuery {SelectedDate = Fixture.Monday});
                await f.CreditLimitCheck.Received(1).For(nameKey);
                await f.BillingCapCheck.Received(1).ForName(nameKey, Fixture.Monday);
                Assert.Equal(expected, result != null);
            }
        }

        public class GetWipWarningsForCase : FactBase
        {
            [Fact]
            public async Task ChecksCreditLimitForTheAllDebtors()
            {
                var caseKey = Fixture.Integer();
                var @case = new CaseBuilder().BuildWithId(caseKey).In(Db);
                var debtor1 = new NameBuilder(Db).Build().In(Db);
                var debtor2 = new NameBuilder(Db).Build().In(Db);
                var debtorStatus = new DebtorStatusBuilder().Build().In(Db);
                var debtorNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor}.Build().In(Db);
                new CaseNameBuilder(Db) {NameType = debtorNameType, Name = debtor1}.BuildWithCase(@case).In(Db);
                new CaseNameBuilder(Db) {NameType = debtorNameType, Name = debtor2}.BuildWithCase(@case).In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus}.BuildForName(debtor1).In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus}.BuildForName(debtor2).In(Db);

                var f = new WipWarningsControllerFixture(Db);
                f.Now().Returns(Fixture.Today());
                f.SiteControlReader.Read<bool>(Arg.Any<string>()).ReturnsForAnyArgs(true);
                var result = await f.Subject.GetWipWarningsForCase(caseKey, new TimeQuery {SelectedDate = Fixture.Monday});

                f.SiteControlReader.Received(1).Read<bool>(Arg.Is<string>(_=> _ == SiteControls.RestrictOnWIP));

                Assert.Equal(2, result.CaseWipWarnings.Count());
                Assert.True(result.RestrictOnWip);
            }

            [Fact]
            public async Task ChecksCreditLimitForTheSingleDebtor()
            {
                var caseKey = Fixture.Integer();
                var @case = new CaseBuilder().BuildWithId(caseKey).In(Db);
                var debtorStatus = new DebtorStatusBuilder().Build().In(Db);
                var debtor = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus}.BuildForName(debtor).In(Db);
                var debtorNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor}.Build().In(Db);
                new CaseNameBuilder(Db) {NameType = debtorNameType, Name = debtor}.BuildWithCase(@case).In(Db);

                var f = new WipWarningsControllerFixture(Db);
                f.Now().Returns(Fixture.Today());
                var result = await f.Subject.GetWipWarningsForCase(caseKey, new TimeQuery {SelectedDate = Fixture.Monday});
                Assert.True(result.CaseWipWarnings.Any());
            }

            [Fact]
            public async Task ChecksFinancialWarningsForTheCase()
            {
                var caseKey = Fixture.Integer();
                new CaseBuilder().BuildWithId(caseKey).In(Db);
                var f = new WipWarningsControllerFixture(Db);
                f.Now().Returns(Fixture.Today());
                await f.Subject.GetWipWarningsForCase(caseKey, new TimeQuery {SelectedDate = Fixture.Monday});
                await f.BudgetWarnings.Received(1).For(caseKey, Fixture.Monday);
                await f.PrepaymentCheck.Received(1).ForCase(caseKey);
                await f.BillingCapCheck.Received(1).ForCase(caseKey, Fixture.Monday);
            }

            [Theory]
            [InlineData(KnownDebtorRestrictions.DisplayError, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarning, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, true)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, false)]
            public async Task OnlyReturnsErrorRestrictions(short restriction, bool expected)
            {
                var caseKey = Fixture.Integer();
                var @case = new CaseBuilder().BuildWithId(caseKey).In(Db);
                var debtorStatus = new DebtorStatusBuilder {RestrictionAction = restriction}.Build().In(Db);
                var debtor = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus}.BuildForName(debtor).In(Db);
                var debtorNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor}.Build().In(Db);
                new CaseNameBuilder(Db) {NameType = debtorNameType, Name = debtor}.BuildWithCase(@case).In(Db);

                var f = new WipWarningsControllerFixture(Db);
                f.Now().Returns(Fixture.Today());
                var result = await f.Subject.GetWipWarningsForCase(caseKey, new TimeQuery {SelectedDate = Fixture.Monday});
                Assert.Equal(expected, result.CaseWipWarnings.Any());
            }

            [Theory]
            [InlineData(KnownDebtorRestrictions.DisplayError, KnownDebtorRestrictions.DisplayError, true)]
            [InlineData(KnownDebtorRestrictions.DisplayError, KnownDebtorRestrictions.DisplayWarning, true)]
            [InlineData(KnownDebtorRestrictions.DisplayError, KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarning, KnownDebtorRestrictions.DisplayWarning, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarning, KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, true)]
            [InlineData(KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, true)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, KnownDebtorRestrictions.DisplayError, true)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, KnownDebtorRestrictions.DisplayWarning, true)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, true)]
            [InlineData(KnownDebtorRestrictions.NoRestriction, KnownDebtorRestrictions.NoRestriction, false)]
            public async Task OnlyReturnsForDebtorsWithErrorRestrictions(short restriction1, short restriction2, bool expected)
            {
                var caseKey = Fixture.Integer();
                var @case = new CaseBuilder().BuildWithId(caseKey).In(Db);
                var debtorStatus1 = new DebtorStatusBuilder {RestrictionAction = restriction1}.Build().In(Db);
                var debtorStatus2 = new DebtorStatusBuilder {RestrictionAction = restriction2}.Build().In(Db);
                var debtor1 = new NameBuilder(Db).Build().In(Db);
                var debtor2 = new NameBuilder(Db).Build().In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus1}.BuildForName(debtor1).In(Db);
                new ClientDetailBuilder {DebtorStatus = debtorStatus2}.BuildForName(debtor2).In(Db);
                var debtorNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor}.Build().In(Db);
                new CaseNameBuilder(Db) {NameType = debtorNameType, Name = debtor1}.BuildWithCase(@case).In(Db);
                new CaseNameBuilder(Db) {NameType = debtorNameType, Name = debtor2}.BuildWithCase(@case).In(Db);

                var f = new WipWarningsControllerFixture(Db);
                f.Now().Returns(Fixture.Today());
                var result = await f.Subject.GetWipWarningsForCase(caseKey, new TimeQuery {SelectedDate = Fixture.Monday});
                Assert.Equal(expected, result.CaseWipWarnings.Any());
            }
        }

        public class CheckIfEditable
        {
            [Fact]
            public async Task CallsStatusEvaluatorForEntry()
            {
                var f = new WipWarningsControllerFixture(null);
                f.WipStatusEvaluator.GetWipStatus(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(WipStatusEnum.Billed);
                var result = await f.Subject.CheckIfEditable(10, 100);

                f.WipStatusEvaluator.Received(1).GetWipStatus(Arg.Is(10), Arg.Is(100)).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(WipStatusEnum.Billed, result);
            }
        }

        public class WipWarningsControllerFixture : IFixture<WipWarningsController>
        {
            public WipWarningsControllerFixture(InMemoryDbContext db)
            {
                Culture = Substitute.For<IPreferredCultureResolver>();
                CreditLimitCheck = Substitute.For<INameCreditLimitCheck>();
                Now = Substitute.For<Func<DateTime>>();
                BudgetWarnings = Substitute.For<IBudgetWarnings>();
                PrepaymentCheck = Substitute.For<IPrepaymentWarningCheck>();
                BillingCapCheck = Substitute.For<IBillingCapCheck>();
                WipStatusEvaluator = Substitute.For<IWipStatusEvaluator>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Subject = new WipWarningsController(db, Culture, CreditLimitCheck, Now, BudgetWarnings, PrepaymentCheck, BillingCapCheck, WipStatusEvaluator, SiteControlReader);
            }

            public ISiteControlReader SiteControlReader { get; set; }
            public INameCreditLimitCheck CreditLimitCheck { get; set; }
            public IPreferredCultureResolver Culture { get; set; }

            public IBudgetWarnings BudgetWarnings { get; set; }

            public Func<DateTime> Now { get; set; }
            public IPrepaymentWarningCheck PrepaymentCheck { get; set; }
            public IBillingCapCheck BillingCapCheck { get; set; }
            public IWipStatusEvaluator WipStatusEvaluator { get; set; }
            public WipWarningsController Subject { get; }
        }
    }
}