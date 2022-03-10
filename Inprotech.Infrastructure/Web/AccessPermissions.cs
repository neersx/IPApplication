using System;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Infrastructure.Web
{
    public interface IAccessPermissions
    {
        object GetAccessPermissions();
    }

    public class AccessPermissions : IAccessPermissions
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISubjectSecurityProvider _subjectSecurity;
        readonly IWebPartSecurity _webPartSecurity;

        public AccessPermissions(ITaskSecurityProvider taskSecurityProvider, ISubjectSecurityProvider subjectSecurity, IWebPartSecurity webPartSecurity)
        {
            _taskSecurityProvider = taskSecurityProvider ?? throw new ArgumentNullException(nameof(taskSecurityProvider));
            _subjectSecurity = subjectSecurity;
            _webPartSecurity = webPartSecurity;
        }

        public object GetAccessPermissions()
        {
            return new
            {
                CanShowLinkforInprotechWeb = _taskSecurityProvider.HasAccessTo(ApplicationTask.ShowLinkstoWeb),
                CanViewWorkInProgress = _subjectSecurity.HasAccessToSubject(ApplicationSubject.WorkInProgressItems),
                CanViewReceivables = _subjectSecurity.HasAccessToSubject(ApplicationSubject.ReceivableItems),
                CanChangeMyPassword = _taskSecurityProvider.HasAccessTo(ApplicationTask.ChangeMyPassword),
                CanUpdateBatchEvent = _taskSecurityProvider.HasAccessTo(ApplicationTask.BatchEventUpdate),
                CanAccessQuickSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.QuickCaseSearch),
                CanViewRecentCases = _webPartSecurity.HasAccessToWebPart(ApplicationWebPart.MyCaseList) && _taskSecurityProvider.HasAccessTo(ApplicationTask.RunSavedCaseSearch),
                CanAccessTimeRecording = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTimeViaTimeRecording),
                CanMaintainCaseBillNarrative = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseBillNarrative)
            };
        }
    }
}