using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Cases
{
    public class FilteredRowAccessCase
    {
        public AccessPermissionLevel SecurityFlag { get; set; }

        public int CaseId { get; set; }
    }
}