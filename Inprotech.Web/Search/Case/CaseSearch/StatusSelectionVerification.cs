using System;
using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search.CaseSupportData;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public interface IStatusSelectionVerification
    {
        StatusSelection Verify(StatusSelection selection);
    }

    public class StatusSelectionVerification : IStatusSelectionVerification
    {
        readonly ICaseStatuses _caseStatuses;
        readonly IRenewalStatuses _renewalStatuses;

        public StatusSelectionVerification(ICaseStatuses caseStatuses, IRenewalStatuses renewalStatuses)
        {
            if(caseStatuses == null) throw new ArgumentNullException("caseStatuses");
            if(renewalStatuses == null) throw new ArgumentNullException("renewalStatuses");
            _caseStatuses = caseStatuses;
            _renewalStatuses = renewalStatuses;
        }

        public StatusSelection Verify(StatusSelection selection)
        {
            selection = VerifyCaseStatus(selection);
            selection = VerifyRenewalStatus(selection);

            return selection;
        }

        StatusSelection VerifyCaseStatus(StatusSelection selection)
        {
            if(!selection.CaseStatuses.Any())
                return selection;

            var list = _caseStatuses.Get(
                                         null,
                                         false,
                                         selection.IsPending,
                                         selection.IsRegistered,
                                         selection.IsDead);

            selection.CaseStatuses = list.Where(a => selection.CaseStatuses.Any(b => b.Key == a.Key)).ToArray();

            return selection;
        }

        StatusSelection VerifyRenewalStatus(StatusSelection selection)
        {
            if(!selection.RenewalStatuses.Any())
                return selection;

            var list = _renewalStatuses.Get(
                                            null,
                                            selection.IsPending,
                                            selection.IsRegistered,
                                            selection.IsDead);

            selection.RenewalStatuses = list.Where(a => selection.RenewalStatuses.Any(b => b.Key == a.Key)).ToArray();

            return selection;
        }
    }
}