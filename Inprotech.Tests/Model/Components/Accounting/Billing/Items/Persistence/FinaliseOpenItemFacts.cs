using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class FinaliseOpenItemFacts
    {
        readonly IDraftBillManagementCommands _draftBillManagementCommands = Substitute.For<IDraftBillManagementCommands>();

        FinaliseOpenItem CreateSubject()
        {
            var logger = Substitute.For<ILogger<FinaliseOpenItem>>();

            return new FinaliseOpenItem(_draftBillManagementCommands, logger);
        }

        [Fact]
        public async Task ShouldFinaliseRequestedOpenItemThenReturnResult()
        {
            var itemTransactionId = Fixture.Integer();
            var itemEntityId = Fixture.Integer();
            var enteredOpenItemXml = Fixture.String();
            var itemDate = Fixture.Today();

            var debitNoteNo1 = new DebtorOpenItemNo(Fixture.Integer());
            var debitNoteNo2 = new DebtorOpenItemNo(Fixture.Integer());

            var reconciliationError = Fixture.String();

            _draftBillManagementCommands.Finalise(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<DateTime>())
                                        .Returns(new FinaliseOpenItemResult(
                                                                            new[]
                                                                            {
                                                                                debitNoteNo1,
                                                                                debitNoteNo2
                                                                            },
                                                                            new[] { reconciliationError }));

            var result = new SaveOpenItemResult(Guid.NewGuid());

            var subject = CreateSubject();

            var r = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new FinaliseRequest
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          ItemDate = itemDate,
                                          EnteredOpenItemXml = enteredOpenItemXml
                                      },
                                      result);

            Assert.True(r);
            Assert.Equal(debitNoteNo1, result.DebtorOpenItemNos.First());
            Assert.Equal(debitNoteNo2, result.DebtorOpenItemNos.Last());
            Assert.Equal(reconciliationError, result.ReconciliationErrors.Single());
            Assert.Null(result.ErrorCode);

            _draftBillManagementCommands
                .Received(1)
                .Finalise(4, "en", itemEntityId, itemTransactionId, Arg.Any<string>(), itemDate)
                .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnLastOpenItemNoToModel()
        {
            var itemTransactionId = Fixture.Integer();
            var itemEntityId = Fixture.Integer();
            var enteredOpenItemXml = Fixture.String();
            var itemDate = Fixture.Today();

            var debitNoteNo1 = new DebtorOpenItemNo(Fixture.Integer()) { OpenItemNo = Fixture.String() };
            var debitNoteNo2 = new DebtorOpenItemNo(Fixture.Integer()) { OpenItemNo = Fixture.String() };

            var reconciliationError = Fixture.String();

            var finaliseRequest = new FinaliseRequest
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                ItemDate = itemDate,
                EnteredOpenItemXml = enteredOpenItemXml
            };

            _draftBillManagementCommands.Finalise(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<DateTime>())
                                        .Returns(new FinaliseOpenItemResult(
                                                                            new[]
                                                                            {
                                                                                debitNoteNo1,
                                                                                debitNoteNo2
                                                                            },
                                                                            new[] { reconciliationError }));

            var result = new SaveOpenItemResult(Guid.NewGuid());

            var subject = CreateSubject();

            var r = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      finaliseRequest,
                                      result);

            Assert.Equal(debitNoteNo2.OpenItemNo, finaliseRequest.OpenItemNo);
        }

        [Fact]
        public async Task ShouldReturnAlertsThenReturnFalse()
        {
            var itemTransactionId = Fixture.Integer();
            var itemEntityId = Fixture.Integer();
            var enteredOpenItemXml = Fixture.String();
            var itemDate = Fixture.Today();

            var alert = new ApplicationAlert
            {
                AlertID = Fixture.String(),
                Message = Fixture.String()
            };

            _draftBillManagementCommands.Finalise(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<DateTime>())
                                        .Returns(new FinaliseOpenItemResult(new[] { alert }));

            var result = new SaveOpenItemResult(Guid.NewGuid());

            var subject = CreateSubject();

            var r = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new FinaliseRequest
                                      {
                                          ItemEntityId = itemEntityId,
                                          ItemTransactionId = itemTransactionId,
                                          ItemDate = itemDate,
                                          EnteredOpenItemXml = enteredOpenItemXml
                                      },
                                      result);

            Assert.False(r);
            Assert.Equal(alert.AlertID, result.ErrorCode);
            Assert.Equal(alert.Message, result.ErrorDescription);
        }
    }
}
