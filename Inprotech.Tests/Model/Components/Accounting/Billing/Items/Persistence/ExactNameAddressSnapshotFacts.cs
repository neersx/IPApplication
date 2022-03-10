using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class ExactNameAddressSnapshotFacts : FactBase
    {
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

        ExactNameAddressSnapshot CreateSubject(int? lastInternalCode = 45)
        {
            _lastInternalCodeGenerator.GenerateLastInternalCode("NAMEADDRESSSNAP")
                                      .Returns(lastInternalCode ?? Fixture.Integer());

            return new ExactNameAddressSnapshot(Db, _lastInternalCodeGenerator);
        }

        [Fact]
        public async Task ShouldReturnExactMatchingNameAddressSnapshot()
        {
            var debtorId = Fixture.Integer();
            var snapshotId = Fixture.Integer();
            var formattedName = Fixture.String();
            var formattedAddress = Fixture.String();
            var formattedAttention = Fixture.String();
            var formattedReference = Fixture.String();
            var addressCode = Fixture.Integer();
            var attentionNameId = Fixture.Integer();
            var reasonCode = Fixture.Integer();

            new NameAddressSnapshot
            {
                NameId = debtorId,
                NameSnapshotId = snapshotId,
                FormattedName = formattedName,
                FormattedAddress = formattedAddress,
                FormattedAttention = formattedAttention,
                FormattedReference = formattedReference,
                AddressCode = addressCode,
                AttentionNameId = attentionNameId,
                ReasonCode = reasonCode
            }.In(Db);

            var subject = CreateSubject();
            var r = await subject.Derive(new NameAddressSnapshotParameter
            {
                AccountDebtorId = debtorId,
                FormattedName = formattedName,
                FormattedAddress = formattedAddress,
                FormattedAttention = formattedAttention,
                FormattedReference = formattedReference,
                AddressId = addressCode,
                AttentionNameId = attentionNameId,
                AddressChangeReasonId = reasonCode
            });

            Assert.Equal(snapshotId, r);

            _lastInternalCodeGenerator.DidNotReceive().GenerateLastInternalCode(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldReturnUpdatedMatchingNameAddressSnapshotIfReferencedOnlyOnce()
        {
            var debtorId = Fixture.Integer();
            var snapshotId = Fixture.Integer();
            var formattedName = Fixture.String();
            var formattedAddress = Fixture.String();
            var formattedAttention = Fixture.String();
            var formattedReference = Fixture.String();
            var addressCode = Fixture.Integer();
            var attentionNameId = Fixture.Integer();
            var reasonCode = Fixture.Integer();

            var snapshot = new NameAddressSnapshot
            {
                NameId = Fixture.Integer(),
                NameSnapshotId = snapshotId,
                FormattedName = Fixture.String(),
                FormattedAddress = Fixture.String(),
                FormattedAttention = Fixture.String(),
                FormattedReference = Fixture.String(),
                AddressCode = Fixture.Integer(),
                AttentionNameId = Fixture.Integer(),
                ReasonCode = Fixture.Integer()
            }.In(Db);

            new OpenItem
            {
                NameSnapshotId = snapshotId
            }.In(Db);

            var parameter = new NameAddressSnapshotParameter
            {
                AccountDebtorId = debtorId,
                SnapshotId = snapshotId,
                FormattedName = formattedName,
                FormattedAddress = formattedAddress,
                FormattedAttention = formattedAttention,
                FormattedReference = formattedReference,
                AddressId = addressCode,
                AttentionNameId = attentionNameId,
                AddressChangeReasonId = reasonCode
            };

            var subject = CreateSubject();
            var r = await subject.Derive(parameter);

            Assert.Equal(snapshotId, r);
            Assert.Equal(debtorId, snapshot.NameId);
            Assert.Equal(formattedName, snapshot.FormattedName);
            Assert.Equal(formattedAddress, snapshot.FormattedAddress);
            Assert.Equal(formattedAttention, snapshot.FormattedAttention);
            Assert.Equal(formattedReference, snapshot.FormattedReference);
            Assert.Equal(addressCode, snapshot.AddressCode);
            Assert.Equal(attentionNameId, snapshot.AttentionNameId);
            Assert.Equal(reasonCode, snapshot.ReasonCode);

            _lastInternalCodeGenerator.DidNotReceive().GenerateLastInternalCode(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldCreateSnapshotIfExistingSnapshotIsReferencedMoreThanOnce()
        {
            var debtorId = Fixture.Integer();
            var snapshotId = Fixture.Integer();
            var newSnapshotId = Fixture.Integer();
            var formattedName = Fixture.String();
            var formattedAddress = Fixture.String();
            var formattedAttention = Fixture.String();
            var formattedReference = Fixture.String();
            var addressCode = Fixture.Integer();
            var attentionNameId = Fixture.Integer();
            var reasonCode = Fixture.Integer();

            new NameAddressSnapshot
            {
                NameId = Fixture.Integer(),
                NameSnapshotId = snapshotId,
                FormattedName = Fixture.String(),
                FormattedAddress = Fixture.String(),
                FormattedAttention = Fixture.String(),
                FormattedReference = Fixture.String(),
                AddressCode = Fixture.Integer(),
                AttentionNameId = Fixture.Integer(),
                ReasonCode = Fixture.Integer()
            }.In(Db);

            new OpenItem
            {
                NameSnapshotId = snapshotId
            }.In(Db);

            new OpenItem
            {
                NameSnapshotId = snapshotId
            }.In(Db);

            var parameter = new NameAddressSnapshotParameter
            {
                AccountDebtorId = debtorId,
                SnapshotId = snapshotId,
                FormattedName = formattedName,
                FormattedAddress = formattedAddress,
                FormattedAttention = formattedAttention,
                FormattedReference = formattedReference,
                AddressId = addressCode,
                AttentionNameId = attentionNameId,
                AddressChangeReasonId = reasonCode
            };

            var subject = CreateSubject(newSnapshotId); // configure return with new SnapshotId
            var r = await subject.Derive(parameter);

            Assert.Equal(newSnapshotId, r);

            var snapshot = Db.Set<NameAddressSnapshot>().Single(_ => _.NameSnapshotId == r);

            Assert.Equal(debtorId, snapshot.NameId);
            Assert.Equal(formattedName, snapshot.FormattedName);
            Assert.Equal(formattedAddress, snapshot.FormattedAddress);
            Assert.Equal(formattedAttention, snapshot.FormattedAttention);
            Assert.Equal(formattedReference, snapshot.FormattedReference);
            Assert.Equal(addressCode, snapshot.AddressCode);
            Assert.Equal(attentionNameId, snapshot.AttentionNameId);
            Assert.Equal(reasonCode, snapshot.ReasonCode);

            _lastInternalCodeGenerator.Received().GenerateLastInternalCode(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldCreateSnapshotIfNonExactMatchFound()
        {
            var debtorId = Fixture.Integer();
            var snapshotId = Fixture.Integer();
            var newSnapshotId = Fixture.Integer();
            var formattedName = Fixture.String();
            var formattedAddress = Fixture.String();
            var formattedAttention = Fixture.String();
            var formattedReference = Fixture.String();
            var addressCode = Fixture.Integer();
            var attentionNameId = Fixture.Integer();
            var reasonCode = Fixture.Integer();

            var parameter = new NameAddressSnapshotParameter
            {
                AccountDebtorId = debtorId,
                SnapshotId = snapshotId,
                FormattedName = formattedName,
                FormattedAddress = formattedAddress,
                FormattedAttention = formattedAttention,
                FormattedReference = formattedReference,
                AddressId = addressCode,
                AttentionNameId = attentionNameId,
                AddressChangeReasonId = reasonCode
            };

            var subject = CreateSubject(newSnapshotId); // configure return with new SnapshotId
            var r = await subject.Derive(parameter);

            Assert.Equal(newSnapshotId, r);

            var snapshot = Db.Set<NameAddressSnapshot>().Single(_ => _.NameSnapshotId == r);

            Assert.Equal(debtorId, snapshot.NameId);
            Assert.Equal(formattedName, snapshot.FormattedName);
            Assert.Equal(formattedAddress, snapshot.FormattedAddress);
            Assert.Equal(formattedAttention, snapshot.FormattedAttention);
            Assert.Equal(formattedReference, snapshot.FormattedReference);
            Assert.Equal(addressCode, snapshot.AddressCode);
            Assert.Equal(attentionNameId, snapshot.AttentionNameId);
            Assert.Equal(reasonCode, snapshot.ReasonCode);

            _lastInternalCodeGenerator.Received().GenerateLastInternalCode(Arg.Any<string>());
        }
    }
}
