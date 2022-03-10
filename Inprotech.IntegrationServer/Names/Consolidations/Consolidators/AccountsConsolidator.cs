using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Payment;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Accounting.Trust;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class AccountsConsolidator : INameConsolidator
    {
        readonly IBatchedCommand _batchedCommand;
        readonly IDbContext _dbContext;

        public AccountsConsolidator(IDbContext dbContext, IBatchedCommand batchedCommand)
        {
            _dbContext = dbContext;
            _batchedCommand = batchedCommand;
        }

        public string Name => nameof(AccountsConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            var parameters = new Dictionary<string, object>
            {
                {"@to", to.Id},
                {"@from", from.Id}
            };

            await UpdateExistingAccountBalanceFromName(to, from);

            await UpdateExistingAccountBalanceFromEntity(to, from);

            await InsertAccountBalanceFromName(parameters);

            await InsertAccountBalanceFromEntity(parameters);

            await UpdateBilledItemAccountDebtorNumber(to, from);

            await InsertCreditorItem(parameters);

            await InsertCreditorHistory(parameters);

            await InsertTaxPaidHistory(parameters);

            await DeleteTaxPaidHistory(from);

            await DeleteCreditorHistory(from);

            await InsertPaymentPlanDetail(parameters);

            await DeletePaymentPlanDetail(from);

            await InsertTaxPaidItem(parameters);

            await DeleteTaxPaidItem(from);

            await DeleteCreditorItem(from);

            await InsertOpenItem(parameters);

            await UpdateOpenItem(to, from);

            await UpdateBilledCreditDrAccountDebtor(to, from);

            await UpdateBilledCreditCrAccountDebtor(to, from);

            await UpdateOpenItemBreakdown(to, from);

            await UpdateOpenItemCase(to, from);

            await UpdateOpenItemTax(to, from);

            await UpdateWipPayment(to, from);

            await DeleteOpenItem(from);

            await ResetInsertedOpenItemNumbers(to);

            await InsertDebtorHistory(parameters);

            await UpdateDebtorHistoryCase(to, from);

            await UpdateTaxHistory(to, from);

            await DeleteDebtorHistory(from);

            await UpdateTransAdjustment(to, from);

            await InsertTrustAccount(parameters);

            await InsertTrustItem(parameters);

            await UpdateTrustItem(to, from);

            await InsertTrustHistory(parameters);

            await DeleteTrustHistory(from);

            await DeleteTrustItem(from);

            await DeleteTrustAccount(from);

            await DeleteWorkHistory(from);
        }

        async Task InsertCreditorItem(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO CREDITORITEM (	 
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, DOCUMENTREF, ITEMDATE, ITEMDUEDATE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD,
			    ITEMTYPE, CURRENCY, EXCHRATE, LOCALPRETAXVALUE, LOCALVALUE, LOCALTAXAMOUNT, FOREIGNVALUE, FOREIGNTAXAMT, LOCALBALANCE, FOREIGNBALANCE, EXCHVARIANCE, 
                [STATUS], [DESCRIPTION], LONGDESCRIPTION, RESTRICTIONID, RESTNREASONCODE, PROTOCOLNO, PROTOCOLDATE)
		    SELECT	 
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, @to, DOCUMENTREF, ITEMDATE, ITEMDUEDATE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD,
                ITEMTYPE, CURRENCY, EXCHRATE, LOCALPRETAXVALUE, LOCALVALUE, LOCALTAXAMOUNT, FOREIGNVALUE, FOREIGNTAXAMT, LOCALBALANCE, FOREIGNBALANCE, EXCHVARIANCE,
			    [STATUS], [DESCRIPTION], LONGDESCRIPTION, RESTRICTIONID, RESTNREASONCODE, PROTOCOLNO, PROTOCOLDATE
		    FROM CREDITORITEM
		    WHERE ACCTCREDITORNO=@from", parameters);
        }

        async Task InsertCreditorHistory(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO CREDITORHISTORY (
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, HISTORYLINENO, DOCUMENTREF, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, 
                COMMANDID, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, EXCHVARIANCE, FOREIGNTAXAMT, FOREIGNTRANVALUE, REFENTITYNO, REFTRANSNO, LOCALBALANCE, 
                FOREIGNBALANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, [STATUS], ASSOCLINENO, ITEMIMPACT, [DESCRIPTION], LONGDESCRIPTION, GLMOVEMENTNO, GLSTATUS, REMITTANCENAMENO)
		    SELECT   
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, @to, HISTORYLINENO, DOCUMENTREF, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, 
                COMMANDID, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, EXCHVARIANCE, FOREIGNTAXAMT, FOREIGNTRANVALUE, REFENTITYNO, REFTRANSNO, LOCALBALANCE,
			    FOREIGNBALANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, [STATUS], ASSOCLINENO, ITEMIMPACT, [DESCRIPTION], LONGDESCRIPTION, GLMOVEMENTNO, GLSTATUS, REMITTANCENAMENO
		    FROM CREDITORHISTORY
		    where ACCTCREDITORNO=@from", parameters);
        }

        async Task DeleteCreditorHistory(Name from)
        {
            await _dbContext.DeleteAsync(from ch in _dbContext.Set<CreditorHistory>()
                                         where ch.AccountCreditorId == @from.Id
                                         select ch);
        }

        async Task InsertTaxPaidHistory(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO TAXPAIDHISTORY(	 
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, HISTORYLINENO, TAXCODE, COUNTRYCODE,
                TAXRATE, TAXABLEAMOUNT, TAXAMOUNT, REFENTITYNO, REFTRANSNO)
		    SELECT	 
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, @to, HISTORYLINENO, TAXCODE, COUNTRYCODE, 
                TAXRATE, TAXABLEAMOUNT, TAXAMOUNT, REFENTITYNO, REFTRANSNO
		    FROM TAXPAIDHISTORY
		    WHERE ACCTCREDITORNO=@from", parameters);
        }

        async Task DeleteTaxPaidHistory(Name from)
        {
            await _dbContext.DeleteAsync(from t in _dbContext.Set<TaxPaidHistory>()
                                         where t.AccountCreditorId == @from.Id
                                         select t);
        }

        async Task InsertPaymentPlanDetail(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO PAYMENTPLANDETAIL(	 
                PLANID, ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, REFENTITYNO, REFTRANSNO, PAYMENTAMOUNT, FXDEALERREF, ACCOUNTID)
		    SELECT	 
                PLANID, ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, @to, REFENTITYNO, REFTRANSNO, PAYMENTAMOUNT, FXDEALERREF, ACCOUNTID
		    FROM PAYMENTPLANDETAIL
		    WHERE ACCTCREDITORNO=@from", parameters);
        }

        async Task DeletePaymentPlanDetail(Name from)
        {
            await _dbContext.DeleteAsync(from p in _dbContext.Set<PaymentPlanDetail>()
                                         where p.AccountCreditorId == @from.Id
                                         select p);
        }

        async Task InsertTaxPaidItem(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO TAXPAIDITEM(
                    ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTCREDITORNO, TAXCODE, COUNTRYCODE, TAXRATE, TAXABLEAMOUNT, TAXAMOUNT)
		    SELECT	 
                    ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, @to, TAXCODE, COUNTRYCODE, TAXRATE, TAXABLEAMOUNT, TAXAMOUNT
		    FROM TAXPAIDITEM
		    WHERE ACCTCREDITORNO=@from", parameters);
        }

        async Task DeleteTaxPaidItem(Name from)
        {
            await _dbContext.DeleteAsync(from t in _dbContext.Set<TaxPaIdItem>()
                                         where t.AccountCreditorId == @from.Id
                                         select t);
        }

        async Task DeleteCreditorItem(Name from)
        {
            await _dbContext.DeleteAsync(from t in _dbContext.Set<CreditorItem>()
                                         where t.AccountCreditorId == @from.Id
                                         select t);
        }

        async Task InsertOpenItem(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO OPENITEM(	 
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, ACTION, OPENITEMNO, ITEMDATE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, [STATUS],
                ITEMTYPE, BILLPERCENTAGE, EMPLOYEENO, EMPPROFITCENTRE, CURRENCY, EXCHRATE, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, FOREIGNTAXAMT, FOREIGNVALUE, 
                LOCALBALANCE, FOREIGNBALANCE, EXCHVARIANCE, STATEMENTREF, REFERENCETEXT, NAMESNAPNO, BILLFORMATID, BILLPRINTEDFLAG, REGARDING, SCOPE, LANGUAGE, ASSOCOPENITEMNO,
                LONGREGARDING, LONGREFTEXT, IMAGEID, FOREIGNEQUIVCURRCY, FOREIGNEQUIVEXRATE, ITEMDUEDATE, PENALTYINTEREST, LOCALORIGTAKENUP, FOREIGNORIGTAKENUP, 
                REFERENCETEXT_TID, REGARDING_TID, SCOPE_TID, INCLUDEONLYWIP, PAYFORWIP, PAYPROPERTYTYPE, RENEWALDEBTORFLAG, CASEPROFITCENTRE, MAINCASEID)
		    SELECT	 
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, @to, ACTION,'~'+OPENITEMNO,  /* temporarily required to maintain uniqueness */
			    ITEMDATE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, [STATUS], 
                ITEMTYPE, BILLPERCENTAGE, EMPLOYEENO, EMPPROFITCENTRE, CURRENCY, EXCHRATE, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, FOREIGNTAXAMT, FOREIGNVALUE,
                LOCALBALANCE, FOREIGNBALANCE, EXCHVARIANCE, STATEMENTREF, REFERENCETEXT, NAMESNAPNO, BILLFORMATID, BILLPRINTEDFLAG, REGARDING, SCOPE, LANGUAGE, ASSOCOPENITEMNO, 
                LONGREGARDING, LONGREFTEXT, IMAGEID, FOREIGNEQUIVCURRCY, FOREIGNEQUIVEXRATE, ITEMDUEDATE, PENALTYINTEREST, LOCALORIGTAKENUP, FOREIGNORIGTAKENUP, 
                REFERENCETEXT_TID, REGARDING_TID, SCOPE_TID, INCLUDEONLYWIP, PAYFORWIP, PAYPROPERTYTYPE, RENEWALDEBTORFLAG, CASEPROFITCENTRE, MAINCASEID
		    FROM OPENITEM
		    WHERE ACCTDEBTORNO=@from", parameters);
        }

        async Task UpdateOpenItem(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from o in _dbContext.Set<OpenItem>()
                                         where o.StaffId == @from.Id
                                         select o,
                                         _ => new OpenItem
                                         {
                                             StaffId = to.Id
                                         });
        }

        async Task UpdateBilledCreditDrAccountDebtor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from o in _dbContext.Set<BilledCredit>()
                                         where o.DebitAccountDebtorId == @from.Id
                                         select o,
                                         _ => new BilledCredit
                                         {
                                             DebitAccountDebtorId = to.Id
                                         });
        }

        async Task UpdateBilledCreditCrAccountDebtor(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from o in _dbContext.Set<BilledCredit>()
                                         where o.CreditAccountDebtorId == @from.Id
                                         select o,
                                         _ => new BilledCredit
                                         {
                                             CreditAccountDebtorId = to.Id
                                         });
        }

        async Task UpdateOpenItemBreakdown(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from o in _dbContext.Set<OpenItemBreakdown>()
                                         where o.AccountDebtorId == @from.Id
                                         select o,
                                         _ => new OpenItemBreakdown
                                         {
                                             AccountDebtorId = to.Id
                                         });
        }

        async Task UpdateOpenItemCase(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from o in _dbContext.Set<OpenItemCase>()
                                         where o.AccountDebtorId == @from.Id
                                         select o,
                                         _ => new OpenItemCase
                                         {
                                             AccountDebtorId = to.Id
                                         });
        }
        
        async Task UpdateOpenItemTax(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from o in _dbContext.Set<OpenItemTax>()
                                         where o.AccountDebtorId == @from.Id
                                         select o,
                                         _ => new OpenItemTax
                                         {
                                             AccountDebtorId = to.Id
                                         });
        }
        
        async Task UpdateWipPayment(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from o in _dbContext.Set<WipPayment>()
                                         where o.AccountDebtorId == @from.Id
                                         select o,
                                         _ => new WipPayment
                                         {
                                             AccountDebtorId = to.Id
                                         });
        }

        async Task DeleteOpenItem(Name from)
        {
            await _dbContext.DeleteAsync(from o in _dbContext.Set<OpenItem>()
                                         where o.AccountDebtorId == @from.Id
                                         select o);
        }

        async Task ResetInsertedOpenItemNumbers(Name to)
        {
            await _dbContext.UpdateAsync(from o in _dbContext.Set<OpenItem>()
                                         where o.AccountDebtorId == to.Id &&
                                               o.OpenItemNo != null && o.OpenItemNo.StartsWith("~")
                                         select o,
                                         _ => new OpenItem
                                         {
                                             OpenItemNo = _.OpenItemNo.Substring(1)
                                         });
        }

        async Task InsertDebtorHistory(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO DEBTORHISTORY(	 
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO, OPENITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, 
                COMMANDID, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, EXCHVARIANCE, FOREIGNTAXAMT, FOREIGNTRANVALUE, REFERENCETEXT, REASONCODE, REFENTITYNO, 
                REFTRANSNO, REFSEQNO, REFACCTENTITYNO, REFACCTDEBTORNO, LOCALBALANCE, FOREIGNBALANCE, TOTALEXCHVARIANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, 
                [STATUS], ASSOCLINENO, ITEMIMPACT, LONGREFTEXT, GLMOVEMENTNO)
		    SELECT	 
                ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, @to, HISTORYLINENO, OPENITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, 
                COMMANDID, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, EXCHVARIANCE, FOREIGNTAXAMT, FOREIGNTRANVALUE, REFERENCETEXT, REASONCODE, REFENTITYNO,
                REFTRANSNO, REFSEQNO, REFACCTENTITYNO, REFACCTDEBTORNO, LOCALBALANCE, FOREIGNBALANCE, TOTALEXCHVARIANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, 
                [STATUS], ASSOCLINENO, ITEMIMPACT, LONGREFTEXT, GLMOVEMENTNO
		    FROM DEBTORHISTORY
		    WHERE ACCTDEBTORNO=@from", parameters);
        }

        async Task UpdateDebtorHistoryCase(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from d in _dbContext.Set<DebtorHistoryCase>()
                                         where d.AccountDebtorId == @from.Id
                                         select d,
                                         _ => new DebtorHistoryCase
                                         {
                                             AccountDebtorId = to.Id
                                         });
        }

        async Task UpdateTaxHistory(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from d in _dbContext.Set<TaxHistory>()
                                         where d.AccountDebtorId == @from.Id
                                         select d,
                                         _ => new TaxHistory
                                         {
                                             AccountDebtorId = to.Id
                                         });
        }

        async Task DeleteDebtorHistory(Name from)
        {
            await _dbContext.DeleteAsync(from d in _dbContext.Set<DebtorHistory>()
                                         where d.AccountDebtorId == @from.Id
                                         select d);
        }

        async Task UpdateTransAdjustment(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from d in _dbContext.Set<TransAdjustment>()
                                         where d.ToAccountNameId == @from.Id
                                         select d,
                                         _ => new TransAdjustment
                                         {
                                             ToAccountNameId = to.Id
                                         });
        }

        async Task InsertTrustAccount(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO TRUSTACCOUNT(ENTITYNO, NAMENO, BALANCE)
		    SELECT	ENTITYNO, @to, BALANCE
		    FROM    TRUSTACCOUNT
		    WHERE NAMENO=@from", parameters);
        }

        async Task InsertTrustItem(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO TRUSTITEM(	 
                ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, ITEMNO, ITEMDATE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, ITEMTYPE, 
                EMPLOYEENO, CURRENCY, EXCHRATE, LOCALVALUE, FOREIGNVALUE, LOCALBALANCE, FOREIGNBALANCE, EXCHVARIANCE, [STATUS], [DESCRIPTION], LONGDESCRIPTION)
		    SELECT   
                ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, @to, ITEMNO, ITEMDATE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, ITEMTYPE,
                EMPLOYEENO, CURRENCY, EXCHRATE, LOCALVALUE, FOREIGNVALUE, LOCALBALANCE, FOREIGNBALANCE, EXCHVARIANCE, [STATUS], [DESCRIPTION], LONGDESCRIPTION
		    FROM TRUSTITEM
		    WHERE TACCTNAMENO=@from", parameters);
        }

        async Task UpdateTrustItem(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from t in _dbContext.Set<TrustItem>()
                                         where t.StaffId == @from.Id
                                         select t,
                                         _ => new TrustItem {StaffId = to.Id});
        }

        async Task InsertTrustHistory(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO TRUSTHISTORY(	 
                ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, HISTORYLINENO, ITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, 
                COMMANDID, LOCALVALUE, EXCHVARIANCE, FOREIGNTRANVALUE, REFENTITYNO, REFTRANSNO, LOCALBALANCE, FOREIGNBALANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, 
                [STATUS], ASSOCLINENO, ITEMIMPACT, [DESCRIPTION], LONGDESCRIPTION)
		    SELECT   
                ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, @to, HISTORYLINENO, ITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, 
                COMMANDID, LOCALVALUE, EXCHVARIANCE, FOREIGNTRANVALUE, REFENTITYNO, REFTRANSNO, LOCALBALANCE, FOREIGNBALANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE,
                [STATUS], ASSOCLINENO, ITEMIMPACT, [DESCRIPTION], LONGDESCRIPTION
		    FROM TRUSTHISTORY
		    WHERE TACCTNAMENO=@from", parameters);
        }

        async Task DeleteTrustHistory(Name from)
        {
            await _dbContext.DeleteAsync(from t in _dbContext.Set<TrustHistory>()
                                         where t.TrustAccountNameId == @from.Id
                                         select t);
        }

        async Task DeleteTrustItem(Name from)
        {
            await _dbContext.DeleteAsync(from t in _dbContext.Set<TrustItem>()
                                         where t.TrustAccountNameId == @from.Id
                                         select t);
        }

        async Task DeleteTrustAccount(Name from)
        {
            await _dbContext.DeleteAsync(from t in _dbContext.Set<TrustAccount>()
                                         where t.NameId == @from.Id
                                         select t);
        }
        
        async Task DeleteWorkHistory(Name from)
        {
            await _dbContext.DeleteAsync(from w in _dbContext.Set<WorkHistory>()
                                         where w.AccountClientId == @from.Id
                                         select w);
        }

        async Task InsertAccountBalanceFromName(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO ACCOUNT (
                ENTITYNO, NAMENO, BALANCE, CRBALANCE)
		    SELECT	 
                @to, A.NAMENO, isnull(A.BALANCE,0), isnull(A.CRBALANCE,0)
		    FROM ACCOUNT A
		    LEFT JOIN ACCOUNT A1 ON (A1.ENTITYNO = @to and A1.NAMENO = A.NAMENO)
		    WHERE A.ENTITYNO=@from and A1.ENTITYNO is null", parameters);
        }

        async Task InsertAccountBalanceFromEntity(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO ACCOUNT (	 
                ENTITYNO, NAMENO, BALANCE, CRBALANCE)
		    SELECT	 
                A.ENTITYNO, @to, isnull(A.BALANCE,0), isnull(A.CRBALANCE,0)
		    FROM ACCOUNT A
		    LEFT JOIN ACCOUNT A1 ON (A1.ENTITYNO=A.ENTITYNO AND A1.NAMENO  =@to)
		    WHERE A.NAMENO=@from and A1.ENTITYNO is null", parameters);
        }

        async Task UpdateExistingAccountBalanceFromName(Name to, Name from)
        {
            await UpdateAccountsAsync(await (from a in _dbContext.Set<Account>()
                                             join a1 in _dbContext.Set<Account>().Where(_ => _.NameId == @from.Id)
                                                 on a.EntityId equals a1.EntityId into a1J
                                             from a1 in a1J
                                             where a.NameId == to.Id
                                             select new ProjectedAccount
                                             {
                                                 Entity = a,
                                                 NameId = a.NameId,
                                                 EntityNo = a.EntityId,
                                                 Balance = (a.Balance ?? 0) + (a1.Balance ?? 0),
                                                 CrBalance = (a.CreditBalance ?? 0) + (a1.CreditBalance ?? 0)
                                             }).ToArrayAsync());
        }

        async Task UpdateExistingAccountBalanceFromEntity(Name to, Name from)
        {
            await UpdateAccountsAsync(await (from a in _dbContext.Set<Account>()
                                             join a1 in _dbContext.Set<Account>().Where(_ => _.EntityId == @from.Id)
                                                 on a.NameId equals a1.NameId into a1J
                                             from a1 in a1J
                                             where a.EntityId == to.Id
                                             select new ProjectedAccount
                                             {
                                                 Entity = a,
                                                 NameId = a.NameId,
                                                 EntityNo = a.EntityId,
                                                 Balance = (a.Balance ?? 0) + (a1.Balance ?? 0),
                                                 CrBalance = (a.CreditBalance ?? 0) + (a1.CreditBalance ?? 0)
                                             }).ToArrayAsync());
        }

        async Task UpdateAccountsAsync(IEnumerable<ProjectedAccount> accountsToUpdate)
        {
            foreach (var account in accountsToUpdate)
            {
                account.Entity.CreditBalance = account.CrBalance;
                account.Entity.Balance = account.Balance;
            }

            await _dbContext.SaveChangesAsync();
        }

        async Task UpdateBilledItemAccountDebtorNumber(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from bi in _dbContext.Set<BilledItem>()
                                         where bi.AccountDebtorId == @from.Id
                                         select bi,
                                         _ => new BilledItem {AccountDebtorId = to.Id});
        }

        public class ProjectedAccount
        {
            public Account Entity { get; set; }

            public int EntityNo { get; set; }

            public int NameId { get; set; }

            public decimal? Balance { get; set; }

            public decimal? CrBalance { get; set; }
        }
    }
}