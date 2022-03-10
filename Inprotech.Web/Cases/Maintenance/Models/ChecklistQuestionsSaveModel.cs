using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Cases.Maintenance.Models
{
    public class ChecklistQuestionsSaveModel
    {
        public ChecklistQuestionData[] Rows { get; set; }
        public int ChecklistCriteriaKey { get; set; }
        public short ChecklistTypeId { get; set; }
        public ChecklistDocuments[] GeneralDocs { get; set; }
        public bool ShowRegenerationDialog { get; set; }
    }
}
