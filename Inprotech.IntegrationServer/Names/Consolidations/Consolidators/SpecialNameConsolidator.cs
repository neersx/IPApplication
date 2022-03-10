using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class SpecialNameConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public SpecialNameConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(SpecialNameConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            var specialNames = await (from s in _dbContext.Set<SpecialName>()
                                      where s.Id == @from.Id || s.Id == to.Id
                                      select new
                                      {
                                          s.Id,
                                          EntityFlag = s.IsEntity,
                                          IPOfficeFlag = s.IsIpOffice,
                                          BankFlag = s.IsBankOrFinancialInstitution,
                                          s.LastOpenItemNo,
                                          s.LastDraftNo,
                                          s.LastAccountsReceivableNo,
                                          s.LastAccountsPayableNo,
                                          s.LastInternalItemNo,
                                          s.Currency
                                      }).ToDictionaryAsync(k => k.Id, v => v);

            if (specialNames.ContainsKey(to.Id) || !specialNames.ContainsKey(from.Id)) return;

            _dbContext.Set<SpecialName>()
                      .Add(new SpecialName
                      {
                          Id = to.Id,
                          IsEntity = specialNames[from.Id].EntityFlag,
                          IsIpOffice = specialNames[from.Id].IPOfficeFlag,
                          IsBankOrFinancialInstitution = specialNames[from.Id].BankFlag,
                          LastOpenItemNo = specialNames[from.Id].LastOpenItemNo,
                          LastDraftNo = specialNames[from.Id].LastDraftNo,
                          LastInternalItemNo = specialNames[from.Id].LastInternalItemNo,
                          LastAccountsReceivableNo = specialNames[from.Id].LastAccountsReceivableNo,
                          LastAccountsPayableNo = specialNames[from.Id].LastAccountsPayableNo,
                          Currency = specialNames[from.Id].Currency
                      });

            await _dbContext.SaveChangesAsync();
        }
    }
}