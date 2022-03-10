using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OpenItemCopyToPersistenceFacts : FactBase
    {
        readonly IExactNameAddressSnapshot _exactNameAddressSnapshot = Substitute.For<IExactNameAddressSnapshot>();

        OpenItemCopyToPersistence CreateSubject(int? snapshotId = null)
        {
            var logger = Substitute.For<ILogger<OpenItemCopyToPersistence>>();

            _exactNameAddressSnapshot.Derive(Arg.Any<NameAddressSnapshotParameter>())
                                     .Returns(snapshotId ?? Fixture.Integer());

            return new OpenItemCopyToPersistence(Db, _exactNameAddressSnapshot, logger);
        }

        [Fact]
        public async Task ShouldSaveOpenItemCopiesToWithNameAddressSnapshot()
        {
            var requestId = Guid.NewGuid();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();

            var copyTo = new DebtorCopiesTo
            {
                CopyToNameId = Fixture.Integer(),
                ContactNameId = Fixture.Integer(),
                AddressId = Fixture.Integer(),
                AddressChangeReasonId = Fixture.Integer(),
                CopyToName = Fixture.String(),
                ContactName = Fixture.String(),
                Address = Fixture.String()
            };

            var debtor = new DebtorData
            {
                NameId = Fixture.Integer(),
                HasCopyToDataChanged = true,
                CopiesTos = new[] { copyTo }
            };

            var snapshotId = Fixture.Integer();

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                Debtors = new[] { debtor }
            };

            var subject = CreateSubject(snapshotId);

            await subject.Run(5, "cn", new BillingSiteSettings(), model, new SaveOpenItemResult(requestId));

            _exactNameAddressSnapshot
                .Received(1)
                .Derive(Arg.Is<NameAddressSnapshotParameter>(
                                                             _ => _.AccountDebtorId == copyTo.CopyToNameId &&
                                                                  _.AttentionNameId == copyTo.ContactNameId &&
                                                                  _.AddressId == copyTo.AddressId &&
                                                                  _.AddressChangeReasonId == copyTo.AddressChangeReasonId &&
                                                                  _.FormattedName == copyTo.CopyToName &&
                                                                  _.FormattedAttention == copyTo.ContactName &&
                                                                  _.FormattedAddress == copyTo.Address
                                                            )).IgnoreAwaitForNSubstituteAssertion();

            var savedOpenItemCopyTo = Db.Set<OpenItemCopyTo>().Single();

            Assert.Equal(itemEntityId, savedOpenItemCopyTo.ItemEntityId);
            Assert.Equal(itemTransactionId, savedOpenItemCopyTo.ItemTransactionId);
            Assert.Equal(accountEntityId, savedOpenItemCopyTo.AccountEntityId);
            Assert.Equal(debtor.NameId, savedOpenItemCopyTo.AccountDebtorId);
            Assert.Equal(snapshotId, savedOpenItemCopyTo.NameSnapshotId);
        }

        [Fact]
        public async Task ShouldNotSaveOpenItemCopiesIfDataHasntChanged()
        {
            var requestId = Guid.NewGuid();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();

            var copyTo = new DebtorCopiesTo
            {
                CopyToNameId = Fixture.Integer(),
                ContactNameId = Fixture.Integer(),
                AddressId = Fixture.Integer(),
                AddressChangeReasonId = Fixture.Integer(),
                CopyToName = Fixture.String(),
                ContactName = Fixture.String(),
                Address = Fixture.String()
            };

            var debtor = new DebtorData
            {
                NameId = Fixture.Integer(),
                HasCopyToDataChanged = false,
                CopiesTos = new[] { copyTo }
            };

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                Debtors = new[] { debtor }
            };

            var subject = CreateSubject();

            await subject.Run(5, "cn", new BillingSiteSettings(), model, new SaveOpenItemResult(requestId));

            _exactNameAddressSnapshot
                .DidNotReceiveWithAnyArgs()
                .Derive(null).IgnoreAwaitForNSubstituteAssertion();

            Assert.Empty(Db.Set<OpenItemCopyTo>());
        }

        [Fact]
        public async Task ShouldNotSaveOpenItemCopiesToMarkedForDelete()
        {
            var requestId = Guid.NewGuid();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();

            var copyTo = new DebtorCopiesTo
            {
                CopyToNameId = Fixture.Integer(),
                ContactNameId = Fixture.Integer(),
                AddressId = Fixture.Integer(),
                AddressChangeReasonId = Fixture.Integer(),
                CopyToName = Fixture.String(),
                ContactName = Fixture.String(),
                Address = Fixture.String(),

                IsDeletedCopyToName = true
            };

            var debtor = new DebtorData
            {
                NameId = Fixture.Integer(),
                HasCopyToDataChanged = true,
                CopiesTos = new[] { copyTo }
            };

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                Debtors = new[] { debtor }
            };

            var subject = CreateSubject();

            await subject.Run(5, "cn", new BillingSiteSettings(), model, new SaveOpenItemResult(requestId));

            _exactNameAddressSnapshot
                .DidNotReceiveWithAnyArgs()
                .Derive(null).IgnoreAwaitForNSubstituteAssertion();

            Assert.Empty(Db.Set<OpenItemCopyTo>());
        }

        [Fact]
        public async Task ShouldNotDeleteNameAddressSnapshotsStillReferenced()
        {
            var requestId = Guid.NewGuid();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var copyToNameId = Fixture.Integer();
            var snapshotId = Fixture.Integer();
            var debtorId = Fixture.Integer();

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                Debtors = new[]
                {
                    new DebtorData
                    {
                        NameId = debtorId,
                        HasCopyToDataChanged = true,
                        CopiesTos = new[] { new DebtorCopiesTo { CopyToNameId = copyToNameId } }
                    }
                }
            };

            var olderSnapshot = new NameAddressSnapshot
            {
                NameId = copyToNameId
            }.In(Db);

            new OpenItemCopyTo
            {
                NameSnapshotId = olderSnapshot.NameSnapshotId
            }.In(Db);

            new OpenItem
            {
                NameSnapshotId = olderSnapshot.NameSnapshotId
            }.In(Db);

            var subject = CreateSubject(snapshotId);

            await subject.Run(5, "cn", new BillingSiteSettings(), model, new SaveOpenItemResult(requestId));

            // contains older snapshot and the new snapshot
            Assert.Equal(2, Db.Set<OpenItemCopyTo>().Count());
        }

        [Fact]
        public async Task ShouldDeleteUnreferencedNameAddressSnapshots()
        {
            var requestId = Guid.NewGuid();
            var itemEntityId = Fixture.Integer();
            var itemTransactionId = Fixture.Integer();
            var accountEntityId = Fixture.Integer();
            var copyToNameId = Fixture.Integer();
            var snapshotId = Fixture.Integer();
            var debtorId = Fixture.Integer();

            var model = new OpenItemModel
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                Debtors = new[]
                {
                    new DebtorData
                    {
                        NameId = debtorId,
                        HasCopyToDataChanged = true,
                        CopiesTos = new[] { new DebtorCopiesTo { CopyToNameId = copyToNameId } }
                    }
                }
            };

            var olderSnapshot = new NameAddressSnapshot
            {
                NameId = copyToNameId
            }.In(Db);

            var subject = CreateSubject(snapshotId);

            await subject.Run(5, "cn", new BillingSiteSettings(), model, new SaveOpenItemResult(requestId));

            Assert.NotEqual(olderSnapshot.NameSnapshotId, Db.Set<OpenItemCopyTo>().Single().NameSnapshotId);
            Assert.Equal(snapshotId, Db.Set<OpenItemCopyTo>().Single().NameSnapshotId);
        }
    }
}
