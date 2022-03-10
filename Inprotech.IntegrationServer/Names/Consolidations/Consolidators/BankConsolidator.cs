using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Cash;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Payment;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class BankConsolidator : INameConsolidator
    {
        readonly IBatchedCommand _batchedCommand;
        readonly IDbContext _dbContext;

        public BankConsolidator(IDbContext dbContext, IBatchedCommand batchedCommand)
        {
            _dbContext = dbContext;
            _batchedCommand = batchedCommand;
        }

        public string Name => nameof(BankConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            var parameters = new Dictionary<string, object>
            {
                {"@to", to.Id},
                {"@from", from.Id}
            };

            await InsertBankAccountBankName(parameters);

            await InsertBankAccountAccountOwner(parameters);

            await UpdateBankAccountBranch(to, from);

            await InsertBankHistoryEntity(parameters);

            await InsertBankHistoryName(parameters);

            await InsertStatementTransactionsAccountOwner(parameters);

            await InsertStatementTransactionsBankName(parameters);

            await DeleteStatementTransactions(from);

            await DeleteBankHistory(from);

            await InsertBankStatementsAccountOwner(parameters);

            await InsertBankStatementsBankName(parameters);

            await DeleteBankStatements(from);

            await InsertCashItemsEntity(parameters);

            await InsertCashItemsBankName(parameters);

            await UpdateCashItems(to, from);

            await InsertCashHistory(parameters);

            await UpdateCashHistory(from, to);

            await DeleteCashHistory(from);

            await DeleteCashItem(from);

            await UpdateChequeRegister(to, from);

            await UpdateCreditorBankAccountOwner(to, from);

            await UpdateCreditorBankName(to, from);

            await UpdateCreditorEntityDetail(to, from);

            await UpdateElectronicFundsTransferDetailBankName(to, from);

            await UpdateElectronicFundsTransferAccountOwner(to, from);

            await UpdateGeneralLedgerAccountMapping(to, from);

            await UpdatePaymentPlanBankName(to, from);

            await DeletePaymentPlanBankAccount(from);

            await DeleteCreditor(from, option);

            await DeleteAccount(from);

            await DeleteSpecialName(from);
        }

        async Task DeleteSpecialName(Name from)
        {
            await _dbContext.DeleteAsync(from s in _dbContext.Set<SpecialName>()
                                         where s.Id == @from.Id
                                         select s);
        }

        async Task DeleteAccount(Name from)
        {
            await _dbContext.DeleteAsync(from a in _dbContext.Set<Account>()
                                         where a.NameId == @from.Id
                                         select a);
        }

        async Task DeleteCreditor(Name from, ConsolidationOption option)
        {
            if (option.KeepConsolidatedName) return;

            await _dbContext.DeleteAsync(from c in _dbContext.Set<Creditor>()
                                         where c.NameId == @from.Id
                                         select c);
        }

        async Task DeletePaymentPlanBankAccount(Name from)
        {
            await _dbContext.DeleteAsync(from b in _dbContext.Set<BankAccount>()
                                         where b.AccountOwner == @from.Id || b.BankNameNo == @from.Id
                                         select b);
        }

        async Task UpdatePaymentPlanBankName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from p in _dbContext.Set<PaymentPlan>()
                                         where p.BankNameNo == @from.Id
                                         select p,
                                         _ => new PaymentPlan {BankNameNo = to.Id});
        }

        async Task UpdateGeneralLedgerAccountMapping(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from g in _dbContext.Set<GlAccountMapping>()
                                         where g.BankNameId == @from.Id
                                         select g,
                                         _ => new GlAccountMapping {BankNameId = to.Id});
        }

        async Task UpdateElectronicFundsTransferAccountOwner(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from eft in _dbContext.Set<ElectronicFundsTransferDetail>()
                                         where eft.AccountOwner == @from.Id
                                         select eft,
                                         _ => new ElectronicFundsTransferDetail {AccountOwner = to.Id});
        }

        async Task UpdateElectronicFundsTransferDetailBankName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from eft in _dbContext.Set<ElectronicFundsTransferDetail>()
                                         where eft.BankNameNo == @from.Id
                                         select eft,
                                         _ => new ElectronicFundsTransferDetail {BankNameNo = to.Id});
        }

        async Task UpdateCreditorEntityDetail(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from c in _dbContext.Set<CreditorEntityDetail>()
                                         where c.BankNameNo == @from.Id
                                         select c,
                                         _ => new CreditorEntityDetail {BankNameNo = to.Id});
        }

        async Task UpdateCreditorBankName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from c in _dbContext.Set<Creditor>()
                                         where c.BankNameNo == @from.Id
                                         select c,
                                         _ => new Creditor {BankNameNo = to.Id});
        }

        async Task UpdateCreditorBankAccountOwner(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from c in _dbContext.Set<Creditor>()
                                         where c.BankAccountOwner == @from.Id
                                         select c,
                                         _ => new Creditor {BankAccountOwner = to.Id});
        }

        async Task UpdateChequeRegister(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from c in _dbContext.Set<ChequeRegister>()
                                         where c.BankNameNo == @from.Id
                                         select c,
                                         _ => new ChequeRegister {BankNameNo = to.Id});
        }

        async Task InsertCashHistory(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO CASHHISTORY(	 
                ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, HISTORYLINENO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, 
                REFENTITYNO, REFTRANSNO, [STATUS], [DESCRIPTION], ASSOCIATEDLINENO, ITEMREFNO, ACCTENTITYNO, ACCTNAMENO, GLACCOUNTCODE, 
                DISSECTIONCURRENCY, FOREIGNAMOUNT, DISSECTIONEXCHANGE, LOCALAMOUNT, ITEMIMPACT, GLMOVEMENTNO)
		    SELECT	 
                ENTITYNO, @to, SEQUENCENO, TRANSENTITYNO, TRANSNO, HISTORYLINENO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, 
                REFENTITYNO, REFTRANSNO, [STATUS], [DESCRIPTION], ASSOCIATEDLINENO, ITEMREFNO, ACCTENTITYNO ,ACCTNAMENO, GLACCOUNTCODE, 
                DISSECTIONCURRENCY, FOREIGNAMOUNT, DISSECTIONEXCHANGE, LOCALAMOUNT, ITEMIMPACT, GLMOVEMENTNO
            FROM CASHHISTORY
		    WHERE BANKNAMENO=@from", parameters);
        }

        async Task UpdateCashHistory(Name from, Name to)
        {
            await _dbContext.UpdateAsync(from c in _dbContext.Set<CashHistory>()
                                         where c.AccountNameId == @from.Id
                                         select c,
                                         _ => new CashHistory {AccountNameId = to.Id});
        }

        async Task DeleteCashHistory(Name from)
        {
            await _dbContext.DeleteAsync(from c in _dbContext.Set<CashHistory>()
                                         where c.BankNameId == @from.Id
                                         select c);
        }

        async Task DeleteCashItem(Name from)
        {
            await _dbContext.DeleteAsync(from c in _dbContext.Set<CashItem>()
                                         where c.EntityId == @from.Id || c.BankNameId == @from.Id
                                         select c);
        }

        async Task InsertCashItemsEntity(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO CASHITEM(	 
                ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, ITEMDATE, [DESCRIPTION], [STATUS], ITEMTYPE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, TRADER, 
                ACCTENTITYNO, ACCTNAMENO, BANKEDBYENTITYNO, BANKEDBYTRANSNO, BANKCATEGORY, ITEMBANKBRANCHNO, ITEMREFNO, ITEMBANKNAME, ITEMBANKBRANCH, CREDITCARDTYPE, CARDEXPIRYDATE, 
                PAYMENTCURRENCY, PAYMENTAMOUNT, BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET, DISSECTIONCURRENCY, DISSECTIONAMOUNT, DISSECTIONUNALLOC, DISSECTIONEXCHANGE, 
                LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, LOCALUNALLOCATED, BANKOPERATIONCODE, DETAILSOFCHARGES, EFTFILEFORMAT, EFTPAYMENTFILE, 
                FXDEALERREF, TRANSFERENTITYNO, TRANSFERTRANSNO, INSTRUCTIONCODE)
		    SELECT   
                @to, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, ITEMDATE, [DESCRIPTION], [STATUS], ITEMTYPE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, TRADER,
                ACCTENTITYNO, ACCTNAMENO, BANKEDBYENTITYNO, BANKEDBYTRANSNO, BANKCATEGORY, ITEMBANKBRANCHNO, ITEMREFNO, ITEMBANKNAME, ITEMBANKBRANCH, CREDITCARDTYPE, CARDEXPIRYDATE,
                PAYMENTCURRENCY, PAYMENTAMOUNT, BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET, DISSECTIONCURRENCY, DISSECTIONAMOUNT, DISSECTIONUNALLOC, DISSECTIONEXCHANGE, 
                LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, LOCALUNALLOCATED, BANKOPERATIONCODE, DETAILSOFCHARGES, EFTFILEFORMAT, EFTPAYMENTFILE, 
                FXDEALERREF, TRANSFERENTITYNO, TRANSFERTRANSNO, INSTRUCTIONCODE
		    FROM CASHITEM
		    WHERE ENTITYNO=@from", parameters);
        }

        async Task InsertCashItemsBankName(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO CASHITEM(	 
                ENTITYNO, BANKNAMENO, SEQUENCENO, TRANSENTITYNO, TRANSNO, ITEMDATE, [DESCRIPTION], [STATUS], ITEMTYPE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, TRADER, 
                ACCTENTITYNO, ACCTNAMENO, BANKEDBYENTITYNO, BANKEDBYTRANSNO, BANKCATEGORY, ITEMBANKBRANCHNO, ITEMREFNO, ITEMBANKNAME, ITEMBANKBRANCH, CREDITCARDTYPE, CARDEXPIRYDATE, 
                PAYMENTCURRENCY, PAYMENTAMOUNT, BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET, DISSECTIONCURRENCY, DISSECTIONAMOUNT, DISSECTIONUNALLOC, DISSECTIONEXCHANGE, 
                LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, LOCALUNALLOCATED, BANKOPERATIONCODE, DETAILSOFCHARGES, EFTFILEFORMAT, EFTPAYMENTFILE, 
                FXDEALERREF, TRANSFERENTITYNO, TRANSFERTRANSNO, INSTRUCTIONCODE)
		    SELECT   
                ENTITYNO, @to, SEQUENCENO, TRANSENTITYNO, TRANSNO, ITEMDATE, [DESCRIPTION], [STATUS], ITEMTYPE, POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, TRADER,
                ACCTENTITYNO, ACCTNAMENO, BANKEDBYENTITYNO, BANKEDBYTRANSNO, BANKCATEGORY, ITEMBANKBRANCHNO, ITEMREFNO, ITEMBANKNAME, ITEMBANKBRANCH, CREDITCARDTYPE, CARDEXPIRYDATE,
                PAYMENTCURRENCY, PAYMENTAMOUNT, BANKEXCHANGERATE, BANKAMOUNT, BANKCHARGES, BANKNET, DISSECTIONCURRENCY, DISSECTIONAMOUNT, DISSECTIONUNALLOC, DISSECTIONEXCHANGE, 
                LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, LOCALUNALLOCATED, BANKOPERATIONCODE, DETAILSOFCHARGES, EFTFILEFORMAT, EFTPAYMENTFILE, 
                FXDEALERREF, TRANSFERENTITYNO, TRANSFERTRANSNO, INSTRUCTIONCODE
		    FROM CASHITEM
		    WHERE BANKNAMENO=@from", parameters);
        }

        async Task UpdateCashItems(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from c in _dbContext.Set<CashItem>()
                                         where c.AccountNameId == @from.Id
                                         select c,
                                         _ => new CashItem {AccountNameId = to.Id});
        }

        async Task InsertStatementTransactionsAccountOwner(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO STATEMENTTRANS(STATEMENTNO, ACCOUNTOWNER, BANKNAMENO, ACCOUNTSEQUENCENO, HISTORYLINENO)
		    SELECT	 STATEMENTNO, @to, BANKNAMENO, ACCOUNTSEQUENCENO, HISTORYLINENO
		    FROM STATEMENTTRANS
		    WHERE ACCOUNTOWNER=@from", parameters);
        }

        async Task InsertStatementTransactionsBankName(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO STATEMENTTRANS(STATEMENTNO, ACCOUNTOWNER, BANKNAMENO, ACCOUNTSEQUENCENO, HISTORYLINENO)
		    SELECT	 STATEMENTNO, ACCOUNTOWNER, @to, ACCOUNTSEQUENCENO, HISTORYLINENO
		    FROM STATEMENTTRANS
		    WHERE BANKNAMENO=@from", parameters);
        }

        async Task DeleteStatementTransactions(Name from)
        {
            await _dbContext.DeleteAsync(from s in _dbContext.Set<StatementTran>()
                                         where s.AccountOwner == @from.Id || s.BankNameNo == @from.Id
                                         select s);
        }

        async Task DeleteBankHistory(Name from)
        {
            await _dbContext.DeleteAsync(from b in _dbContext.Set<BankHistory>()
                                         where b.EntityId == @from.Id || b.BankNameId == @from.Id
                                         select b);
        }

        async Task InsertBankStatementsAccountOwner(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO BANKSTATEMENT(	 
                STATEMENTNO, ACCOUNTOWNER, BANKNAMENO, ACCOUNTSEQUENCENO, STATEMENTENDDATE, CLOSINGBALANCE, ISRECONCILED,
                USERID, DATECREATED, OPENINGBALANCE, RECONCILEDDATE, IDENTITYID)
		    SELECT	 
                STATEMENTNO, @to, BANKNAMENO, ACCOUNTSEQUENCENO, STATEMENTENDDATE, CLOSINGBALANCE, ISRECONCILED, 
                USERID, DATECREATED, OPENINGBALANCE, RECONCILEDDATE, IDENTITYID
		    FROM BANKSTATEMENT
		    WHERE ACCOUNTOWNER=@from", parameters);
        }

        async Task InsertBankStatementsBankName(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO BANKSTATEMENT(	 
                STATEMENTNO, ACCOUNTOWNER, BANKNAMENO, ACCOUNTSEQUENCENO, STATEMENTENDDATE, CLOSINGBALANCE, ISRECONCILED,
                USERID, DATECREATED, OPENINGBALANCE, RECONCILEDDATE, IDENTITYID)
		    SELECT	 
                STATEMENTNO, ACCOUNTOWNER, @to, ACCOUNTSEQUENCENO, STATEMENTENDDATE, CLOSINGBALANCE, ISRECONCILED, 
                USERID, DATECREATED, OPENINGBALANCE, RECONCILEDDATE, IDENTITYID
		    FROM BANKSTATEMENT
		    WHERE BANKNAMENO=@from", parameters);
        }

        async Task DeleteBankStatements(Name from)
        {
            await _dbContext.DeleteAsync(from b in _dbContext.Set<BankStatement>()
                                         where b.AccountOwner == @from.Id || b.BankNameNo == @from.Id
                                         select b);
        }

        async Task InsertBankHistoryEntity(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO BANKHISTORY(	 
                ENTITYNO, BANKNAMENO, SEQUENCENO, HISTORYLINENO, TRANSDATE, POSTDATE, POSTPERIOD, PAYMENTMETHOD, WITHDRAWALCHEQUENO, TRANSTYPE, MOVEMENTCLASS, 
                COMMANDID, REFENTITYNO, REFTRANSNO, [STATUS], [DESCRIPTION], ASSOCLINENO, PAYMENTCURRENCY, PAYMENTAMOUNT, BANKEXCHANGERATE, BANKAMOUNT, 
                BANKCHARGES, BANKNET, LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, BANKCATEGORY, REFERENCE, ISRECONCILED, GLMOVEMENTNO)
		    SELECT	 
                @to, B.BANKNAMENO, B.SEQUENCENO, B.HISTORYLINENO, B.TRANSDATE, B.POSTDATE, B.POSTPERIOD, B.PAYMENTMETHOD, B.WITHDRAWALCHEQUENO, B.TRANSTYPE, B.MOVEMENTCLASS,
                B.COMMANDID, B.REFENTITYNO, B.REFTRANSNO, B.[STATUS], B.[DESCRIPTION], B.ASSOCLINENO, B.PAYMENTCURRENCY, B.PAYMENTAMOUNT, B.BANKEXCHANGERATE, B.BANKAMOUNT,
                B.BANKCHARGES, B.BANKNET, B.LOCALAMOUNT, B.LOCALCHARGES, B.LOCALEXCHANGERATE, B.LOCALNET, B.BANKCATEGORY, B.REFERENCE, B.ISRECONCILED, B.GLMOVEMENTNO
		    FROM BANKHISTORY B
		    where ENTITYNO=@from", parameters);
        }

        async Task InsertBankHistoryName(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO BANKHISTORY(	 
                ENTITYNO, BANKNAMENO, SEQUENCENO, HISTORYLINENO, TRANSDATE, POSTDATE, POSTPERIOD, PAYMENTMETHOD, WITHDRAWALCHEQUENO, TRANSTYPE, MOVEMENTCLASS, 
                COMMANDID, REFENTITYNO, REFTRANSNO, [STATUS], [DESCRIPTION], ASSOCLINENO, PAYMENTCURRENCY, PAYMENTAMOUNT, BANKEXCHANGERATE, BANKAMOUNT, 
                BANKCHARGES, BANKNET, LOCALAMOUNT, LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET, BANKCATEGORY, REFERENCE, ISRECONCILED, GLMOVEMENTNO)
		    SELECT	 
                B.ENTITYNO, @to, B.SEQUENCENO, B.HISTORYLINENO, B.TRANSDATE, B.POSTDATE, B.POSTPERIOD, B.PAYMENTMETHOD, B.WITHDRAWALCHEQUENO, B.TRANSTYPE, B.MOVEMENTCLASS,
                B.COMMANDID, B.REFENTITYNO, B.REFTRANSNO, B.[STATUS], B.[DESCRIPTION], B.ASSOCLINENO, B.PAYMENTCURRENCY, B.PAYMENTAMOUNT, B.BANKEXCHANGERATE, B.BANKAMOUNT,
                B.BANKCHARGES, B.BANKNET, B.LOCALAMOUNT, B.LOCALCHARGES, B.LOCALEXCHANGERATE, B.LOCALNET, B.BANKCATEGORY, B.REFERENCE, B.ISRECONCILED, B.GLMOVEMENTNO
		    FROM BANKHISTORY B
		    where BANKNAMENO=@from", parameters);
        }

        async Task InsertBankAccountBankName(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO BANKACCOUNT(	 
                ACCOUNTOWNER, BANKNAMENO, SEQUENCENO, ISOPERATIONAL, BANKBRANCHNO, BRANCHNAMENO, ACCOUNTNO, ACCOUNTNAME, CURRENCY, [DESCRIPTION], ACCOUNTTYPE, DRAWCHEQUESFLAG, 
                LASTMANUALCHEQUE, LASTAUTOCHEQUE, ACCOUNTBALANCE, LOCALBALANCE, DATECEASED, BICBANKCODE, BICCOUNTRYCODE, BICLOCATIONCODE, BICBRANCHCODE, IBAN, 
                BANKOPERATIONCODE, DETAILSOFCHARGES, EFTFILEFORMATUSED, CABPROFITCENTRE, CABACCOUNTID, CABCPROFITCENTRE, CABCACCOUNTID, PROCAMOUNTTOWORDS,TRUSTACCTFLAG)
		    SELECT   
                B.ACCOUNTOWNER, @to, B.SEQUENCENO, B.ISOPERATIONAL, B.BANKBRANCHNO, B.BRANCHNAMENO, B.ACCOUNTNO, B.ACCOUNTNAME, B.CURRENCY, B.[DESCRIPTION], B.ACCOUNTTYPE, B.DRAWCHEQUESFLAG,
                B.LASTMANUALCHEQUE, B.LASTAUTOCHEQUE, B.ACCOUNTBALANCE, B.LOCALBALANCE, B.DATECEASED, B.BICBANKCODE, B.BICCOUNTRYCODE, B.BICLOCATIONCODE, B.BICBRANCHCODE, B.IBAN,
                B.BANKOPERATIONCODE, B.DETAILSOFCHARGES, B.EFTFILEFORMATUSED, B.CABPROFITCENTRE, B.CABACCOUNTID, B.CABCPROFITCENTRE, B.CABCACCOUNTID, B.PROCAMOUNTTOWORDS, B.TRUSTACCTFLAG
		    FROM BANKACCOUNT B
		    LEFT JOIN BANKACCOUNT B1 on (B1.ACCOUNTOWNER=B.ACCOUNTOWNER and B1.BANKNAMENO  = @to)
		    WHERE B.BANKNAMENO=@from
		    AND  B1.BANKNAMENO is null", parameters);
        }

        async Task InsertBankAccountAccountOwner(Dictionary<string, object> parameters)
        {
            await _batchedCommand.ExecuteAsync(@"
            INSERT INTO BANKACCOUNT(	 
                ACCOUNTOWNER, BANKNAMENO, SEQUENCENO, ISOPERATIONAL, BANKBRANCHNO, BRANCHNAMENO, ACCOUNTNO, ACCOUNTNAME, CURRENCY, [DESCRIPTION], ACCOUNTTYPE, DRAWCHEQUESFLAG, 
                LASTMANUALCHEQUE, LASTAUTOCHEQUE, ACCOUNTBALANCE, LOCALBALANCE, DATECEASED, BICBANKCODE, BICCOUNTRYCODE, BICLOCATIONCODE, BICBRANCHCODE, IBAN, 
                BANKOPERATIONCODE, DETAILSOFCHARGES, EFTFILEFORMATUSED, CABPROFITCENTRE, CABACCOUNTID, CABCPROFITCENTRE, CABCACCOUNTID, PROCAMOUNTTOWORDS,TRUSTACCTFLAG)
		    SELECT   
                @to, B.BANKNAMENO, B.SEQUENCENO, B.ISOPERATIONAL, B.BANKBRANCHNO, B.BRANCHNAMENO, B.ACCOUNTNO, B.ACCOUNTNAME, B.CURRENCY, B.[DESCRIPTION], B.ACCOUNTTYPE, B.DRAWCHEQUESFLAG,
                B.LASTMANUALCHEQUE, B.LASTAUTOCHEQUE, B.ACCOUNTBALANCE, B.LOCALBALANCE, B.DATECEASED, B.BICBANKCODE, B.BICCOUNTRYCODE, B.BICLOCATIONCODE, B.BICBRANCHCODE, B.IBAN,
                B.BANKOPERATIONCODE, B.DETAILSOFCHARGES, B.EFTFILEFORMATUSED, B.CABPROFITCENTRE, B.CABACCOUNTID, B.CABCPROFITCENTRE, B.CABCACCOUNTID, B.PROCAMOUNTTOWORDS, B.TRUSTACCTFLAG
		    FROM BANKACCOUNT B
		    LEFT JOIN BANKACCOUNT B1 on (B1.ACCOUNTOWNER=@to and B1.BANKNAMENO  = B.BANKNAMENO)
		    WHERE B.ACCOUNTOWNER=@from
		    AND  B1.ACCOUNTOWNER is null", parameters);
        }

        async Task UpdateBankAccountBranch(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from b in _dbContext.Set<BankAccount>()
                                         where b.BranchNameNo == @from.Id
                                         select b,
                                         _ => new BankAccount {BranchNameNo = to.Id});
        }
    }
}