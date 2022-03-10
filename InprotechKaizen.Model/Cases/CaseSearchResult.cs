using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASESEARCHRESULT")]
    public class CaseSearchResult
    {
        [Obsolete("For persistance only.")]
        public CaseSearchResult()
        {
        }

        public CaseSearchResult(int caseId, int priorArtId, bool caseFirstLinkedTo)
        {
            PriorArtId = priorArtId;
            CaseId = caseId;
            CaseFirstLinkedTo = caseFirstLinkedTo;
            UpdateDate = DateTime.Now;
        }

        [Key]
        [Column("CASEPRIORARTID")]
        public int Id { get; set; }

        [Column("FAMILYPRIORARTID")]
        public int? FamilyPriorArtId { get; set; }
        
        [Column("NAMEPRIORARTID")]
        public int? NamePriorArtId { get;set; }

        [Column("CASELISTPRIORARTID")]
        public int? CaseListPriorArtId { get;set; }

        [Column("CASEID")]
        public int CaseId { get; set; }

        [Column("PRIORARTID")]
        public int PriorArtId { get; set; }

        [Column("UPDATEDDATE")]
        public DateTime UpdateDate { get; set; }
        
        [Column("CASEFIRSTLINKEDTO")]
        public bool? CaseFirstLinkedTo { get; set; }
        [Column("ISCASERELATIONSHIP")]
        public bool? IsCaseRelationship { get; set; }

        [Column("STATUS")]
        public int? StatusId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
        public virtual Case Case { get; set; }

        public virtual PriorArt.PriorArt PriorArt { get; set; }
    }
}