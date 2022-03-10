using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Cases.AssignmentRecordal
{
    [Table("RECORDALAFFECTEDCASE")]
    public class RecordalAffectedCase
    {
        public RecordalAffectedCase()
        {

        }
        public RecordalAffectedCase(Case @case, RecordalType recordalType, Country country, string officialNumber, int recordalStepSeq, int seqNo, string status)
        {
            if (@case == null) throw new ArgumentNullException("case");
            if (recordalType == null) throw new ArgumentNullException("recordalStep");
            if (country == null) throw new ArgumentNullException("country");

            CaseId = @case.Id;
            CountryId = country.Id;
            RecordalTypeNo = recordalType.Id;
            RecordalStepSeq = recordalStepSeq;
            Status = status;
            SequenceNo = seqNo;
            OfficialNumber = officialNumber;
        }

        public RecordalAffectedCase(Case @case, Case relatedCase, int seqNo, RecordalType recordalType, int recordalStepSeq, string status)
        {
            if (@case == null) throw new ArgumentNullException("case");
            if (relatedCase == null) throw new ArgumentNullException("relatedCase");
            if (recordalType == null) throw new ArgumentNullException("recordalStep");

            CaseId = @case.Id;
            RecordalTypeNo = recordalType.Id;
            RecordalStepSeq = recordalStepSeq;
            Status = status;
            SequenceNo = seqNo;
            RelatedCaseId = relatedCase.Id;
        }

        [Key]
        [Column("CASEID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CaseId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int SequenceNo { get; set; }

        [Column("RELATEDCASEID")]
        public int? RelatedCaseId { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [MaxLength(36)]
        [Column("OFFICIALNUMBER")]
        public string OfficialNumber { get; set; }

        [Column("RECORDALTYPENO")]
        public int RecordalTypeNo { get; set; }

        [Column("RECORDALSTEPSEQ")]
        public int? RecordalStepSeq { get; set; }

        [Column("AGENTNO")]
        public int? AgentId { get; set; }

        [MaxLength(20)]
        [Column("STATUS")]
        public string Status { get; set; }

        [Column("REQUESTDATE")]
        public DateTime? RequestDate { get; set; }

        [Column("RECORDDATE")]
        public DateTime? RecordDate { get; set; }

        public virtual Case Case { get; set; }

        public virtual Case RelatedCase { get; set; }

        public virtual Country Country { get; set; }

        public virtual RecordalType RecordalType { get; set; }

        public virtual Name Agent { get; set; }
    }
}