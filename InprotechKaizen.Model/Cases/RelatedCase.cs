using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.Linq;

namespace InprotechKaizen.Model.Cases
{
    [Table("RELATEDCASE")]
    public class RelatedCase
    {
        [Obsolete("For persistence only.")]
        public RelatedCase()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public RelatedCase(int caseId, string countryCode, string officialNumber, CaseRelation relation, int? relatedCaseId = null)
        {
            CaseId = caseId;
            CountryCode = countryCode;
            OfficialNumber = officialNumber;
            Relation = relation;
            Relationship = Relation.Relationship;
            RelatedCaseId = relatedCaseId;
        }

        public RelatedCase(int caseId, string relationship)
        {
            CaseId = caseId;
            Relationship = relationship;
        }

        public RelatedCase(int caseId, string relationship, string countryCode)
        {
            CaseId = caseId;
            CountryCode = countryCode;
            Relationship = relationship;
        }

        [Key]
        [Column("CASEID", Order = 0)]
        public int CaseId { get; protected set; }

        [Key]
        [Column("RELATIONSHIPNO", Order = 1)]
        public int RelationshipNo { get; set; }

        [MaxLength(3)]
        [Column("RELATIONSHIP")]
        public string Relationship { get; set; }

        [Column("RELATEDCASEID")]
        public int? RelatedCaseId { get; set; }

        [MaxLength(254)]
        [Column("TITLE")]
        public string Title { get; set; }

        [Column("CYCLE")]
        public short? Cycle { get; set; }

        [MaxLength(254)]
        [Column("CLASS")]
        public string Class { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; protected set; }

        [MaxLength(36)]
        [Column("OFFICIALNUMBER")]
        public string OfficialNumber { get; protected set; }

        [Column("PRIORITYDATE")]
        public DateTime? PriorityDate { get; set; }

        [Column("CURRENTSTATUS")]
        public int? CurrentStatus { get; set; }

        [Column("ACCEPTANCEDETAILS")]
        public string Notes { get; set; }

        [Column("AGENT")]
        public int? AgentId { get; set; }

        [Column("TRANSLATOR")]
        public int? TranslatorId { get; set; }

        [Column("RECORDALFLAGS")]
        public short? RecordalFlags { get; set; }

        [ForeignKey("CountryCode")]
        public virtual Country Country { get; protected set; }

        [ForeignKey("Relationship")]
        public virtual CaseRelation Relation { get; protected set; }
    }

    public static class RelatedCaseExtension
    {
        public static IQueryable<RelatedCase> ByRelationship(this IDbSet<RelatedCase> relatedCases, string relationship)
        {
            return relatedCases.Where(_ => _.Relationship == relationship);
        }
    }
}