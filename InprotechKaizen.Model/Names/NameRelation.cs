using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMERELATION")]
    public class NameRelation
    {
        [Obsolete("For persistance only.")]
        public NameRelation()
        {
        }

        public NameRelation(string relationshipCode, string relationDescription, string reverseDescription, decimal usedByNameType, bool? crmOnly, byte ethicalWall)
        {
            RelationshipCode = relationshipCode;
            RelationDescription = relationDescription;
            ReverseDescription = reverseDescription;
            UsedByNameType = usedByNameType;
            ShowFlag = 1;
            CrmOnly = crmOnly;
            EthicalWall = ethicalWall;
        }
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("RELATIONSHIP")]
        [MaxLength(3)]
        public string RelationshipCode { get; set; }
        
        [MaxLength(30)]
        [Column("RELATIONDESCR")]
        public string RelationDescription { get; set; }

        [Column("RELATIONDESCR_TID")]
        public int? RelationDescriptionTId { get; set; }

        [MaxLength(30)]
        [Column("REVERSEDESCR")]
        public string ReverseDescription { get; set; }

        [Column("REVERSEDESCR_TID")]
        public int? ReverseDescriptionTId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("SHOWFLAG")]
        public decimal ShowFlag { get; set; }

        [Column("USEDBYNAMETYPE")]
        public decimal UsedByNameType { get; set; }

        [Column("CRMONLY")]
        public bool? CrmOnly { get; set; }

        [Column("ETHICALWALL")]
        public byte EthicalWall { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        public bool UsedAsIndividual => Convert.ToBoolean((short) UsedByNameType & (short) NameRelationType.Individual);

        public bool UsedAsEmployee => Convert.ToBoolean((short) UsedByNameType & (short) NameRelationType.Employee);

        public bool UsedAsOrganisation => Convert.ToBoolean((short) UsedByNameType & (short) NameRelationType.Organisation);
        
    }
}