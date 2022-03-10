using System;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseViewEventsDueDateClientFilter
    {
        DateTime? MaxDueDateLimit();
    }

    class CaseViewEventsDueDateClientFilter : ICaseViewEventsDueDateClientFilter
    {
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControl;
        readonly Func<DateTime> _now;

        public CaseViewEventsDueDateClientFilter(ISecurityContext securityContext, ISiteControlReader siteControl, Func<DateTime> now)
        {
            _securityContext = securityContext;
            _siteControl = siteControl;
            _now = now;
        }

        public DateTime? MaxDueDateLimit()
        {
            if (!_securityContext.User.IsExternalUser) return null;

            var overDueDays = _siteControl.Read<int?>(SiteControls.ClientDueDates_OverdueDays);

            if (!overDueDays.HasValue)
                return null;

            return _now().Date.AddDays(-overDueDays.Value);
        }
    }
}