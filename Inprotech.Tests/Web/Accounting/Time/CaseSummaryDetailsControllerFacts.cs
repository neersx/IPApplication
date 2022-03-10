using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;
using TimeCaseSummaryName = Inprotech.Web.Accounting.Time.CaseSummaryName;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class CaseSummaryDetailsControllerFacts
    {
        public class GetCaseSummary : FactBase
        {
            [Theory]
            [InlineData(true, 2)]
            [InlineData(false, 1)]
            public async Task GetsCaseNamesAndInfoForTheCase(bool withMultipleNames, int expected)
            {
                var caseId = Fixture.Integer();
                var status = new Status(Fixture.Short(), Fixture.String()).In(Db);
                var officialNo = new OfficialNumberBuilder().Build().In(Db);
                var @case = new CaseBuilder { Status = status, OfficialNumbers = new[] { officialNo } }.BuildWithId(caseId).In(Db);
                var f = new CaseSummaryDetailsControllerFixture(Db, withMultipleNames);
                var result = await f.Subject.GetCaseSummary(caseId);
                await f.CaseSummaryNamesProvider.Received(1).GetNames(caseId);
                f.StatusReader.Received(1).GetCaseStatusDescription(status);

                Assert.Equal(caseId, result.CaseKey);
                Assert.Equal(@case.Irn, result.Irn);
                Assert.Equal(@case.Title, result.Title);
                Assert.NotNull(result.Instructor);
                Assert.Equal(expected, ((IEnumerable<TimeCaseSummaryName>)result.StaffMember).Count(_ => _.TypeId == KnownNameTypes.StaffMember));
                Assert.Equal(expected, ((IEnumerable<TimeCaseSummaryName>) result.Signatory).Count(_ => _.TypeId == KnownNameTypes.Signatory));
                Assert.Equal(expected, ((IEnumerable<TimeCaseSummaryName>)result.Owners).Count(_ => _.TypeId == KnownNameTypes.Owner));
                Assert.Equal(expected, ((IEnumerable<TimeCaseSummaryName>)result.Debtors).Count(_ => _.TypeId == KnownNameTypes.Debtor));
            }

            [Fact]
            public async Task ReturnsNotFoundWhenCaseDoesNotExist()
            {
                var caseId = Fixture.Integer();
                var f = new CaseSummaryDetailsControllerFixture(Db);
                var message = await f.Subject.GetCaseSummary(caseId);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseMessage)message).StatusCode);
            }

            [Fact]
            public async Task ReturnsCaseBillNarrativeForCase()
            {
                var f = new CaseSummaryDetailsControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var tt = new TextTypeBuilder {Description = Fixture.String(), Id = KnownTextTypes.Billing}.Build().In(Db);
                @case.CaseTexts.Add(new CaseText(@case.Id, KnownTextTypes.Billing, 0, "01") {TextType = tt, Text = Fixture.String() });
                f.SiteControlReader.Read<bool>(SiteControls.TimesheetShowCaseNarrative).Returns(true);
                var result = await f.Subject.GetCaseSummary(@case.Id);
                Assert.Equal(@case.CaseTexts.FirstOrDefault()?.Text, result.CaseNarrativeText);
            }

            [Fact]
            public async Task DoNotReturnCaseBillNarrativeWhenSiteControlIsFalse()
            {
                var f = new CaseSummaryDetailsControllerFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var tt = new TextTypeBuilder {Description = Fixture.String(), Id = KnownTextTypes.Billing}.Build().In(Db);
                @case.CaseTexts.Add(new CaseText(@case.Id, KnownTextTypes.Billing, 0, "01") {TextType = tt, Text = Fixture.String() });
                f.SiteControlReader.Read<bool>(SiteControls.TimesheetShowCaseNarrative).Returns(false);
                var result = await f.Subject.GetCaseSummary(@case.Id);
                Assert.Null(result.CaseNarrativeText);
            }
        }

        public class GetBillingDetails : FactBase
        {
            [Fact]
            public async Task ChecksSubjectSecurity()
            {
                var caseId = Fixture.Integer();
                var f = new CaseSummaryDetailsControllerFixture(Db);
                var result = await f.Subject.GetBillingDetails(caseId);
                Db.DidNotReceiveWithAnyArgs().Set<Case>();
                Db.DidNotReceiveWithAnyArgs().Set<WorkInProgress>();
                Db.DidNotReceiveWithAnyArgs().Set<Diary>();
                Db.DidNotReceiveWithAnyArgs().Set<WorkHistory>();
                Assert.Null(result.LastInvoiceDate);
                Assert.Null(result.BudgetUsed);
                Assert.Equal(0, result.ActiveBudget);
                Assert.Equal(0, result.TotalWorkPerformed);
                Assert.Equal(0, result.TotalWorkForPeriod);
                Assert.Equal(0, result.Wip);
                Assert.Equal(0, result.UnpostedTime);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public async Task ReturnsBudget(bool hasRevised)
            {
                var budgetAmt = Fixture.Decimal();
                var revised = Fixture.Decimal();
                var @case = new CaseBuilder
                    {
                        BudgetAmount = budgetAmt,
                        RevisedBudgetAmount = hasRevised ? revised : null
                    }.Build()
                     .In(Db);
                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems).Returns(true);
                var result = await f.Subject.GetBillingDetails(@case.Id);
                Assert.Equal(hasRevised ? revised : budgetAmt, result.ActiveBudget);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            [InlineData(false, true)]
            [InlineData(true, true)]
            public async Task ReturnsBudgetIfWithinStartDate(bool hasRevised, bool asExpired = false)
            {
                var budgetAmt = Fixture.Decimal();
                var revised = Fixture.Decimal();
                var @case = new CaseBuilder
                    {
                        BudgetAmount = budgetAmt,
                        RevisedBudgetAmount = hasRevised ? revised : null,
                        BudgetStartDate = asExpired ? Fixture.FutureDate() : Fixture.Today(),
                        BudgetEndDate = Fixture.FutureDate().AddDays(1)
                    }.Build()
                     .In(Db);
                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems).Returns(true);
                var result = await f.Subject.GetBillingDetails(@case.Id);
                Assert.Equal(asExpired ? 0 : hasRevised ? revised : budgetAmt, result.ActiveBudget);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            [InlineData(false, true)]
            [InlineData(true, true)]
            public async Task ReturnsBudgetIfWithinEndDate(bool hasRevised, bool asExpired = false)
            {
                var budgetAmt = Fixture.Decimal();
                var revised = Fixture.Decimal();
                var @case = new CaseBuilder
                    {
                        BudgetAmount = budgetAmt,
                        RevisedBudgetAmount = hasRevised ? revised : null,
                        BudgetStartDate = Fixture.PastDate().AddDays(-1),
                        BudgetEndDate = asExpired ? Fixture.PastDate() : Fixture.Today()
                    }.Build()
                     .In(Db);
                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems).Returns(true);
                var result = await f.Subject.GetBillingDetails(@case.Id);
                Assert.Equal(asExpired ? 0 : hasRevised ? revised : budgetAmt, result.ActiveBudget);
            }

            [Fact]
            public async Task ReturnsUnpostedTime()
            {
                var caseId = Fixture.Integer();
                var @case = new CaseBuilder().BuildWithId(caseId);

                var case2 = new CaseBuilder().BuildWithId(Fixture.Integer());
                var diaryOtherCase = new DiaryBuilder(Db) { Case = case2 }.BuildWithCase();
                diaryOtherCase.TimeValue = 100;

                new DiaryBuilder(Db) { Case = @case }.BuildWithCase();
                var diaryWithTimeValue = new DiaryBuilder(Db) { Case = @case }.BuildWithCase();
                diaryWithTimeValue.TimeValue = 100;
                var diaryAsTimer = new DiaryBuilder(Db) { Case = @case }.BuildWithCase();
                diaryAsTimer.TimeValue = 100;
                diaryAsTimer.IsTimer = 1;

                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems).Returns(true);
                var result = await f.Subject.GetBillingDetails(caseId);
                Assert.Equal(100, result.UnpostedTime);
                Assert.Equal(0, result.Wip);
                Assert.Equal(0, result.TotalWorkPerformed);
            }

            [Fact]
            public async Task ReturnsTotalWip()
            {
                var caseId = Fixture.Integer();
                var @case = new CaseBuilder().BuildWithId(caseId);
                var case2 = new CaseBuilder().BuildWithId(Fixture.Integer());
                var diaryOtherCase = new DiaryBuilder(Db) { Case = case2 }.BuildWithCase();
                diaryOtherCase.TimeValue = 100;

                new DiaryBuilder(Db) { Case = @case }.BuildWithCase();
                var diaryWithTimeValue = new DiaryBuilder(Db) { Case = @case }.BuildWithCase();
                diaryWithTimeValue.TimeValue = 100;
                var diaryAsTimer = new DiaryBuilder(Db) { Case = @case }.BuildWithCase();
                diaryAsTimer.TimeValue = 100;
                diaryAsTimer.IsTimer = 1;

                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems).Returns(true);
                f.AccountingProvider.UnbilledWipFor(caseId).Returns(30);
                var result = await f.Subject.GetBillingDetails(caseId);
                Assert.Equal(100, result.UnpostedTime);
                Assert.Equal(30, result.Wip);
                Assert.Equal(0, result.TotalWorkPerformed);
                await f.AccountingProvider.Received(1).UnbilledWipFor(caseId);
            }

            [Fact]
            public async Task ReturnsTotalWorkPerformed()
            {
                var @case = new CaseBuilder().Build().In(Db);
                var case2 = new CaseBuilder().BuildWithId(Fixture.Integer()).In(Db);
                CreateWipFor(@case, case2);

                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems).Returns(true);
                f.AccountingProvider.UnbilledWipFor(@case.Id).Returns(30);
                var result = await f.Subject.GetBillingDetails(@case.Id);
                Assert.Equal(100, result.UnpostedTime);
                Assert.Equal(30, result.Wip);
                Assert.Equal(40, result.TotalWorkPerformed);
                await f.AccountingProvider.Received(1).UnbilledWipFor(@case.Id);
                Assert.Null(result.BudgetUsed);
                Assert.Null(result.ActiveBudget);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            [InlineData(true, true)]
            [InlineData(false, false, true)]
            [InlineData(false, true, true)]
            public async Task ReturnsBudgetUsedWhereAvailable(bool withWip, bool withBudgetStart = false, bool withBudgetEnd = false)
            {
                var budget = 100;
                var @case = new CaseBuilder
                    {
                        BudgetAmount = budget,
                        BudgetStartDate = withBudgetStart ? Fixture.PastDate() : null,
                        BudgetEndDate = withBudgetEnd ? Fixture.Today() : null
                    }.Build().In(Db);
                var case2 = new CaseBuilder().BuildWithId(Fixture.Integer()).In(Db);

                if (withWip) CreateWipFor(@case, case2);

                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems).Returns(true);
                var result = await f.Subject.GetBillingDetails(@case.Id);
                Assert.Equal(0, result.Wip);
                Assert.Equal(withWip ? 100 : 0, result.UnpostedTime);
                Assert.Equal(withWip ? 40 : 0, result.TotalWorkPerformed);
                Assert.Equal(withWip ? 40 - (withBudgetStart ? 10 : 0) - (withBudgetEnd ? 10 : 0) : 0, result.TotalWorkForPeriod);
                await f.AccountingProvider.Received(1).UnbilledWipFor(@case.Id);
                Assert.Equal(withWip ? 40 - (withBudgetStart ? 10 : 0) - (withBudgetEnd ? 10 : 0) : 0, result.BudgetUsed);
                Assert.Equal(budget, result.ActiveBudget);
            }

            void CreateWipFor(Case case1, Case case2)
            {
                new WorkHistory { CaseId = case1.Id, LocalValue = 10, Status = TransactionStatus.Draft, MovementClass = MovementClass.Entered }.In(Db);
                new WorkHistory { CaseId = case1.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.Entered, TransDate = Fixture.PastDate()}.In(Db);
                new WorkHistory { CaseId = case1.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.Billed }.In(Db);
                new WorkHistory { CaseId = case1.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.AdjustUp, TransDate = Fixture.PastDate().AddDays(-1)}.In(Db);
                new WorkHistory { CaseId = case1.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.AdjustDown, TransDate = Fixture.FutureDate()}.In(Db);
                new WorkHistory { CaseId = case1.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.Entered, TransDate = Fixture.Today()}.In(Db);
                new WorkHistory { CaseId = case1.Id, LocalValue = 10, Status = TransactionStatus.Draft, MovementClass = MovementClass.AdjustUp }.In(Db);
                new WorkHistory { CaseId = case1.Id, LocalValue = 10, Status = TransactionStatus.Draft, MovementClass = MovementClass.AdjustDown}.In(Db);
                new WorkHistory { CaseId = case2.Id, LocalValue = 10, Status = TransactionStatus.Draft, MovementClass = MovementClass.Entered }.In(Db);
                new WorkHistory { CaseId = case2.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.Entered }.In(Db);
                new WorkHistory { CaseId = case2.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.AdjustUp }.In(Db);
                new WorkHistory { CaseId = case2.Id, LocalValue = 10, Status = TransactionStatus.Active, MovementClass = MovementClass.AdjustDown }.In(Db);

                var diaryOtherCase = new DiaryBuilder(Db) { Case = case2 }.BuildWithCase();
                diaryOtherCase.TimeValue = 100;

                new DiaryBuilder(Db) { Case = case1 }.BuildWithCase();
                var diaryWithTimeValue = new DiaryBuilder(Db) { Case = case1 }.BuildWithCase();
                diaryWithTimeValue.TimeValue = 100;
                var diaryAsTimer = new DiaryBuilder(Db) { Case = case1 }.BuildWithCase();
                diaryAsTimer.TimeValue = 100;
                diaryAsTimer.IsTimer = 1;
            }

            [Fact]
            public async Task ReturnsNullIfSubjectSecurityNotSet()
            {
                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.BillingHistory).Returns(false);
                var result = await f.Subject.GetBillingDetails(10);
                Assert.Null(result.LastInvoiceDate);
                f.AccountingProvider.DidNotReceive().GetLastInvoiceDate(Arg.Any<int>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallsAccountingProviderToGetDate()
            {
                var d = new DateTime(2010, 10, 10);
                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.BillingHistory).Returns(true);
                f.AccountingProvider.GetLastInvoiceDate(Arg.Any<int>()).ReturnsForAnyArgs(d);

                var result = await f.Subject.GetBillingDetails(10);
                Assert.Equal(result.LastInvoiceDate, d);
                f.AccountingProvider.Received(1).GetLastInvoiceDate(Arg.Is(10)).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GetWipBalance : FactBase
        {
            [Fact]
            public async Task ChecksSubjectSecurity()
            {
                var caseId = Fixture.Integer();
                var f = new CaseSummaryDetailsControllerFixture(Db);
                var result = await f.Subject.GetWipBalances(caseId);
                f.AccountingProvider.DidNotReceiveWithAnyArgs().GetAgeingBrackets().IgnoreAwaitForNSubstituteAssertion();
                f.AccountingProvider.DidNotReceiveWithAnyArgs().GetAgedWipTotals(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.Null(result);
            }

            [Fact]
            public async Task GetsAgedBalancePerPeriodForTheCase()
            {
                var caseId = Fixture.Integer();
                var f = new CaseSummaryDetailsControllerFixture(Db);
                f.SubjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems).Returns(true);
                var brackets = new AgeingBrackets { BaseDate = Fixture.Today(), Bracket0 = Fixture.Integer(), Bracket1 = Fixture.Integer(), Bracket2 = Fixture.Integer() };
                f.AccountingProvider.GetAgeingBrackets().Returns(brackets);
                await f.Subject.GetWipBalances(caseId);
                f.AccountingProvider.Received(1).GetAgeingBrackets().IgnoreAwaitForNSubstituteAssertion();
                f.AccountingProvider.Received(1).GetAgedWipTotals(caseId, brackets.BaseDate, brackets.Current, brackets.Previous, brackets.Last).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class CaseSummaryDetailsControllerFixture : IFixture<CaseSummaryDetailsController>
        {
            public CaseSummaryDetailsControllerFixture(InMemoryDbContext db, bool withMultipleNames = false)
            {
                CaseSummaryNamesProvider = Substitute.For<ICaseSummaryNamesProvider>();
                var caseSummaryNames = new List<TimeCaseSummaryName>
                {
                    new TimeCaseSummaryName
                    {
                        TypeId = KnownNameTypes.StaffMember,
                        Name = Fixture.String("EMP-")
                    },
                    new TimeCaseSummaryName
                    {
                        TypeId = KnownNameTypes.Signatory,
                        Name = Fixture.String("SIG-=")
                    },
                    new TimeCaseSummaryName
                    {
                        TypeId = KnownNameTypes.Instructor,
                        Name = Fixture.String("Instructor-")
                    },
                    new TimeCaseSummaryName
                    {
                        TypeId = KnownNameTypes.Owner,
                        Name = Fixture.String("Owner-")
                    },
                    new TimeCaseSummaryName
                    {
                        TypeId = KnownNameTypes.Debtor,
                        Name = Fixture.String("Debtor-")
                    }
                };
                if (withMultipleNames)
                {
                    caseSummaryNames.AddRange(new[]
                    {
                        new TimeCaseSummaryName
                        {
                            TypeId = KnownNameTypes.StaffMember,
                            Name = Fixture.String("EMP-")
                        },
                        new TimeCaseSummaryName
                        {
                            TypeId = KnownNameTypes.Signatory,
                            Name = Fixture.String("SIG-")
                        },
                        new TimeCaseSummaryName
                        {
                            TypeId = KnownNameTypes.Owner,
                            Name = Fixture.String("Owner-")
                        },
                        new TimeCaseSummaryName
                        {
                            TypeId = KnownNameTypes.Debtor,
                            Name = Fixture.String("Debtor-")
                        }
                    });
                }
                CaseSummaryNamesProvider.GetNames(Arg.Any<int>()).Returns(caseSummaryNames);
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                StatusReader = Substitute.For<ICaseStatusReader>();
                SubjectSecurity = Substitute.For<ISubjectSecurityProvider>();
                AccountingProvider = Substitute.For<IAccountingProvider>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                TodayFunc = Substitute.For<Func<DateTime>>();
                TodayFunc().Returns(Fixture.Today());

                Subject = new CaseSummaryDetailsController(db, PreferredCultureResolver, StatusReader, CaseSummaryNamesProvider, SubjectSecurity, AccountingProvider, SiteControlReader, TodayFunc);
            }

            public ICaseSummaryNamesProvider CaseSummaryNamesProvider { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ICaseStatusReader StatusReader { get; set; }
            public ISubjectSecurityProvider SubjectSecurity { get; set; }
            public CaseSummaryDetailsController Subject { get; set; }
            public IAccountingProvider AccountingProvider { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public Func<DateTime> TodayFunc { get; set; }
        }
    }
}