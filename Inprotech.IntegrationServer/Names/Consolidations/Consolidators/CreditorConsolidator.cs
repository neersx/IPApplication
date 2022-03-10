using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class CreditorConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public CreditorConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(CreditorConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await CopyCreditorDetails(to, from);

            await ChangeCreditorEntityParent(to, from);

            await DeleteCreditorEntity(from, option.KeepConsolidatedName);
        }

        async Task CopyCreditorDetails(Name to, Name from)
        {
            var creditors = await _dbContext.Set<Creditor>().Where(_ => _.NameId == from.Id || _.NameId == to.Id)
                                            .ToDictionaryAsync(k => k.NameId, v => v);

            if (creditors.ContainsKey(from.Id) && !creditors.ContainsKey(to.Id))
            {
                _dbContext.Set<Creditor>().Add(new Creditor
                {
                    NameId = to.Id,
                    SupplierType = creditors[from.Id].SupplierType,
                    DefaultTaxCode = creditors[from.Id].DefaultTaxCode,
                    TaxTreatment = creditors[from.Id].TaxTreatment,
                    PurchaseCurrency = creditors[from.Id].PurchaseCurrency,
                    PaymentTermNo = creditors[from.Id].PaymentTermNo,
                    ChequePayee = creditors[from.Id].ChequePayee,
                    Instructions = creditors[from.Id].Instructions,
                    ExpenseAccount = creditors[from.Id].ExpenseAccount,
                    ProfitCentre = creditors[from.Id].ProfitCentre,
                    PaymentMethod = creditors[from.Id].PaymentMethod,
                    BankName = creditors[from.Id].BankName,
                    BankBranchNo = creditors[from.Id].BankBranchNo,
                    BankAccountNo = creditors[from.Id].BankAccountNo,
                    BankAccountName = creditors[from.Id].BankAccountName,
                    BankAccountOwner = creditors[from.Id].BankAccountOwner,
                    BankNameNo = creditors[from.Id].BankNameNo,
                    BankSequenceNo = creditors[from.Id].BankSequenceNo,
                    RestrictionId = creditors[from.Id].RestrictionId,
                    RestrictionReasonCode = creditors[from.Id].RestrictionReasonCode,
                    PurchaseDescription = creditors[from.Id].PurchaseDescription,
                    DisbursementWipCode = creditors[from.Id].DisbursementWipCode,
                    BeiBankCode = creditors[from.Id].BeiBankCode,
                    BeiCountryCode = creditors[from.Id].BeiCountryCode,
                    BeiLocationCode = creditors[from.Id].BeiLocationCode,
                    BeiBranchCode = creditors[from.Id].BeiBranchCode,
                    InstructionsTId = creditors[from.Id].InstructionsTId,
                    ExchangeScheduleId = creditors[from.Id].ExchangeScheduleId
                });

                await _dbContext.SaveChangesAsync();

                to.SupplierFlag = 1;

                await _dbContext.SaveChangesAsync();
            }
        }

        async Task ChangeCreditorEntityParent(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from c1 in _dbContext.Set<CreditorEntityDetail>()
                                         join c2 in _dbContext.Set<CreditorEntityDetail>().Where(_ => _.NameId == to.Id)
                                             on c1.EntityNameNo equals c2.EntityNameNo into c2J
                                         from c2 in c2J.DefaultIfEmpty()
                                         where c1.NameId == @from.Id && c2 == null
                                         select c1,
                                         _ => new CreditorEntityDetail {NameId = to.Id});
        }

        async Task DeleteCreditorEntity(Name from, bool shouldKeepConsolidatedName)
        {
            if (shouldKeepConsolidatedName) return;

            await _dbContext.DeleteAsync(_dbContext.Set<CreditorEntityDetail>().Where(_ => _.NameId == from.Id));
        }
    }
}