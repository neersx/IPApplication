using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Wip
{
    public class CaseStatusValidatorFacts
    {
        public class CaseStatusValidatorFixture : IFixture<CaseStatusValidator>
        {
            public CaseStatusValidatorFixture(IDbContext db)
            {
                Subject = new CaseStatusValidator(db);
            }

            public CaseStatusValidator Subject { get; }
        }

        public class IsRestrictedCaseStatus : FactBase
        {
            dynamic CreateSingleCaseWithCaseStatus()
            {
                var @case = new Case().In(Db);
                var status = new Status().In(Db);
                @case.StatusCode = status.Id;

                return new
                {
                    Case = @case,
                    Status = status
                };
            }

            [Fact] 
            public async Task ShouldThrowExceptionWhenStatusKeyIsNull()
            {
                var data = CreateSingleCaseWithCaseStatus();

                var subject = new CaseStatusValidatorFixture(Db).Subject;
                
                await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                                                                    await subject.IsRestrictedCaseStatus(data.Case.Id, null));
            }

            [Fact]
            public async Task ShouldReturnFalseWhenStatusAllowsWipAndBilling()
            {
                var data = CreateSingleCaseWithCaseStatus();

                var subject = new CaseStatusValidatorFixture(Db).Subject;
                
                Assert.False(await subject.IsRestrictedCaseStatus(data.Case.Id, data.Status.Id));
            }

            [Fact]
            public async Task ShouldReturnFalseWhenStatusPreventsWipAndCaseHasNoUnpostedTime()
            {
                var data = CreateSingleCaseWithCaseStatus();
                data.Status.PreventWip = true;

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.False(await subject.IsRestrictedCaseStatus(data.Case.Id, data.Status.Id));
            }

            [Fact]
            public async Task ShouldReturnTrueWhenStatusPreventsWipAndCaseHasUnpostedTime()
            {
                var data = CreateSingleCaseWithCaseStatus();
                data.Status.PreventWip = true;
                new Diary {Case = data.Case, IsTimer = 0, TimeValue = 10}.In(Db);

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.True(await subject.IsRestrictedCaseStatus(data.Case.Id, data.Status.Id));
            }

            [Fact]
            public async Task ShouldReturnFalseWhenStatusPreventsWipAndCaseHasTimerButNoUnpostedTime()
            {
                var data = CreateSingleCaseWithCaseStatus();
                data.Status.PreventWip = true;
                new Diary {CaseId = data.Case.Id, IsTimer = 1}.In(Db);

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.False(await subject.IsRestrictedCaseStatus(data.Case.Id, data.Status.Id));
            }

            [Fact]
            public async Task ShouldReturnFalseWhenStatusPreventsBillingAndCaseHasNoWipAndNoUnpostedTime()
            {
                var data = CreateSingleCaseWithCaseStatus();
                data.Status.PreventBilling = true;

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.False(await subject.IsRestrictedCaseStatus(data.Case.Id, data.Status.Id));
            }

            [Fact]
            public async Task ShouldReturnTrueWhenStatusPreventsBillingAndCaseHasUnpostedTime()
            {
                var data = CreateSingleCaseWithCaseStatus();
                data.Status.PreventBilling = true;
                new Diary {Case = data.Case, IsTimer = 0, TimeValue = 10}.In(Db);

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.True(await subject.IsRestrictedCaseStatus(data.Case.Id, data.Status.Id));
            }

            [Fact]
            public async Task ShouldReturnTrueWhenStatusPreventsBillingAndCaseHasWip()
            {
                var data = CreateSingleCaseWithCaseStatus();
                data.Status.PreventBilling = true;
                new WorkInProgress {Case = data.Case, Status = (short) TransactionStatus.Draft}.In(Db);

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.True(await subject.IsRestrictedCaseStatus(data.Case.Id, data.Status.Id));
            }
        }

        public class IsCaseStatusRestrictedForWip : FactBase
        {
            dynamic CreateSingleCaseWithCaseStatus()
            {
                var @case = new Case().In(Db);
                var status = new Status().In(Db);
                @case.StatusCode = status.Id;

                return new
                {
                    Case = @case,
                    Status = status
                };
            }

            [Fact]
            public async Task ShouldReturnFalseWhenCaseStatusDoesnotPreventWip()
            {
                var data = CreateSingleCaseWithCaseStatus();

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.False(await subject.IsCaseStatusRestrictedForWip(data.Case.Id));
            }

            [Fact]
            public async Task ShouldReturnTrueWhenCaseStatusPreventWip()
            {
                var @case = CreateSingleCaseWithCaseStatus();
                @case.Status.PreventWip = true;

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.True(await subject.IsCaseStatusRestrictedForWip(@case.Case.Id));
            }
        }

        public class IsCaseStatusRestrictedForPrepayment : FactBase
        {
            dynamic CreateSingleCaseWithCaseStatus()
            {
                var @case = new Case().In(Db);
                var status = new Status().In(Db);
                @case.StatusCode = status.Id;

                return new
                {
                    Case = @case,
                    Status = status
                };
            }

            [Fact]
            public async Task ShouldReturnTrueWhenPrepaymentIsRestrictedOnCaseStatus()
            {
                var @case = CreateSingleCaseWithCaseStatus();
                @case.Status.PreventPrepayment = true;

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                Assert.True(await subject.IsCaseStatusRestrictedForPrepayment(@case.Case.Id));
            }
        }

        public class GetCasesRestrictedForBilling : FactBase
        {
            [Fact]
            public async Task ShouldReturnListofCasesHavingBillingRestriction()
            {
                var firstCase = new Case().In(Db);
                var secondCase = new Case().In(Db);

                var caseList = new int[] {firstCase.Id, secondCase.Id};
                var preventBillingStatus = new Status().In(Db);
                preventBillingStatus.PreventBilling = true;
                var doesNotPreventBillingStatus = new Status().In(Db);
                doesNotPreventBillingStatus.PreventBilling = false;

                firstCase.StatusCode = preventBillingStatus.Id;
                secondCase.StatusCode = doesNotPreventBillingStatus.Id;

                var subject = new CaseStatusValidatorFixture(Db).Subject;
                var result = await subject.GetCasesRestrictedForBilling(caseList).SingleAsync(); 

                Assert.Equal(firstCase, result);
            }
        }

        public class ListRestrictedCasesForStatusChange : FactBase
        {
            [Fact]
            public void ShouldReturnEmptyListWhenStatusPreventsWipAndNoCasesHasUnpostedTime()
            {
                var firstCase = new Case().In(Db);
                var secondCase = new Case().In(Db);
                var thirdCase = new Case().In(Db);
                var status = new Status().In(Db);
                var caseKeys = new[] { firstCase.Id, secondCase.Id, thirdCase.Id};

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var restrictedCases = subject.ListRestrictedCasesForStatusChange(caseKeys, status.Id).AsEnumerable().ToArray();

                Assert.Empty(restrictedCases);
            }

            [Fact]
            public void ShouldReturnCasesWhenStatusPreventsWipAndCaseHasUnpostedTime()
            {
                var firstCase = new Case().In(Db);
                var secondCase = new Case().In(Db);
                var thirdCase = new Case().In(Db);
                var status = new Status
                {
                    PreventWip = true
                }.In(Db);

                var caseKeys = new[] { firstCase.Id, secondCase.Id, thirdCase.Id};
                
                new Diary {CaseId = firstCase.Id, IsTimer = 0, TimeValue = 10}.In(Db);

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var restrictedCases = subject.ListRestrictedCasesForStatusChange(caseKeys, status.Id).AsEnumerable().ToArray();

                Assert.Single(restrictedCases);
                Assert.Equal(firstCase, restrictedCases.Single());
            }

            [Fact]
            public void ShouldReturnCasesWhenStatusPreventsBillingAndCaseHasWip()
            {
                var firstCase = new Case().In(Db);
                var secondCase = new Case().In(Db);
                var thirdCase = new Case().In(Db);
                var status = new Status
                {
                    PreventBilling = true
                }.In(Db);

                var caseKeys = new[] { firstCase.Id, secondCase.Id, thirdCase.Id};
                
                new Diary {CaseId = firstCase.Id, IsTimer = 0, TimeValue = 10}.In(Db);
                new WorkInProgress {CaseId = secondCase.Id}.In(Db);

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var restrictedCases = subject.ListRestrictedCasesForStatusChange(caseKeys, status.Id).AsEnumerable().ToArray();

                Assert.Equal(2, restrictedCases.Length);
                Assert.Equal(new[] {firstCase, secondCase}, restrictedCases);
            }
        }

        public class HasAnyBillCasesRestricted : FactBase
        {
            dynamic CreateSetUpData()
            {
                var preventBillingStatus = new Status {PreventBilling = true}.In(Db);
                var firstCase = new Case {StatusCode = preventBillingStatus.Id}.In(Db);
                var secondCase = new Case().In(Db);

                var firstOpenItem = new OpenItem {ItemEntityId = 1, ItemTransactionId = 1, Status = TransactionStatus.Active}.In(Db);
                var secondOpenItem = new OpenItem {ItemEntityId = 2, ItemTransactionId = 2, Status = TransactionStatus.Locked}.In(Db);
                var thirdOpenItem = new OpenItem {ItemEntityId = 3, ItemTransactionId = 3, Status = TransactionStatus.Active}.In(Db);
                var fourthOpenItem = new OpenItem {ItemEntityId = 4, ItemTransactionId = 4, Status = TransactionStatus.Locked}.In(Db);

                var fifthOpenItem = new OpenItem {ItemEntityId = 5, ItemTransactionId = 5, Status = TransactionStatus.Reversed}.In(Db);
                var sixthOpenItem = new OpenItem {ItemEntityId = 6, ItemTransactionId = 6, Status = TransactionStatus.Reversed}.In(Db);

                new WorkHistory {RefEntityId = 1, RefTransactionId = 1, CaseId = firstCase.Id}.In(Db);
                new WorkHistory {RefEntityId = 3, RefTransactionId = 3, CaseId = secondCase.Id}.In(Db);

                new WorkHistory {RefEntityId = 5, RefTransactionId = 5, CaseId = firstCase.Id}.In(Db);
                new WorkHistory {RefEntityId = 6, RefTransactionId = 6, CaseId = secondCase.Id}.In(Db);

                var wip = new WorkInProgress {EntityId = 2, TransactionId = 2, WipSequenceNo = 1, Case = firstCase}.In(Db);
                new BilledItem {EntityId = 2, TransactionId = 2, WipEntityId = wip.EntityId, WipTransactionId = wip.TransactionId, WipSequenceNo = wip.WipSequenceNo}.In(Db);

                var wip2 = new WorkInProgress {EntityId = 4, TransactionId = 4, WipSequenceNo = 2, Case = secondCase}.In(Db);
                new BilledItem {EntityId = 4, TransactionId = 4, WipEntityId = wip2.EntityId, WipTransactionId = wip2.TransactionId, WipSequenceNo = wip2.WipSequenceNo}.In(Db);

                return new
                {
                    FirstOpenItem = firstOpenItem,
                    SecondOpenItem = secondOpenItem,
                    ThirdOpenItem = thirdOpenItem,
                    FourthOpenItem = fourthOpenItem,
                    FifthOpenItem = fifthOpenItem,
                    SixthOpenItem = sixthOpenItem
                };
            }

            [Fact]
            public async Task ShouldReturnTrueWhenFinalisedBillContainsRestrictedCase()
            {
                var data = CreateSetUpData();

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var hasRestrictedCases = await subject.HasAnyBillCasesRestricted(data.FirstOpenItem.ItemEntityId, data.FirstOpenItem.ItemTransactionId);

                Assert.True(hasRestrictedCases);
            }

            [Fact]
            public async Task ShouldReturnFalseWhenFinalisedBillDoNotContainAnyRestrictedCase()
            {
                var data = CreateSetUpData();

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var hasRestrictedCases = await subject.HasAnyBillCasesRestricted(data.ThirdOpenItem.ItemEntityId, data.ThirdOpenItem.ItemTransactionId);

                Assert.False(hasRestrictedCases);
            }

            [Fact]
            public async Task ShouldReturnTrueWhenCreditBillContainsRestrictedCase()
            {
                var data = CreateSetUpData();

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var hasRestrictedCases = await subject.HasAnyBillCasesRestricted(data.FifthOpenItem.ItemEntityId, data.FifthOpenItem.ItemTransactionId);

                Assert.True(hasRestrictedCases);
            }

            [Fact]
            public async Task ShouldReturnFalseWhenCreditBillDoNotContainAnyRestrictedCase()
            {
                var data = CreateSetUpData();

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var hasRestrictedCases = await subject.HasAnyBillCasesRestricted(data.SixthOpenItem.ItemEntityId, data.SixthOpenItem.ItemTransactionId);

                Assert.False(hasRestrictedCases);
            }

            [Fact]
            public async Task ShouldReturnTrueWhenDraftBillContainsRestrictedCase()
            {
                var data = CreateSetUpData();

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var hasRestrictedCases = await subject.HasAnyBillCasesRestricted(data.SecondOpenItem.ItemEntityId, data.SecondOpenItem.ItemTransactionId);

                Assert.True(hasRestrictedCases);
            }

            [Fact]
            public async Task ShouldReturnFalseWhenDraftBillDoNotContainsRestrictedCase()
            {
                var data = CreateSetUpData();

                var subject = new CaseStatusValidatorFixture(Db).Subject;

                var hasRestrictedCases = await subject.HasAnyBillCasesRestricted(data.FourthOpenItem.ItemEntityId, data.FourthOpenItem.ItemTransactionId);

                Assert.False(hasRestrictedCases);
            }
        }
    }
}