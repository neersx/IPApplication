using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Delivery
{
    public class FinalisedBillDetailsResolverFacts : FactBase
    {
        [Theory]
        [InlineData(ItemType.DebitNote)]
        [InlineData(ItemType.CreditNote)]
        public async Task ShouldResolveDebtorOnlyBillDetails(ItemType itemType)
        {
            var openItem = new OpenItem
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                AccountEntityId = Fixture.Integer(),
                AccountDebtorId = Fixture.Integer(),
                OpenItemNo = Fixture.String(),
                ItemDate = Fixture.PastDate(),
                TypeId = itemType
            }.In(Db);

            var request = new BillGenerationRequest
            {
                ItemEntityId = openItem.ItemEntityId,
                ItemTransactionId = openItem.ItemTransactionId,
                OpenItemNo = openItem.OpenItemNo,
                FileName = Fixture.String(),
                IsFinalisedBill = true
            };

            var subject = new FinalisedBillDetailsResolver(Db);

            var r = await subject.Resolve(request);

            Assert.Equal(openItem.ItemDate, r.ItemDate);
            Assert.Equal(openItem.TypeId, r.ItemType);
            Assert.Equal(openItem.AccountDebtorId, r.DebtorId);
            Assert.Empty(r.Cases);
        }

        [Theory]
        [InlineData(ItemType.DebitNote)]
        [InlineData(ItemType.CreditNote)]
        public async Task ShouldReturnAllCasesIncludedInTheBill(ItemType itemType)
        {
            var case1 = new CaseBuilder().Build().In(Db);
            var case2 = new CaseBuilder().Build().In(Db);

            var openItem = new OpenItem
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                AccountEntityId = Fixture.Integer(),
                AccountDebtorId = Fixture.Integer(),
                OpenItemNo = Fixture.String(),
                ItemDate = Fixture.PastDate(),
                TypeId = itemType
            }.In(Db);

            new WorkHistory
            {
                CaseId = case1.Id,
                RefEntityId = openItem.ItemEntityId,
                RefTransactionId = openItem.ItemTransactionId
            }.In(Db);

            new WorkHistory
            {
                CaseId = case2.Id,
                RefEntityId = openItem.ItemEntityId,
                RefTransactionId = openItem.ItemTransactionId
            }.In(Db);

            var request = new BillGenerationRequest
            {
                ItemEntityId = openItem.ItemEntityId,
                ItemTransactionId = openItem.ItemTransactionId,
                OpenItemNo = openItem.OpenItemNo,
                FileName = Fixture.String(),
                IsFinalisedBill = true
            };

            var subject = new FinalisedBillDetailsResolver(Db);

            var r = await subject.Resolve(request);

            Assert.Equal(openItem.ItemDate, r.ItemDate);
            Assert.Equal(openItem.TypeId, r.ItemType);
            Assert.Equal(openItem.AccountDebtorId, r.DebtorId);
            Assert.Collection(r.Cases,
                              x =>
                              {
                                  Assert.Equal(case1.Id, x.Key);
                                  Assert.Equal(case1.Irn, x.Value);
                              },
                              x =>
                              {
                                  Assert.Equal(case2.Id, x.Key);
                                  Assert.Equal(case2.Irn, x.Value);
                              });
        }
    }
}