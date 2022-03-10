using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class NewOpenItemFacts : FactBase
    {
        readonly ILastInternalCodeGenerator _iLastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
        readonly IClassicUserResolver _classicUserResolver = Substitute.For<IClassicUserResolver>();

        NewOpenItem CreateSubject()
        {
            var logger = Substitute.For<ILogger<NewOpenItem>>();

            return new NewOpenItem(Db, _iLastInternalCodeGenerator, _classicUserResolver, logger, Fixture.Today);
        }

        [Theory]
        [InlineData(ItemType.CreditNote, TransactionType.CreditNote)]
        [InlineData(ItemType.InternalCreditNote, TransactionType.InternalCreditNote)]
        [InlineData(ItemType.DebitNote, TransactionType.Bill)]
        [InlineData(ItemType.InternalDebitNote, TransactionType.InternalBill)]
        public async Task ShouldCreateTransactionHeaderToDraftStatusWithClassicUserAsUserLoginId(ItemType itemType, TransactionType expectedTransactionType)
        {
            var userIdentityId = Fixture.Integer();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var itemDate = Fixture.PastDate();
            var logDateTimeStamp = Fixture.Today();
            var classicUser = Fixture.String();
            var staffId = Fixture.Integer();

            _iLastInternalCodeGenerator.GenerateLastInternalCode("TRANSACTIONHEADER")
                                       .Returns(itemTransactionId);

            _classicUserResolver.Resolve(userIdentityId).Returns(classicUser);

            var result = new SaveOpenItemResult(Guid.NewGuid());

            var subject = CreateSubject();

            await subject.Run(userIdentityId, "en",
                              new BillingSiteSettings(),
                              new OpenItemModel
                              {
                                  ItemEntityId = itemEntityId,
                                  ItemTransactionId = itemTransactionId,
                                  LogDateTimeStamp = logDateTimeStamp,
                                  ItemType = (int)itemType,
                                  ItemDate = itemDate,
                                  StaffId = staffId
                              },
                              result);

            var th = Db.Set<TransactionHeader>().Single();

            Assert.Equal(itemEntityId, th.EntityId);
            Assert.Equal(itemTransactionId, th.TransactionId);
            Assert.Equal(expectedTransactionType, th.TransactionType);
            Assert.Equal(staffId, th.StaffId);
            Assert.Equal(userIdentityId, th.IdentityId);
            Assert.Equal(classicUser, th.UserLoginId);
            Assert.Equal(itemDate, th.TransactionDate);
            Assert.Equal(Fixture.Today(), th.EntryDate);
            Assert.Equal(SystemIdentifier.TimeAndBilling, th.Source);
            Assert.Equal(TransactionStatus.Draft, th.TransactionStatus);

            Assert.Equal(th.TransactionId, result.TransactionId);
            Assert.Equal(th.LogDateTimeStamp, result.LogDateTimeStamp);
        }
    }
}
