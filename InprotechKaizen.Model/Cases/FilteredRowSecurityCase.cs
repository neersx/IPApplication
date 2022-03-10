using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Cases
{
    public class FilteredRowSecurityCase
    {
        public AccessPermissionLevel? SecurityFlag { get; set; }

        public int CaseId { get; set; }
    }

    public class FilteredRowSecurityCaseMultiOffice : FilteredRowSecurityCase
    {
    }
}