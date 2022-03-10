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
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{

    public class MergedOpenItemPersistenceFacts : FactBase
    {
        readonly IDraftBillManagementCommands _draftBillManagementCommands = Substitute.For<IDraftBillManagementCommands>();
        readonly IDraftWipManagementCommands _draftWipManagementCommands = Substitute.For<IDraftWipManagementCommands>();

        MergedOpenItemsPersistence CreateSubject()
        {
            var logger = Substitute.For<ILogger<MergedOpenItemsPersistence>>();
            return new MergedOpenItemsPersistence(_draftWipManagementCommands, _draftBillManagementCommands, logger);
        }

        [Fact]
        public async Task ShouldProceedOnlyIfBillIsMerged()
        {
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                MergedItemKeysInXml = null // this must have a value to proceed
            };

            var subject = CreateSubject();

            var r = await subject.Run(4, "en", new BillingSiteSettings(), model, new SaveOpenItemResult(Guid.NewGuid()));

            Assert.True(r);

            _draftWipManagementCommands.DidNotReceiveWithAnyArgs()
                                       .CopyDraftWip(Arg.Any<int>(), null, null, Arg.Any<int>(), Arg.Any<int>())
                                       .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldCopyDraftWipFromMergedOpenItems()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();

            var newWipSeqNo = Fixture.Short();

            var mergeXmlKeys = new MergeXmlKeys();
            mergeXmlKeys.OpenItemXmls.Add(new OpenItemXmlKey
            {
                ItemEntityNo = Fixture.Integer(),
                ItemTransNo = Fixture.Integer()
            });

            var availableWipItem = new AvailableWipItem
            {
                EntityId = Fixture.Integer(),
                TransactionId = Fixture.Integer(),
                WipSeqNo = Fixture.Short(),
                UniqueReferenceId = Fixture.Integer()
            };

            var billLineWipItem = new BillLineWip
            {
                // where the wip is included in the bill line
                DraftWipRefId = availableWipItem.UniqueReferenceId
            };

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                MergedItemKeysInXml = mergeXmlKeys.ToString(),
                AvailableWipItems = new[]
                {
                    availableWipItem
                },
                BillLines = new[]
                {
                    new BillLine
                    {
                        WipItems = new[]
                        {
                            billLineWipItem
                        }
                    }
                }
            };

            _draftWipManagementCommands.CopyDraftWip(userIdentityId, culture, Arg.Any<MergeXmlKeys>(), itemEntityId, itemTransactionId)
                                       .Returns((new[]
                                       {
                                           new RemappedWipItems
                                           {
                                               EntityId = availableWipItem.EntityId,
                                               TransactionId = availableWipItem.TransactionId,
                                               WipSeqNo = availableWipItem.WipSeqNo,
                                               NewWipSeqNo = newWipSeqNo
                                           }
                                       }, Enumerable.Empty<ApplicationAlert>()));

            var result = new SaveOpenItemResult(Guid.NewGuid());
            var subject = CreateSubject();

            var r = await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            Assert.True(r);

            Assert.Equal(newWipSeqNo, availableWipItem.WipSeqNo);
            Assert.Equal(newWipSeqNo, billLineWipItem.WipSeqNo);
            Assert.Equal(availableWipItem.TransactionId, billLineWipItem.TransactionId);
            Assert.Equal(availableWipItem.EntityId, billLineWipItem.EntityId);

            Assert.Equal(newWipSeqNo, result.DraftWipItems.Single().WipSeqNo);
            Assert.Equal(availableWipItem.UniqueReferenceId, result.DraftWipItems.Single().UniqueReferenceId);
        }

        [Fact]
        public async Task ShouldReturnErrorIfCopyDraftWipFromMergedOpenItemsFailed()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var mergeXmlKeys = new MergeXmlKeys();
            mergeXmlKeys.OpenItemXmls.Add(new OpenItemXmlKey
            {
                ItemEntityNo = Fixture.Integer(),
                ItemTransNo = Fixture.Integer()
            });

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                MergedItemKeysInXml = mergeXmlKeys.ToString()
            };

            var alert = new ApplicationAlert
            {
                AlertID = "AC136",
                Message = "Open Item could not be found. Item has been modified or is already finalised."
            };

            _draftWipManagementCommands.CopyDraftWip(userIdentityId, culture, Arg.Any<MergeXmlKeys>(), itemEntityId, itemTransactionId)
                                       .Returns((Enumerable.Empty<RemappedWipItems>(), new[] { alert }));

            var result = new SaveOpenItemResult(Guid.NewGuid());
            var subject = CreateSubject();

            var r = await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            Assert.False(r);

            Assert.Equal("AC136", result.ErrorCode);
            Assert.Equal("Open Item could not be found. Item has been modified or is already finalised.", result.ErrorDescription);

            _draftBillManagementCommands.DidNotReceiveWithAnyArgs()
                                        .Delete(Arg.Any<int>(), null, null)
                                        .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldDeleteOpenItemsWhoseItemsHaveBeenMerged()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var mergeXmlKeys = new MergeXmlKeys();
            mergeXmlKeys.OpenItemXmls.Add(new OpenItemXmlKey
            {
                ItemEntityNo = Fixture.Integer(),
                ItemTransNo = Fixture.Integer()
            });

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                MergedItemKeysInXml = mergeXmlKeys.ToString()
            };

            _draftWipManagementCommands.CopyDraftWip(userIdentityId, culture, Arg.Any<MergeXmlKeys>(), itemEntityId, itemTransactionId)
                                       .Returns((Enumerable.Empty<RemappedWipItems>(), Enumerable.Empty<ApplicationAlert>()));

            var result = new SaveOpenItemResult(Guid.NewGuid());
            var subject = CreateSubject();

            var r = await subject.Run(userIdentityId, culture, new BillingSiteSettings(), model, result);

            Assert.True(r);

            _draftBillManagementCommands.Received(1)
                                        .Delete(userIdentityId, culture,
                                                Arg.Is<MergeXmlKeys>(_ => _.ToString() == mergeXmlKeys.ToString()))
                                        .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}