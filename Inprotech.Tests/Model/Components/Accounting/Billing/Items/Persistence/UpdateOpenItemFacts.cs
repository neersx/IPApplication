using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class UpdateOpenItemFacts : FactBase
    {
        readonly IBilledItems _billedItems = Substitute.For<IBilledItems>();
        readonly IClassicUserResolver _classicUserResolver = Substitute.For<IClassicUserResolver>();

        UpdateOpenItem CreateSubject()
        {
            var logger = Substitute.For<ILogger<UpdateOpenItem>>();

            return new UpdateOpenItem(Db, _billedItems, _classicUserResolver, logger);
        }

        [Fact]
        public async Task ShouldReinstateBilledItems()
        {
            /*
             * The BilledItem Reinstate component has below responsibility
             * * reinstate all items included in the bill to unlocked status
             * * delete data that held those items.
             *
             * It is only to be used when updating an existing bill.  
             * The unlocked (previously included) WIP will be included again in subsequent components that will be executed
             * The other structures that holds the WIP, presentation, bill etc will be recreated in subsequent components that will be executed
             */

            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            new TransactionHeader
            {
                EntityId = itemEntityId,
                TransactionId = itemTransactionId,
                LogDateTimeStamp = Fixture.Today()
            }.In(Db);

            var result = new SaveOpenItemResult(Guid.NewGuid());

            var subject = CreateSubject();

            await subject.Run(43, "en",
                              new BillingSiteSettings(),
                              new OpenItemModel
                              {
                                  ItemEntityId = itemEntityId,
                                  ItemTransactionId = itemTransactionId,
                                  LogDateTimeStamp = Fixture.Today()
                              },
                              result);

            _billedItems.Received(1).Reinstate(itemEntityId, itemTransactionId, result.RequestId)
                        .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldUpdateTransactionHeaderToDraftStatusWithClassicUserAsUserLoginId()
        {
            var userIdentityId = Fixture.Integer();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var itemDate = Fixture.PastDate();
            var logDateTimeStamp = Fixture.Today();
            var classicUser = Fixture.String();
            var staffId = Fixture.Integer();

            var th = new TransactionHeader
            {
                EntityId = itemEntityId,
                TransactionId = itemTransactionId,
                LogDateTimeStamp = Fixture.Today()
            }.In(Db);

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
                                  ItemDate = itemDate,
                                  StaffId = staffId
                              },
                              result);

            Assert.Equal(staffId, th.StaffId);
            Assert.Equal(userIdentityId, th.IdentityId);
            Assert.Equal(classicUser, th.UserLoginId);
            Assert.Equal(itemDate, th.TransactionDate);
            Assert.Equal(SystemIdentifier.TimeAndBilling, th.Source);
            Assert.Equal(TransactionStatus.Draft, th.TransactionStatus);
        }
    }
}
