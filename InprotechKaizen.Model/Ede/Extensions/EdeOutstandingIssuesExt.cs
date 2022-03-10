using System;

namespace InprotechKaizen.Model.Ede.Extensions
{
    public static class EdeOutstandingIssuesExt
    {
        public static string IssueDescription(this EdeOutstandingIssues edeOutstandingIssues)
        {
            if (edeOutstandingIssues == null) throw new ArgumentNullException(nameof(edeOutstandingIssues));

            var standardIssue = (edeOutstandingIssues.StandardIssue.LongDescription ??
                                 edeOutstandingIssues.StandardIssue.ShortDescription).Trim();

            if(!string.IsNullOrWhiteSpace(standardIssue))
            {
                return standardIssue + Environment.NewLine + edeOutstandingIssues.Issue;
            }

            return edeOutstandingIssues.Issue;
        }
    }
}
