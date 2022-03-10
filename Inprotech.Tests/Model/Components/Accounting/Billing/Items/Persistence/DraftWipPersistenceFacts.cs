using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class DraftWipPersistenceFacts
    {
        readonly ISaveOpenItemDraftWip _handler = Substitute.For<ISaveOpenItemDraftWip>();
        readonly IIndex<TypeOfDraftWipPersistence, ISaveOpenItemDraftWip> _handlerFactory = Substitute.For<IIndex<TypeOfDraftWipPersistence, ISaveOpenItemDraftWip>>();

        DraftWipDetailPersistence CreateSubject(SaveOpenItemDraftWipResult result = null)
        {
            var logger = Substitute.For<ILogger<DraftWipDetailPersistence>>();
            _handlerFactory[Arg.Any<TypeOfDraftWipPersistence>()].Returns(_handler);

            _handler.Save(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<IEnumerable<DraftWip>>(), Arg.Any<int?>(), Arg.Any<ItemType>(), Arg.Any<Guid>())
                    .Returns(result ?? new SaveOpenItemDraftWipResult());

            return new DraftWipDetailPersistence(_handlerFactory, logger);
        }

        [Theory]
        [InlineData(true, TypeOfDraftWipPersistence.WipSplitMultiDebtor)]
        [InlineData(false, TypeOfDraftWipPersistence.Default)]
        public async Task ShouldGetCorrectHandlerBasedOnWipSplitMultiDebtorSettings(bool wipSplitMultiDebtorSetting, TypeOfDraftWipPersistence typeOfDraftWipPersistenceExpected)
        {
            var settings = new BillingSiteSettings
            {
                WIPSplitMultiDebtor = wipSplitMultiDebtorSetting
            };

            var subject = CreateSubject();

            await subject.Run(3, "cn", settings, new OpenItemModel(), new SaveOpenItemResult(Guid.NewGuid()));

            var _ = _handlerFactory.Received(1)[typeOfDraftWipPersistenceExpected];
        }

        [Fact]
        public async Task ShouldPassDraftWipDataOnlyToHandler()
        {
            var availableWipItemForDraftWipHandler = new AvailableWipItem
            {
                IsDraft = true,
                DraftWipRefId = Fixture.Integer(),
                DraftWipData = new DraftWip()
            };

            var model = new OpenItemModel
            {
                AvailableWipItems = new[]
                {
                    new AvailableWipItem(),
                    availableWipItemForDraftWipHandler,
                    new AvailableWipItem()
                }
            };

            var subject = CreateSubject();

            await subject.Run(3, "cn", new BillingSiteSettings(), model, new SaveOpenItemResult(Guid.NewGuid()));

            _handler.Received(1).Save(3, "cn",
                                      Arg.Is<IEnumerable<DraftWip>>(_ => _.Single() == availableWipItemForDraftWipHandler.DraftWipData), Arg.Any<int?>(), Arg.Any<ItemType>(), Arg.Any<Guid>())
                    .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldApplyPersistedDataFromHandlerToModel()
        {
            var availableWipItemForDraftWipHandler = new AvailableWipItem
            {
                IsDraft = true,
                DraftWipRefId = Fixture.Integer(),
                DraftWipData = new DraftWip()
            };

            var billLineReferencingDraftWipAbove = new BillLineWip
            {
                DraftWipRefId = availableWipItemForDraftWipHandler.DraftWipRefId
            };

            var model = new OpenItemModel
            {
                AvailableWipItems = new[]
                {
                    new AvailableWipItem(),
                    availableWipItemForDraftWipHandler,
                    new AvailableWipItem()
                },

                BillLines = new[]
                {
                    new BillLine(),
                    new BillLine
                    {
                        WipItems = new List<BillLineWip>(new[] { billLineReferencingDraftWipAbove })
                    },
                    new BillLine()
                }
            };

            var seqNo = Fixture.Short();
            var transactionId = Fixture.Integer();

            var handlerResult = new SaveOpenItemDraftWipResult();
            handlerResult.PersistedWipDetails.Add(new DraftWipDetails
            {
                DraftWipRefId = availableWipItemForDraftWipHandler.DraftWipRefId.GetValueOrDefault(),
                TransactionId = transactionId,
                WipSeqNo = seqNo
            });

            var result = new SaveOpenItemResult(Guid.NewGuid());
            var subject = CreateSubject(handlerResult);

            await subject.Run(3, "cn", new BillingSiteSettings(), model, result);

            Assert.Equal(seqNo, availableWipItemForDraftWipHandler.WipSeqNo);
            Assert.Equal(transactionId, availableWipItemForDraftWipHandler.TransactionId);

            Assert.Equal(seqNo, billLineReferencingDraftWipAbove.WipSeqNo);
            Assert.Equal(transactionId, billLineReferencingDraftWipAbove.TransactionId);

            Assert.Contains(handlerResult.PersistedWipDetails.Single(), result.DraftWipItems);
        }

        [Fact]
        public async Task ShouldRelayErrorsFromHandler()
        {
            var subject = CreateSubject(new SaveOpenItemDraftWipResult("AC1", "Some Error"));

            var result = new SaveOpenItemResult(Guid.NewGuid());

            await subject.Run(3, "cn", new BillingSiteSettings(), new OpenItemModel(), result);

            Assert.Equal("AC1", result.ErrorCode);
            Assert.Equal("Some Error", result.ErrorDescription);
        }
    }
}
