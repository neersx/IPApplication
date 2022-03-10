using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Cases
{
    public class FilteredRowSecurityName
    {
        public AccessPermissionLevel? SecurityFlag { get; set; }

        public int NameNo { get; set; }
    }
}