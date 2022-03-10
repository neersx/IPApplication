using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.Cases.Restrictions
{
    public interface ICaseNamesWithDebtorStatus
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "For")]
        IEnumerable<CaseNameRestriction> For(Case @case);
    }

    public class CaseNamesWithDebtorStatus : ICaseNamesWithDebtorStatus
    {
        readonly IRestrictableCaseNames _restrictableCaseNames;

        public CaseNamesWithDebtorStatus(IRestrictableCaseNames restrictableCaseNames)
        {
            if(restrictableCaseNames == null) throw new ArgumentNullException("restrictableCaseNames");

            _restrictableCaseNames = restrictableCaseNames;
        }

        public IEnumerable<CaseNameRestriction> For(Case @case)
        {
            if(@case == null) throw new ArgumentNullException("case");

            return _restrictableCaseNames.For(@case)
                                         .Where(cn => cn.Name.ClientDetail.DebtorStatus != null)
                                         .Select(cn => new CaseNameRestriction(cn, cn.Name.ClientDetail.DebtorStatus));
        }
    }
}