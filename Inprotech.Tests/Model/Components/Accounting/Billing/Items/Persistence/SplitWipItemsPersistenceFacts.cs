using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class SplitWipItemsPersistenceFacts : FactBase
    {
        readonly ISplitWipCommand _splitWipCommand = Substitute.For<ISplitWipCommand>();

        SplitWipItemsPersistence CreateSubject(ApplicationAlert alert = null)
        {
            var logger = Substitute.For<ILogger<SplitWipItemsPersistence>>();
            var applicationAlerts = Substitute.For<IApplicationAlerts>();
            applicationAlerts.TryParse(Arg.Any<string>(), out var alerts)
                             .Returns(x =>
                             {
                                 x[1] = alert == null ? null : new[] { alert };
                                 return alert != null;
                             });

            return new SplitWipItemsPersistence(_splitWipCommand, applicationAlerts, logger);
        }

        [Fact]
        public async Task ShouldSplitWipItemsThenApplyToBillLineWip()
        {
            var splitWipRefKey = Fixture.Integer();
            var uniqueRefId = Fixture.Integer();
            var newTransactionId = Fixture.Integer();
            var newWipSequenceNo = Fixture.Short();

            var availableWip = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                StaffId = Fixture.Integer(),
                StaffProfitCentre = Fixture.String(),
                ReasonCode = Fixture.String(),
                LocalBilled = Fixture.Decimal(),
                ForeignBilled = Fixture.Decimal(),
                SplitWipRefKey = splitWipRefKey,
                UniqueReferenceId = uniqueRefId,
                IsDraft = true
            };

            var billLineWip = new BillLine
            {
                WipItems = new[]
                {
                    new BillLineWip
                    {
                        SplitWipRefId = splitWipRefKey,
                        UniqueReferenceId = uniqueRefId
                    }
                }
            };

            _splitWipCommand.Split(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<SplitWipItem>())
                            .Returns(new WipAdjustOrSplitResult
                            {
                                NewTransKey = newTransactionId,
                                NewWipSeqKey = newWipSequenceNo
                            });

            var result = new SaveOpenItemResult(Guid.NewGuid());
            var subject = CreateSubject();

            var r = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          AvailableWipItems = new[] { availableWip },
                                          BillLines = new[] { billLineWip }
                                      },
                                      result);

            Assert.True(r);
            Assert.Equal(newTransactionId, result.SplitWipItems.Single().TransactionId);
            Assert.Equal(newWipSequenceNo, result.SplitWipItems.Single().WipSeqNo);
            Assert.Equal(newTransactionId, billLineWip.WipItems.Single().TransactionId);
            Assert.Equal(newWipSequenceNo, billLineWip.WipItems.Single().WipSeqNo);

            _splitWipCommand.Split(4, "en", Arg.Is<SplitWipItem>(_ =>
                                                                     _.EntityKey == availableWip.EntityId &&
                                                                     _.TransKey == availableWip.TransactionId &&
                                                                     _.WipSeqKey == availableWip.WipSeqNo &&
                                                                     _.StaffKey == availableWip.StaffId &&
                                                                     _.ProfitCentreKey == availableWip.StaffProfitCentre &&
                                                                     _.ReasonCode == availableWip.SplitWipReasonCode &&
                                                                     _.LocalAmount == availableWip.LocalBilled &&
                                                                     _.ForeignAmount == availableWip.ForeignBilled
                                                                ))
                            .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnApplicationAlertsIfFound()
        {
            var splitWipRefKey = Fixture.Integer();
            var uniqueRefId = Fixture.Integer();

            var availableWip = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                StaffId = Fixture.Integer(),
                StaffProfitCentre = Fixture.String(),
                ReasonCode = Fixture.String(),
                LocalBilled = Fixture.Decimal(),
                ForeignBilled = Fixture.Decimal(),
                SplitWipRefKey = splitWipRefKey,
                UniqueReferenceId = uniqueRefId,
                IsDraft = true
            };

            var billLineWip = new BillLine
            {
                WipItems = new[]
                {
                    new BillLineWip
                    {
                        SplitWipRefId = splitWipRefKey,
                        UniqueReferenceId = uniqueRefId
                    }
                }
            };

            _splitWipCommand.When(s => s.Split(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<SplitWipItem>()))
                            .Do(_ => throw new SqlExceptionBuilder()
                                           .WithApplicationAlert("AC29", Fixture.String())
                                           .Build());

            var result = new SaveOpenItemResult(Guid.NewGuid());
            var subject = CreateSubject(new ApplicationAlert { AlertID = "AC29" });

            var r = await subject.Run(4, "en",
                                      new BillingSiteSettings(),
                                      new OpenItemModel
                                      {
                                          AvailableWipItems = new[] { availableWip },
                                          BillLines = new[] { billLineWip }
                                      },
                                      result);

            Assert.False(r);
            Assert.Equal("AC29", result.ErrorCode);
        }
    }
}
