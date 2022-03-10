using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Banking;
using InprotechKaizen.Model.Accounting.Cash;
using InprotechKaizen.Model.Accounting.Cost;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Names.Consolidations
{
    public interface INamesConsolidationValidator
    {
        Task<(bool FinancialCheckPerformed, IEnumerable<NamesConsolidationResult> Errors)> Validate(int targetNameNo, int[] namesToBeConsolidated, bool validateFinancialData);
    }

    class NamesConsolidationValidator : INamesConsolidationValidator
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;
        readonly Func<DateTime> _now;

        public NamesConsolidationValidator(IDbContext dbContext, ISiteControlReader siteControlReader, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _now = now;
        }

        public async Task<(bool FinancialCheckPerformed, IEnumerable<NamesConsolidationResult> Errors)> Validate(int targetNameNo, int[] namesToBeConsolidated, bool validateFinancialData)
        {
            var allNames = await _dbContext.Set<Name>().Where(_ => _.Id == targetNameNo || namesToBeConsolidated.Contains(_.Id)).ToListAsync();
            var targetName = allNames.Single(_ => _.Id == targetNameNo);
            var names = allNames.Except(new[] { targetName }).ToArray();

            var nameTypeValidationResult = ValidateNameTypes(targetName, names);

            validateFinancialData = validateFinancialData || !nameTypeValidationResult.Any();
            if (!validateFinancialData || nameTypeValidationResult.Any(_ => _.IsBlocking))
                return (false, nameTypeValidationResult);

            return (true, await ValidateFinancialData(targetName, names));
        }

        ICollection<NamesConsolidationResult> ValidateNameTypes(Name targetName, Name[] namesToBeConsolidated)
        {
            var result = new List<NamesConsolidationResult>();
            foreach (var name in namesToBeConsolidated)
            {
                if ((targetName.IsStaff || name.IsStaff) && targetName.IsIndividual != name.IsIndividual)
                    result.Add(new NamesConsolidationResult(name.Id, StaffAndOrganizationValidationMessage(targetName), true));

                else if (targetName.IsClient != name.IsClient)
                    result.Add(new NamesConsolidationResult(name.Id, ClientValidationMessage(targetName)));

                else if (targetName.IsStaff != name.IsStaff)
                    result.Add(new NamesConsolidationResult(name.Id, IndividualAndStaffValidationMessage(targetName)));

                else if (targetName.IsIndividual != name.IsIndividual)
                    result.Add(new NamesConsolidationResult(name.Id, IndividualAndOrganizationValidationMessage(targetName)));
            }

            return result;
        }

        async Task<ICollection<NamesConsolidationResult>> ValidateFinancialData(Name targetName, Name[] namesToBeConsolidated)
        {
            int[] namesWithOutstandingBalance = new int[0];
            var specialNames = await GetNamesConfiguredAsAccountingEntries(namesToBeConsolidated.Select(_ => _.Id));
            var blockOnFinancialError = !_siteControlReader.Read<bool>(SiteControls.NameConsolidateFinancials);
            var isActive = targetName.IsActive(_now);
            if (!isActive)
                namesWithOutstandingBalance = await GetNamesWithOutstandingBalance(namesToBeConsolidated.Select(_ => _.Id));

            var result = new List<NamesConsolidationResult>();
            foreach (var name in namesToBeConsolidated)
            {
                if (specialNames.Contains(name.Id))
                {
                    result.Add(new NamesConsolidationResult(name.Id, "acct-entry", true));
                }
                else if (!isActive)
                {
                    if (namesWithOutstandingBalance.Contains(name.Id))
                        result.Add(new NamesConsolidationResult(name.Id, "pen-bal", true));
                }

                else if (await HasFinancialData(name.Id))
                {
                    result.Add(new NamesConsolidationResult(name.Id, blockOnFinancialError ? "fin-block" : "fin-warn", blockOnFinancialError));
                }
            }

            return result;
        }

        async Task<bool> HasFinancialData(int nameNo)
        {
            var financialRecordsQuery = from n in _dbContext.Set<Name>().Where(_ => _.Id == nameNo)
                                        join t in _dbContext.Set<Diary>() on n.Id equals t.EmployeeNo into d1A
                                        from d1 in d1A.DefaultIfEmpty()
                                        join t in _dbContext.Set<Diary>() on n.Id equals t.NameNo into d2A
                                        from d2 in d2A.DefaultIfEmpty()
                                        join t in _dbContext.Set<WorkHistory>() on n.Id equals t.StaffId into wh1A
                                        from wh1 in wh1A.DefaultIfEmpty()
                                        join t in _dbContext.Set<WorkHistory>() on n.Id equals t.AccountClientId into wh2A
                                        from wh2 in wh2A.DefaultIfEmpty()
                                        join t in _dbContext.Set<DebtorHistory>() on n.Id equals t.AccountDebtorId into dh1
                                        from dh in dh1.DefaultIfEmpty()
                                        join t in _dbContext.Set<CreditorHistory>() on n.Id equals t.AccountCreditorId into ch1
                                        from ch in ch1.DefaultIfEmpty()
                                        join t in _dbContext.Set<CashHistory>() on n.Id equals t.AccountNameId into chh1
                                        from chh in chh1.DefaultIfEmpty()
                                        join t in _dbContext.Set<TaxHistory>() on n.Id equals t.AccountDebtorId into th1
                                        from th in th1.DefaultIfEmpty()
                                        join t in _dbContext.Set<BankHistory>() on n.Id equals t.BankNameId into bh1
                                        from bh in bh1.DefaultIfEmpty()
                                        join t in _dbContext.Set<TimeCosting>() on n.Id equals t.NameNo into tc1A
                                        from tc1 in tc1A.DefaultIfEmpty()
                                        join t in _dbContext.Set<TimeCosting>() on n.Id equals t.EmployeeNo into tc2A
                                        from tc2 in tc2A.DefaultIfEmpty()
                                        join t in _dbContext.Set<TimeCosting>() on n.Id equals t.Owner into tc3A
                                        from tc3 in tc3A.DefaultIfEmpty()
                                        join t in _dbContext.Set<TimeCosting>() on n.Id equals t.Instructor into tc4A
                                        from tc4 in tc4A.DefaultIfEmpty()
                                        join t in _dbContext.Set<TransactionHeader>() on n.Id equals t.StaffId into tr1
                                        from tr in tr1.DefaultIfEmpty()
                                        join t in _dbContext.Set<NameAddressSnapshot>() on n.Id equals t.NameId into nas1A
                                        from nas1 in nas1A.DefaultIfEmpty()
                                        join t in _dbContext.Set<NameAddressSnapshot>() on n.Id equals t.AttentionNameId into nas2A
                                        from nas2 in nas2A.DefaultIfEmpty()
                                        join t in _dbContext.Set<Margin>() on n.Id equals t.AgentId into mg1A
                                        from mg1 in mg1A.DefaultIfEmpty()
                                        join t in _dbContext.Set<Margin>() on n.Id equals t.InstructorId into mg2A
                                        from mg2 in mg2A.DefaultIfEmpty()
                                        join t in _dbContext.Set<NameMarginProfile>() on n.Id equals t.NameId into nmp1
                                        from nmp in nmp1.DefaultIfEmpty()
                                        join t in _dbContext.Set<FeesCalculation>() on n.Id equals t.AgentId into fc1A
                                        from fc1 in fc1A.DefaultIfEmpty()
                                        join t in _dbContext.Set<FeesCalculation>() on n.Id equals t.OwnerId into fc2A
                                        from fc2 in fc2A.DefaultIfEmpty()
                                        join t in _dbContext.Set<FeesCalculation>() on n.Id equals t.DebtorId into fc3A
                                        from fc3 in fc3A.DefaultIfEmpty()
                                        join t in _dbContext.Set<FeesCalculation>() on n.Id equals t.InstructorId into fc4A
                                        from fc4 in fc4A.DefaultIfEmpty()
                                        join t in _dbContext.Set<GlAccountMapping>() on n.Id equals t.WipStaffId into gl1
                                        from gl in gl1.DefaultIfEmpty()
                                        where d1 != null || d2 != null || wh1 != null || wh2 != null
                                              || dh != null || ch != null
                                              || chh != null || th != null || bh != null
                                              || tc1 != null || tc2 != null || tc3 != null || tc4 != null
                                              || tr != null
                                              || nas1 != null || nas2 != null
                                              || mg1 != null || mg2 != null
                                              || nmp != null
                                              || fc1 != null || fc2 != null || fc3 != null || fc4 != null
                                              || gl != null
                                        select new
                                        {
                                            EmployeeNo = d1 == null ? null : (int?)d1.EmployeeNo,
                                            NameNo = d2 == null ? null : d2.NameNo,
                                            WorkHistory = wh1 == null ? null : wh1.StaffId,
                                            AcctClientNo = wh2 == null ? null : wh2.AccountClientId,
                                            AcctDebtorNo = dh == null ? null : (int?)dh.AccountDebtorId,
                                            AcctCreditorNo = ch == null ? null : (int?)ch.AccountCreditorId,
                                            AcctNameNo = chh == null ? null : chh.AccountNameId,
                                            BankNameNo = bh == null ? null : (int?)bh.BankNameId
                                        };
            return await financialRecordsQuery.AnyAsync();
        }

        async Task<int[]> GetNamesConfiguredAsAccountingEntries(IEnumerable<int> namesToBeConsolidated)
        {
            return await _dbContext.Set<SpecialName>()
                                   .Where(_ => namesToBeConsolidated.Contains(_.Id) && _.IsEntity == 1)
                                   .Select(_ => _.Id)
                                   .ToArrayAsync();
        }
        async Task<int[]> GetNamesWithOutstandingBalance(IEnumerable<int> namesToBeConsolidated)
        {
            return await _dbContext.Set<Account>()
                                   .Where(_ => namesToBeConsolidated.Contains(_.NameId) && (_.Balance > 0 || _.CreditBalance > 0))
                                   .Select(_ => _.NameId)
                                   .ToArrayAsync();
        }

        string ClientValidationMessage(Name targetName)
        {
            string NonClientToClient = "nonclient-client";
            string ClientToNonClient = "client-nonclient";
            return targetName.IsClient ? NonClientToClient : ClientToNonClient;
        }

        string IndividualAndStaffValidationMessage(Name targetName)
        {
            string StaffToIndividual = "sta-ind";
            string IndividualToStaff = "ind-sta";
            return targetName.IsStaff ? StaffToIndividual : IndividualToStaff;
        }

        string StaffAndOrganizationValidationMessage(Name targetName)
        {
            string OrganizationToStaff = "org-sta";
            string StaffToOrganization = "sta-org";
            return targetName.IsIndividual ? OrganizationToStaff : StaffToOrganization;
        }

        string IndividualAndOrganizationValidationMessage(Name targetName)
        {
            string OrganizationToIndividual = "org-ind";
            string IndividualToOrganization = "ind-org";
            return targetName.IsIndividual ? OrganizationToIndividual : IndividualToOrganization;
        }

    }

    public class NamesConsolidationResult
    {
        public NamesConsolidationResult(int nameNo, string error, bool isBlocking = false)
        {
            NameNo = nameNo;
            Error = error;
            IsBlocking = isBlocking;
        }

        public int NameNo { get; set; }
        public string Error { get; set; }
        public bool IsBlocking { get; set; }
    }
}