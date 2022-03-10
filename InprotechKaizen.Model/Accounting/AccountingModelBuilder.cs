using System;
using System.Data.Entity;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Budget;
using InprotechKaizen.Model.Accounting.Cash;
using InprotechKaizen.Model.Accounting.Cost;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Payment;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Accounting.Trust;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Accounting
{
    public class AccountingModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if (modelBuilder == null) throw new ArgumentNullException(nameof(modelBuilder));
            modelBuilder.Entity<Period>();
            modelBuilder.Entity<SpecialName>();
            modelBuilder.Entity<ChargeRates>().HasKey(_ => new {_.ChargeTypeNo, _.RateNo, _.SequenceNo});
            modelBuilder.Entity<ChargeType>();

            modelBuilder.Entity<BatchTypeRule>();
            modelBuilder.Entity<ChequeRegister>();
            modelBuilder.Entity<Diary>()
                        .Property(p => p.ExchRate)
                        .HasPrecision(11, 4);

            modelBuilder.Entity<Diary>()
                        .HasMany(c => c.DebtorSplits)
                        .WithRequired(d => d.Diary);

            modelBuilder.Entity<DebtorSplitDiary>()
                        .HasIndex(_ => _.Id);

            modelBuilder.Entity<Margin>();
            modelBuilder.Entity<Discount>();
            modelBuilder.Entity<TransactionHeader>();
            modelBuilder.Entity<ExpenseImport>();
            modelBuilder.Entity<FeeList>();
            modelBuilder.Entity<Narrative>();
            modelBuilder.Entity<NarrativeRule>();
            modelBuilder.Entity<NarrativeSubstitute>();
            modelBuilder.Entity<Quotation>();
            modelBuilder.Entity<SpecialName>();
            modelBuilder.Entity<Rates>();
            modelBuilder.Entity<TaxRate>();
            modelBuilder.Entity<TaxRatesCountry>();
            modelBuilder.Entity<DebtorItemType>();

            RegisterAccount(modelBuilder);
            RegisterBanking(modelBuilder);
            RegisterBilling(modelBuilder);
            RegisterBudget(modelBuilder);
            RegisterCash(modelBuilder);
            RegisterAccount(modelBuilder);
            RegisterCost(modelBuilder);
            RegisterCreditor(modelBuilder);
            RegisterDebtor(modelBuilder);
            RegisterOpenItem(modelBuilder);
            RegisterPayment(modelBuilder);
            RegisterTax(modelBuilder);
            RegisterTrust(modelBuilder);
            RegisterWork(modelBuilder);
        }

        void RegisterAccount(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Account.Account>();
            modelBuilder.Entity<TransAdjustment>();
            modelBuilder.Entity<GlAccountMapping>();
        }

        void RegisterBanking(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<BankAccount>();
            modelBuilder.Entity<BankHistory>();
            modelBuilder.Entity<BankStatement>();
            modelBuilder.Entity<StatementTran>();
            modelBuilder.Entity<ElectronicFundsTransferDetail>();
        }

        void RegisterBilling(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<BilledCredit>();
            modelBuilder.Entity<BilledItem>();
            modelBuilder.Entity<BillFormat>();
            modelBuilder.Entity<BillRule>();
            modelBuilder.Entity<BillLine>();
        }

        void RegisterBudget(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Budget.Budget>();
            modelBuilder.Entity<CaseBudget>();
        }

        void RegisterCash(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<CashHistory>();
            modelBuilder.Entity<CashItem>();
        }

        void RegisterCost(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<CostRate>();
            modelBuilder.Entity<CostTrack>();
            modelBuilder.Entity<CostTrackAlloc>();
            modelBuilder.Entity<CostTrackLine>();
            modelBuilder.Entity<TimeCosting>();
        }

        void RegisterCreditor(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Creditor.Creditor>();
            modelBuilder.Entity<CreditorHistory>();
            modelBuilder.Entity<CreditorItem>();
            modelBuilder.Entity<CreditorEntityDetail>();
        }

        void RegisterDebtor(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DebitNoteImage>();
            modelBuilder.Entity<DebtorHistory>();
            modelBuilder.Entity<DebtorHistoryCase>();
        }

        void RegisterOpenItem(DbModelBuilder modelBuilder)
        {
            var openItem = modelBuilder.Entity<OpenItem.OpenItem>();
            openItem.Map(m => m.ToTable("OPENITEM")).HasKey(oi => oi.Id);
            modelBuilder.Entity<OpenItemBreakdown>();
            modelBuilder.Entity<OpenItemCase>();
            modelBuilder.Entity<OpenItemTax>();
            modelBuilder.Entity<OpenItemXml>();
            modelBuilder.Entity<OpenItemCopyTo>();
        }

        void RegisterPayment(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<PaymentPlan>();
            modelBuilder.Entity<PaymentPlanDetail>();
        }

        void RegisterTax(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<TaxPaidHistory>();
            modelBuilder.Entity<TaxPaIdItem>();
            modelBuilder.Entity<TaxHistory>();
            modelBuilder.Entity<VatReturn>();
        }

        void RegisterTrust(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<TrustAccount>();
            modelBuilder.Entity<TrustHistory>();
            modelBuilder.Entity<TrustItem>();
        }

        void RegisterWork(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<WipPayment>();
            modelBuilder.Entity<WorkHistory>();
            modelBuilder.Entity<WorkInProgress>();
            modelBuilder.Entity<WipTemplate>();
            modelBuilder.Entity<NarrativeTranslation>();
        }
    }
}