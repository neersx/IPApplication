using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Type;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.ContactActivities;
using InprotechKaizen.Model.ContactActivities;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Delivery.Type
{
    public class AttachToCasesAndNamesFacts : FactBase
    {
        readonly ICreateActivityAttachment _createActivityAttachment = Substitute.For<ICreateActivityAttachment>();

        readonly IFinalisedBillDetailsResolver _finalisedBillDetailsResolver = Substitute.For<IFinalisedBillDetailsResolver>();

        AttachToCasesAndNames CreateSubject()
        {
            var logger = Substitute.For<ILogger<AttachToCasesAndNames>>();

            _createActivityAttachment.Exec(Arg.Any<int>(), null, null,
                                           Arg.Any<int>(), Arg.Any<int>(), null, null,
                                           null, null, null,
                                           Arg.Any<bool>())
                                     .ReturnsForAnyArgs(new Activity().In(Db));

            return new AttachToCasesAndNames(Db, logger, _finalisedBillDetailsResolver, _createActivityAttachment);
        }

        [Theory]
        [InlineData(ItemType.DebitNote)]
        [InlineData(ItemType.CreditNote)]
        public async Task ShouldAttachDebitNoteToMainDebtorOfTheBill(ItemType itemType)
        {
            var userIdentityId = Fixture.Integer();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var itemTypeDescription = Fixture.String();
            var accountDebtorId = Fixture.Integer();
            var openItemNo = Fixture.String();
            var itemDate = Fixture.PastDate();
            var useRenewalDebtor = Fixture.Boolean();

            _finalisedBillDetailsResolver.Resolve(Arg.Any<BillGenerationRequest>())
                                         .Returns((itemType, itemDate, accountDebtorId, new Dictionary<int, string>(), useRenewalDebtor));
            
            new DebtorItemType
            {
                Description = itemTypeDescription,
                ItemTypeId = (short)itemType
            }.In(Db).WithKnownId(x => x.ItemTypeId, (short)itemType);

            var request = new BillGenerationRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = openItemNo,
                FileName = Fixture.String(),
                IsFinalisedBill = true
            };

            var subject = CreateSubject();

            await subject.Deliver(userIdentityId, "en-AU", Guid.Empty, request);

            _createActivityAttachment
                .Received(1)
                .Exec(userIdentityId,
                      null,
                      accountDebtorId,
                      KnownActivityTypes.DebitOrCreditNote,
                      KnownActivityCategories.Billing,
                      itemDate,
                      itemTypeDescription,
                      $"{itemTypeDescription} {openItemNo}",
                      request.FileName,
                      isPublic: true)
                .IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData(ItemType.DebitNote)]
        [InlineData(ItemType.CreditNote)]
        public async Task ShouldAttachDebitNoteToEachOfTheCasesIncludedInTheBill(ItemType itemType)
        {
            var caseId1 = Fixture.Integer();
            var caseId2 = Fixture.Integer();
            var userIdentityId = Fixture.Integer();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var itemTypeDescription = Fixture.String();
            var accountDebtorId = Fixture.Integer();
            var openItemNo = Fixture.String();
            var itemDate = Fixture.PastDate();

            _finalisedBillDetailsResolver.Resolve(Arg.Any<BillGenerationRequest>())
                                         .Returns((itemType, itemDate, accountDebtorId, new Dictionary<int, string>
                                         {
                                             { caseId1, Fixture.String() },
                                             { caseId2, Fixture.String() }
                                         }, false));
            
            new DebtorItemType
            {
                Description = itemTypeDescription,
                ItemTypeId = (short)itemType
            }.In(Db).WithKnownId(x => x.ItemTypeId, (short)itemType);

            var request = new BillGenerationRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                OpenItemNo = openItemNo,
                FileName = Fixture.String(),
                IsFinalisedBill = true
            };

            var subject = CreateSubject();

            await subject.Deliver(userIdentityId, "en-AU", Guid.Empty, request);

            // debtor link created
            _createActivityAttachment
                .Received(1)
                .Exec(userIdentityId,
                      null,
                      accountDebtorId,
                      KnownActivityTypes.DebitOrCreditNote,
                      KnownActivityCategories.Billing,
                      itemDate,
                      itemTypeDescription,
                      $"{itemTypeDescription} {openItemNo}",
                      request.FileName,
                      isPublic: true)
                .IgnoreAwaitForNSubstituteAssertion();

            // case link created for caseId1
            _createActivityAttachment
                .Received(1)
                .Exec(userIdentityId,
                      caseId1,
                      null,
                      KnownActivityTypes.DebitOrCreditNote,
                      KnownActivityCategories.Billing,
                      itemDate,
                      itemTypeDescription,
                      $"{itemTypeDescription} {openItemNo}",
                      request.FileName,
                      isPublic: true)
                .IgnoreAwaitForNSubstituteAssertion();

            // case link created for caseId2
            _createActivityAttachment
                .Received(1)
                .Exec(userIdentityId,
                      caseId2,
                      null,
                      KnownActivityTypes.DebitOrCreditNote,
                      KnownActivityCategories.Billing,
                      itemDate,
                      itemTypeDescription,
                      $"{itemTypeDescription} {openItemNo}",
                      request.FileName,
                      isPublic: true)
                .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldOnlyAttachIfTheBillIsFinalised()
        {
            var userIdentityId = Fixture.Integer();
            
            var request = new BillGenerationRequest
            {
                IsFinalisedBill = false
            };

            var subject = CreateSubject();

            await subject.Deliver(userIdentityId, "en-AU", Guid.Empty, request);

            _createActivityAttachment.DidNotReceiveWithAnyArgs()
                                     .Exec(Arg.Any<int>(), null, null,
                                           Arg.Any<int>(), Arg.Any<int>(), null, null,
                                           null, null, null,
                                           Arg.Any<bool>())
                                     .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldAttachIfFileNameExists()
        {
            // File Names are assigned only if PDF generation has not been suppressed

            var userIdentityId = Fixture.Integer();
            
            var request = new BillGenerationRequest
            {
                IsFinalisedBill = true,
                FileName = null
            };

            var subject = CreateSubject();

            await subject.Deliver(userIdentityId, "en-AU", Guid.Empty, request);

            _createActivityAttachment.DidNotReceiveWithAnyArgs()
                                     .Exec(Arg.Any<int>(), null, null,
                                           Arg.Any<int>(), Arg.Any<int>(), null, null,
                                           null, null, null,
                                           Arg.Any<bool>())
                                     .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}
