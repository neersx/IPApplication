using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("PROTECTCODES")]
    public class ProtectCodes
    {
        [Obsolete("For persistence only.")]
        public ProtectCodes()
        {
        }

        public ProtectCodes(int id)
        {
            Id = id;
        }
        
        public ProtectCodes(string numberTypeId)
        {
            NumberTypeId = numberTypeId;
       }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("PROTECTKEY")]
        public int Id { get; set; }
       
        [Column("TABLECODE")]
        public int? TableCodeId { get; protected set; }

        [Column("TABLETYPE")]
        public short? TableTypeId { get; protected set; }

        [Column("EVENTNO")]
        public int? EventId { get; protected set; }

        [MaxLength(3)]
        [Column("CASERELATIONSHIP")]
        public string CaseRelationshipId { get; protected set; }

        [MaxLength(3)]
        [Column("NAMERELATIONSHIP")]
        public string NameRelationshipId { get; protected set; }

        [MaxLength(3)]
        [Column("NUMBERTYPE")]
        public string NumberTypeId { get; protected set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; protected set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeId { get; protected set; }

        [MaxLength(4)]
        [Column("ADJUSTMENT")]
        public string AdjustmentId { get; protected set; }

        [MaxLength(2)]
        [Column("TEXTTYPE")]
        public string TextTypeId { get; set; }

        [MaxLength(20)]
        [Column("FAMILY")]
        public string FamilyId { get; protected set; }

    }
}