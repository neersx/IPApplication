using InprotechKaizen.Model.Accounting.Creditor;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    public class CreditorBuilder : IBuilder<Creditor>
    {
        public int? NameId { get; set; }

        public int? SupplierType { get; set; }

        public string DefaultTaxCode { get; set; }

        public int? TaxTreatment { get; set; }

        public string PurchaseCurrency { get; set; }

        public int? PaymentTermNo { get; set; }

        public string ChequePayee { get; set; }

        public string Instructions { get; set; }

        public int? ExpenseAccount { get; set; }

        public string ProfitCentre { get; set; }

        public int? PaymentMethod { get; set; }

        public string BankName { get; set; }

        public string BankBranchNo { get; set; }

        public string BankAccountNo { get; set; }

        public string BankAccountName { get; set; }

        public int? BankAccountOwner { get; set; }

        public int? BankNameNo { get; set; }

        public int? BankSequenceNo { get; set; }

        public int? RestrictionId { get; set; }

        public string RestrictionReasonCode { get; set; }

        public string PurchaseDescription { get; set; }

        public string DisbursementWipCode { get; set; }

        public string BeiBankCode { get; set; }

        public string BeiCountryCode { get; set; }

        public string BeiLocationCode { get; set; }

        public string BeiBranchCode { get; set; }

        public int? InstructionsTId { get; set; }

        public int? ExchangeScheduleId { get; set; }

        public Creditor Build()
        {
            return new Creditor
            {
                NameId = NameId ?? Fixture.Integer(),
                SupplierType = SupplierType ?? Fixture.Integer(),
                DefaultTaxCode = DefaultTaxCode ?? Fixture.String(),
                TaxTreatment = TaxTreatment ?? Fixture.Integer(),
                PurchaseCurrency = PurchaseCurrency ?? Fixture.String(),
                PaymentTermNo = PaymentTermNo ?? Fixture.Integer(),
                ChequePayee = ChequePayee ?? Fixture.String(),
                Instructions = Instructions ?? Fixture.String(),
                ExpenseAccount = ExpenseAccount ?? Fixture.Integer(),
                ProfitCentre = ProfitCentre ?? Fixture.String(),
                PaymentMethod = PaymentMethod ?? Fixture.Integer(),
                BankName = BankName ?? Fixture.String(),
                BankBranchNo = BankBranchNo ?? Fixture.String(),
                BankAccountNo = BankAccountNo ?? Fixture.String(),
                BankAccountName = BankAccountName ?? Fixture.String(),
                BankAccountOwner = BankAccountOwner ?? Fixture.Integer(),
                BankNameNo = BankNameNo ?? Fixture.Integer(),
                BankSequenceNo = BankSequenceNo ?? Fixture.Short(),
                RestrictionId = RestrictionId ?? Fixture.Integer(),
                RestrictionReasonCode = RestrictionReasonCode ?? Fixture.String(),
                PurchaseDescription = PurchaseDescription ?? Fixture.String(),
                DisbursementWipCode = DisbursementWipCode ?? Fixture.String(),
                BeiBankCode = BeiBankCode ?? Fixture.String(),
                BeiCountryCode = BeiCountryCode ?? Fixture.String(),
                BeiLocationCode = BeiLocationCode ?? Fixture.String(),
                BeiBranchCode = BeiBranchCode ?? Fixture.String(),
                InstructionsTId = InstructionsTId ?? Fixture.Integer(),
                ExchangeScheduleId = ExchangeScheduleId ?? Fixture.Integer()
            };
        }
    }
}