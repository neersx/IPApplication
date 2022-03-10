using System;
using System.Collections.Generic;

namespace Inprotech.Web.Accounting
{
    /// <summary>
    /// TODO: POST-WIP-AND-BILLING-SILVERLIGHT-REMOVAL
    /// - for compatibility, should be rid of its dependencies at first opportunity
    /// </summary>
    public class ValidationResultInfo
    {
        public int ErrorCode { get; }
        public string Message { get; }
        public IEnumerable<string> SourceMemberNames { get; }
        public string StackTrace { get; }

        public ValidationResultInfo()
        {
        }

        public ValidationResultInfo(string message, IEnumerable<string> sourceMemberNames)
        {
            Message = message ?? throw new ArgumentNullException(nameof(message));
            SourceMemberNames = sourceMemberNames ?? throw new ArgumentNullException(nameof(sourceMemberNames));
        }

        public ValidationResultInfo(string message, int errorCode, string stackTrace, IEnumerable<string> sourceMemberNames)
        {
            Message = message ?? throw new ArgumentNullException(nameof(message));
            SourceMemberNames = sourceMemberNames ?? throw new ArgumentNullException(nameof(sourceMemberNames));
            ErrorCode = errorCode;
            StackTrace = stackTrace;
        }
    }
    
    public class ChangeSetEntry<T>
    {
        public bool IsItemDateWarningSuppressed {get; set;}

        public T Entity { get; set; }

        public IEnumerable<ValidationResultInfo> ValidationErrors { get; set; }
    }
}
