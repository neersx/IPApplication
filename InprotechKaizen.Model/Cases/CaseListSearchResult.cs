using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    
    [Table("CASELISTSEARCHRESULT")]
    public class CaseListSearchResult
    {
        public CaseListSearchResult()
        {
                
        }

        public CaseListSearchResult(int id, int priorArtId, int caseListId)
        {
            Id = id;
            PriorArtId = priorArtId;
            CaseListId = caseListId;
        }

        [Key]
        [Column("CASELISTPRIORARTID")]
        public int Id { get; set; }

        [Column("PRIORARTID")]
        public int PriorArtId { get; set; }

        [Column("CASELISTNO")]
        public int CaseListId { get; set; }

        public virtual CaseList CaseList { get; set; }
    }
}
