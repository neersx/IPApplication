using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Restrictions
{
    public interface ICaseCreditLimitChecker
    {
        IEnumerable<CaseName> NamesExceededCreditLimit(Case @case);
    }

    public class CaseCreditLimitChecker : ICaseCreditLimitChecker
    {
        readonly IDbContext _dbContext;
        readonly IRestrictableCaseNames _restrictableNames;

        public CaseCreditLimitChecker(IDbContext dbContext, IRestrictableCaseNames restrictableNames)
        {
            if(dbContext == null) throw new ArgumentNullException("dbContext");
            if(restrictableNames == null) throw new ArgumentNullException("restrictableNames");

            _dbContext = dbContext;
            _restrictableNames = restrictableNames;
        }

        public IEnumerable<CaseName> NamesExceededCreditLimit(Case @case)
        {
            if(@case == null) throw new ArgumentNullException("case");

            var nameTypesToConsider = new[] {KnownNameTypes.Debtor, KnownNameTypes.Instructor};

            var namesWithCreditLimit = _restrictableNames.For(@case)
                                                         .Where(
                                                                rn =>
                                                                nameTypesToConsider.Contains(rn.NameType.NameTypeCode) &&
                                                                rn.Name.ClientDetail.CreditLimit.HasValue).ToArray();

            var nameIds = namesWithCreditLimit.Select(cn => cn.Name.Id).ToArray();

            var openItems = _dbContext.Set<OpenItem>().Where(o => nameIds.Contains(o.AccountDebtorName.Id)).ToArray();

            return namesWithCreditLimit.Where(n => HasExceededLimit(n, openItems));
        }

        static bool HasExceededLimit(CaseName caseName, IEnumerable<OpenItem> openItems)
        {
            var nameOpenItems = openItems.Where(o => o.AccountDebtorName == caseName.Name).ToArray();

            if(!nameOpenItems.Any()) return false;

            return caseName.Name.ClientDetail.CreditLimit <= nameOpenItems.Sum(o => o.LocalBalance);
        }
    }
}