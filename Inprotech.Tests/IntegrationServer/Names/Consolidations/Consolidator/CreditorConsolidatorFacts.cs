using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class CreditorConsolidatorFacts : FactBase
    {
        public CreditorConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldConsolidateCreditor()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var fromCreditor = new CreditorBuilder {NameId = _from.Id}.Build().In(Db);

            var subject = new CreditorConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<Creditor>().Where(_ => _.NameId == _to.Id));
            // Removal of creditor happens in later consolidator
            Assert.Single(Db.Set<Creditor>().Where(_ => _.NameId == _from.Id));

            Assert.Equal(fromCreditor.SupplierType, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).SupplierType);
            Assert.Equal(fromCreditor.DefaultTaxCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).DefaultTaxCode);
            Assert.Equal(fromCreditor.TaxTreatment, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).TaxTreatment);
            Assert.Equal(fromCreditor.PurchaseCurrency, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).PurchaseCurrency);
            Assert.Equal(fromCreditor.PaymentTermNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).PaymentTermNo);
            Assert.Equal(fromCreditor.ChequePayee, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).ChequePayee);
            Assert.Equal(fromCreditor.Instructions, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).Instructions);
            Assert.Equal(fromCreditor.ExpenseAccount, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).ExpenseAccount);
            Assert.Equal(fromCreditor.ProfitCentre, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).ProfitCentre);
            Assert.Equal(fromCreditor.PaymentMethod, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).PaymentMethod);
            Assert.Equal(fromCreditor.BankName, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankName);
            Assert.Equal(fromCreditor.BankBranchNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankBranchNo);
            Assert.Equal(fromCreditor.BankAccountNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankAccountNo);
            Assert.Equal(fromCreditor.BankAccountName, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankAccountName);
            Assert.Equal(fromCreditor.BankAccountOwner, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankAccountOwner);
            Assert.Equal(fromCreditor.BankNameNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankNameNo);
            Assert.Equal(fromCreditor.BankSequenceNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankSequenceNo);
            Assert.Equal(fromCreditor.RestrictionId, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).RestrictionId);
            Assert.Equal(fromCreditor.RestrictionReasonCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).RestrictionReasonCode);
            Assert.Equal(fromCreditor.PurchaseDescription, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).PurchaseDescription);
            Assert.Equal(fromCreditor.DisbursementWipCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).DisbursementWipCode);
            Assert.Equal(fromCreditor.BeiBankCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BeiBankCode);
            Assert.Equal(fromCreditor.BeiCountryCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BeiCountryCode);
            Assert.Equal(fromCreditor.BeiLocationCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BeiLocationCode);
            Assert.Equal(fromCreditor.BeiBranchCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BeiBranchCode);
            Assert.Equal(fromCreditor.InstructionsTId, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).InstructionsTId);
            Assert.Equal(fromCreditor.ExchangeScheduleId, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).ExchangeScheduleId);
            Assert.True(_to.SupplierFlag == 1);
        }

        [Fact]
        public async Task ShouldNotConsolidateIfNameIsAlreadyACreditor()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var fromCreditor = new CreditorBuilder {NameId = _from.Id}.Build().In(Db);
            new CreditorBuilder {NameId = _to.Id}.Build().In(Db);

            var subject = new CreditorConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<Creditor>().Where(_ => _.NameId == _to.Id));
            // Removal of creditor happens in later consolidator
            Assert.Single(Db.Set<Creditor>().Where(_ => _.NameId == _from.Id));

            Assert.NotEqual(fromCreditor.SupplierType, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).SupplierType);
            Assert.NotEqual(fromCreditor.DefaultTaxCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).DefaultTaxCode);
            Assert.NotEqual(fromCreditor.TaxTreatment, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).TaxTreatment);
            Assert.NotEqual(fromCreditor.PurchaseCurrency, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).PurchaseCurrency);
            Assert.NotEqual(fromCreditor.PaymentTermNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).PaymentTermNo);
            Assert.NotEqual(fromCreditor.ChequePayee, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).ChequePayee);
            Assert.NotEqual(fromCreditor.Instructions, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).Instructions);
            Assert.NotEqual(fromCreditor.ExpenseAccount, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).ExpenseAccount);
            Assert.NotEqual(fromCreditor.ProfitCentre, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).ProfitCentre);
            Assert.NotEqual(fromCreditor.PaymentMethod, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).PaymentMethod);
            Assert.NotEqual(fromCreditor.BankName, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankName);
            Assert.NotEqual(fromCreditor.BankBranchNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankBranchNo);
            Assert.NotEqual(fromCreditor.BankAccountNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankAccountNo);
            Assert.NotEqual(fromCreditor.BankAccountName, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankAccountName);
            Assert.NotEqual(fromCreditor.BankAccountOwner, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankAccountOwner);
            Assert.NotEqual(fromCreditor.BankNameNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankNameNo);
            Assert.NotEqual(fromCreditor.BankSequenceNo, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BankSequenceNo);
            Assert.NotEqual(fromCreditor.RestrictionId, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).RestrictionId);
            Assert.NotEqual(fromCreditor.RestrictionReasonCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).RestrictionReasonCode);
            Assert.NotEqual(fromCreditor.PurchaseDescription, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).PurchaseDescription);
            Assert.NotEqual(fromCreditor.DisbursementWipCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).DisbursementWipCode);
            Assert.NotEqual(fromCreditor.BeiBankCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BeiBankCode);
            Assert.NotEqual(fromCreditor.BeiCountryCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BeiCountryCode);
            Assert.NotEqual(fromCreditor.BeiLocationCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BeiLocationCode);
            Assert.NotEqual(fromCreditor.BeiBranchCode, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).BeiBranchCode);
            Assert.NotEqual(fromCreditor.InstructionsTId, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).InstructionsTId);
            Assert.NotEqual(fromCreditor.ExchangeScheduleId, Db.Set<Creditor>().Single(_ => _.NameId == _to.Id).ExchangeScheduleId);
        }

        [Fact]
        public async Task ShouldConsolidateCreditorEntityParent()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), false);

            var entityId = Fixture.Integer();

            new CreditorBuilder {NameId = _from.Id}.Build().In(Db);
            new CreditorEntityDetail {NameId = _from.Id, EntityNameNo = entityId}.In(Db);

            var subject = new CreditorConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<CreditorEntityDetail>().Where(_ => _.NameId == _to.Id && _.EntityNameNo == entityId));
            Assert.Empty(Db.Set<CreditorEntityDetail>().Where(_ => _.NameId == _from.Id));
        }
    }
}