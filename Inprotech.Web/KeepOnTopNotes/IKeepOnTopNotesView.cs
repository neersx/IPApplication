using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Web.KeepOnTopNotes
{
    public interface IKeepOnTopNotesView
    {
        Task<IEnumerable<KotNotesItem>> GetKotNotesForCase(int caseId, string program);

        Task<IEnumerable<KotNotesItem>> GetKotNotesForName(int nameId, string program);
    }

    public class KotNotesItem
    {
        public string Note { get; set; }
        public string TextType { get; set; }
        public string CaseRef { get; set; }
        public string Name { get; set; }
        public string NameTypes { get; set; }
        public string BackgroundColor { get; set; }
        public bool Expanded { get; set; }
        public int? NameId { get; set; }
    }
}
