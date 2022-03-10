using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Web.Maintenance.Topics;

namespace Inprotech.Web.Cases.Maintenance
{
    public class CaseMaintenanceSaveModel : MaintenanceSaveModel
    {
        public int CaseKey { get; set; }
        public string Program { get; set; }
        public bool? IsPoliceImmediately { get; set; }
        public bool ForceUpdate { get; set; }
        public bool IgnoreSanityCheck { get; set; }
    }
}
