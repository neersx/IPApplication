using Inprotech.Web.Maintenance.Topics;

namespace Inprotech.Web.Names.Maintenance
{
    public class NameMaintenanceSaveModel : MaintenanceSaveModel
    {
        public int NameId { get; set; }
        public bool IgnoreSanityCheck { get; set; }
    }
}
