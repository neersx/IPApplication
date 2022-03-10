using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    public enum CaseIndexSource : short
    {
        Irn = 1,
        Title = 2,
        Family = 3,
        CaseNameReferenceNumber = 4,
        OfficialNumbers = 5,
        CaseStem = 6,
        RelatedCaseOfficialNumber = 7
    }

    [Table("CASEINDEXES")]
    public class CaseIndexes
    {
        [Obsolete("For persistence only")]
        public CaseIndexes()
        {
        }

        public CaseIndexes(string genericIndex, int caseId, CaseIndexSource source)
        {
            GenericIndex = genericIndex;
            CaseId = caseId;
            Source = source;
        }

        [Column("GENERICINDEX", Order = 1)]
        [Key]
        [MaxLength(254)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public string GenericIndex { get; internal set; }

        [Column("CASEID", Order = 2)]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CaseId { get; internal set; }

        [Column("SOURCE", Order = 3)]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public CaseIndexSource Source { get; internal set; }
    }
}