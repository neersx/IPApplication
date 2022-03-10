using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Cases
{
    public class CaseWipCalculatorFacts
    {
        public class CaseWipCalculatorFixture : IFixture<CaseWipCalculator>
        {
            public CaseWipCalculatorFixture(IDbContext dbContext)
            {
                Subject = new CaseWipCalculator(dbContext, SettingsResolver);
            }

            public IBillingSiteSettingsResolver SettingsResolver { get; } = Substitute.For<IBillingSiteSettingsResolver>();

            public CaseWipCalculator Subject { get; }

            public CaseWipCalculatorFixture WithInterEntityBillingSetting(bool settingValue)
            {
                SettingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                                .Returns(new BillingSiteSettings
                                {
                                    InterEntityBilling = settingValue
                                });

                return this;
            }
        }

        public class GetUnlockedAvailableWip : FactBase
        {
            [Fact]
            public async Task ShouldGetWipAgainstCase()
            {
                new WorkInProgress
                {
                    CaseId = 1,
                    Status = TransactionStatus.Active,
                    Balance = 1
                }.In(Db);

                new WorkInProgress
                {
                    CaseId = 1,
                    Status = TransactionStatus.Locked,
                    Balance = 1
                }.In(Db);

                var fixture = new CaseWipCalculatorFixture(Db)
                    .WithInterEntityBillingSetting(true);

                var subject = fixture.Subject;

                var result = await subject.GetUnlockedAvailableWip(1, null);

                Assert.Equal(1, result);
            }

            [Fact]
            public async Task ShouldGetWipAgainstCaseAndEntity()
            {
                new WorkInProgress
                {
                    CaseId = 1,
                    EntityId = 1,
                    Status = TransactionStatus.Active,
                    Balance = 1
                }.In(Db);

                new WorkInProgress
                {
                    CaseId = 1,
                    Status = TransactionStatus.Locked,
                    Balance = 1
                }.In(Db);

                var fixture = new CaseWipCalculatorFixture(Db)
                    .WithInterEntityBillingSetting(true);

                var subject = fixture.Subject;

                var result = await subject.GetUnlockedAvailableWip(1, 1);

                Assert.Equal(1, result);
            }
        }

        public class GetTotalAvailableWip : FactBase
        {
            [Fact]
            public async Task ShouldGetWipAgainstCase()
            {
                new WorkInProgress
                {
                    CaseId = 1,
                    Status = TransactionStatus.Active,
                    Balance = 1
                }.In(Db);

                new WorkInProgress
                {
                    CaseId = 1,
                    Status = TransactionStatus.Locked,
                    Balance = 1
                }.In(Db);

                var fixture = new CaseWipCalculatorFixture(Db)
                    .WithInterEntityBillingSetting(true);

                var subject = fixture.Subject;

                var result = await subject.GetTotalAvailableWip(1, null);

                Assert.Equal(2, result);
            }

            [Fact]
            public async Task ShouldGetWipAgainstCaseAndEntity()
            {
                new WorkInProgress
                {
                    CaseId = 1,
                    EntityId = 1,
                    Status = TransactionStatus.Active,
                    Balance = 1
                }.In(Db);

                new WorkInProgress
                {
                    CaseId = 1,
                    Status = TransactionStatus.Locked,
                    Balance = 1
                }.In(Db);

                var fixture = new CaseWipCalculatorFixture(Db)
                    .WithInterEntityBillingSetting(false);

                var subject = fixture.Subject;

                var result = await subject.GetTotalAvailableWip(1, 1);

                Assert.Equal(1, result);
            }
        }

        public class GetDraftBillsByCaseMethod : FactBase
        {
            (int CaseId, string OpenItemNo) CreateOpenItemWithCase(ItemType itemType, TransactionStatus itemStatus, int caseId)
            {
                var wip = new WorkInProgress
                {
                    EntityId = Fixture.Integer(),
                    TransactionId = Fixture.Integer(),
                    WipSequenceNo = Fixture.Short(),
                    CaseId = caseId
                }.In(Db);

                var openItem = new OpenItem
                {
                    OpenItemNo = Fixture.String(),
                    ItemEntityId = Fixture.Integer(),
                    ItemTransactionId = Fixture.Integer(),
                    TypeId = itemType,
                    Status = itemStatus
                }.In(Db);

                new BilledItem
                {
                    EntityId = openItem.ItemEntityId,
                    TransactionId = openItem.ItemTransactionId,
                    WipEntityId = wip.EntityId,
                    WipTransactionId = wip.TransactionId,
                    WipSequenceNo = wip.WipSequenceNo
                }.In(Db);

                return (caseId, openItem.OpenItemNo);
            }

            [Fact]
            public async Task ShouldNotReturnIfWarningNotRequiredToPreventCreatingMultipleDraftBillsForSameCase()
            {
                var draftBill = CreateOpenItemWithCase(ItemType.DebitNote, TransactionStatus.Draft, Fixture.Integer());

                var fixture = new CaseWipCalculatorFixture(Db);

                fixture.SettingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                       .Returns(new BillingSiteSettings
                       {
                           ShouldWarnIfDraftBillForSameCaseExist = false
                       });

                var result = await fixture.Subject.GetDraftBillsByCase(draftBill.CaseId);

                Assert.Empty(result);
            }

            [Theory]
            [InlineData(ItemType.DebitNote)]
            [InlineData(ItemType.InternalDebitNote)]
            public async Task ShouldReturnDistinctDraftOpenItemNosForCasesRequested(ItemType debitNoteType)
            {
                var caseId1 = Fixture.Integer();
                var caseId2 = Fixture.Integer();

                var draftBill1 = CreateOpenItemWithCase(debitNoteType, TransactionStatus.Draft, caseId1);
                var draftBill2 = CreateOpenItemWithCase(debitNoteType, TransactionStatus.Draft, caseId2);
                var draftBill3 = CreateOpenItemWithCase(debitNoteType, TransactionStatus.Draft, caseId1);

                var fixture = new CaseWipCalculatorFixture(Db);

                fixture.SettingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                       .Returns(new BillingSiteSettings
                       {
                           ShouldWarnIfDraftBillForSameCaseExist = true
                       });

                var result = await fixture.Subject.GetDraftBillsByCase(caseId1, caseId2);

                Assert.Equal(draftBill2.OpenItemNo, result[caseId2].Single());
                Assert.Equal(new[] {draftBill1.OpenItemNo, draftBill3.OpenItemNo}, result[caseId1]);
            }

            [Theory]
            [InlineData(ItemType.CreditNote)]
            [InlineData(ItemType.InternalCreditNote)]
            public async Task ShouldNotConsiderWhenDraftingCreditNotes(ItemType creditNoteType)
            {
                var caseId1 = Fixture.Integer();
                var caseId2 = Fixture.Integer();

                CreateOpenItemWithCase(creditNoteType, TransactionStatus.Draft, caseId1);
                CreateOpenItemWithCase(creditNoteType, TransactionStatus.Draft, caseId2);
                CreateOpenItemWithCase(creditNoteType, TransactionStatus.Draft, caseId1);

                var fixture = new CaseWipCalculatorFixture(Db);

                fixture.SettingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                       .Returns(new BillingSiteSettings
                       {
                           ShouldWarnIfDraftBillForSameCaseExist = true
                       });

                var result = await fixture.Subject.GetDraftBillsByCase(caseId1, caseId2);

                Assert.Empty(result);
            }

            [Theory]
            [InlineData(TransactionStatus.Active)]
            [InlineData(TransactionStatus.Reversed)]
            public async Task ShouldNotConsiderWhenViewingFinalisedOrReversedDebitNotes(TransactionStatus nonDraftStatus)
            {
                var caseId1 = Fixture.Integer();
                var caseId2 = Fixture.Integer();

                CreateOpenItemWithCase(ItemType.DebitNote, nonDraftStatus, caseId1);
                CreateOpenItemWithCase(ItemType.DebitNote, nonDraftStatus, caseId2);
                CreateOpenItemWithCase(ItemType.DebitNote, nonDraftStatus, caseId1);

                var fixture = new CaseWipCalculatorFixture(Db);

                fixture.SettingsResolver.Resolve(Arg.Any<BillingSiteSettingsScope>())
                       .Returns(new BillingSiteSettings
                       {
                           ShouldWarnIfDraftBillForSameCaseExist = true
                       });

                var result = await fixture.Subject.GetDraftBillsByCase(caseId1, caseId2);

                Assert.Empty(result);
            }
        }
    }
}