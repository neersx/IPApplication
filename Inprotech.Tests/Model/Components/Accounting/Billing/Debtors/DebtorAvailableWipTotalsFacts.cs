using System;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Debtors
{
    public class DebtorAvailableWipTotalsFacts
    {
        public class Fixture : IFixture<DebtorAvailableWipTotals>
        {
            public Fixture(IDbContext dbContext)
            {
                Subject = new DebtorAvailableWipTotals(dbContext, SettingsResolver);
            }

            public IBillingSiteSettingsResolver SettingsResolver { get; } = Substitute.For<IBillingSiteSettingsResolver>();

            public DebtorAvailableWipTotals Subject { get; }

            public Fixture WithInterEntityBillingSetting(bool settingValue)
            {
                SettingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                                .Returns(new BillingSiteSettings
                                {
                                    InterEntityBilling = settingValue
                                });

                return this;
            }
        }

        public class ForNewBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowArgumentNullExceptionIfCaseListIsEmpty()
            {
                var fixture = new Fixture(Db).WithInterEntityBillingSetting(false);

                var subject = fixture.Subject;

                await Assert.ThrowsAsync<ArgumentNullException>(
                                                                async () => await subject.ForNewBill(null, null, null));
            }

            [Fact]
            public async Task ShouldReturnTotalWipWithNullParameters()
            {
                new WorkInProgress
                {
                    Status = TransactionStatus.Active,
                    Balance = 1
                }.In(Db);

                new WorkInProgress
                {
                    Status = TransactionStatus.Active,
                    Balance = 1
                }.In(Db);

                new WorkInProgress
                {
                    Status = (short) TransactionStatus.Draft,
                    Balance = 1
                }.In(Db);

                var fixture = new Fixture(Db).WithInterEntityBillingSetting(true);

                var subject = fixture.Subject;

                var result = await subject.ForNewBill(new int[] { }, null, null);

                Assert.Equal(2, result);
            }

            [Fact]
            public async Task ShouldGetTotalWipAgainstCases()
            {
                new WorkInProgress
                {
                    CaseId = 1,
                    Status = TransactionStatus.Active,
                    Balance = 1
                }.In(Db);

                var fixture = new Fixture(Db).WithInterEntityBillingSetting(true);

                var subject = fixture.Subject;

                var result = await subject.ForNewBill(new[] {1}, null, null);

                Assert.Equal(1, result);
            }

            [Fact]
            public async Task ShouldGetWipAgainstDebtor()
            {
                new WorkInProgress
                {
                    Status = TransactionStatus.Active,
                    Balance = 1,
                    AccountClientId = 1
                }.In(Db);

                new WorkInProgress
                {
                    Status = TransactionStatus.Active,
                    Balance = 1
                }.In(Db);

                new WorkInProgress
                {
                    Status = TransactionStatus.Active,
                    Balance = 1,
                    AccountClientId = 2
                }.In(Db);

                var fixture = new Fixture(Db).WithInterEntityBillingSetting(true);

                var subject = fixture.Subject;

                var result = await subject.ForNewBill(new int[] { }, 1, null);

                Assert.Equal(1, result);
            }
        }

        public class ForDraftBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowArgumentNullExceptionIfCaseListIsEmpty()
            {
                var fixture = new Fixture(Db).WithInterEntityBillingSetting(false);

                var subject = fixture.Subject;

                await Assert.ThrowsAsync<ArgumentNullException>(
                                                                async () => await subject.ForDraftBill(null, 1, 1, 1));
            }

            [Fact]
            public async Task ShouldGetTotalWip()
            {
                new WorkInProgress
                {
                    CaseId = 1,
                    Status = TransactionStatus.Active,
                    Balance = 1,
                    AccountClientId = 1,
                    EntityId = 1
                }.In(Db);

                new BilledItem
                {
                    EntityId = 1,
                    TransactionId = 1,
                    AccountDebtorId = 1,
                    BilledValue = 1
                }.In(Db);

                new BilledItem().In(Db);

                var fixture = new Fixture(Db).WithInterEntityBillingSetting(false);

                var subject = fixture.Subject;

                var result = await subject.ForDraftBill(new[] {1}, 1, 1, 1);

                Assert.Equal(2, result);
            }
        }
    }
}