using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Documents;

namespace InprotechKaizen.Model.Cases
{
    [Table("NUMBERTYPES")]
    public class NumberType
    {
        [Obsolete("For persistence only.")]
        public NumberType()
        {
        }

        public NumberType(string numberTypeCode, string name, int? relatedEventId)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Number Type is required.");
            if(string.IsNullOrWhiteSpace(numberTypeCode)) throw new ArgumentException("A valid code is required.");

            Name = name;
            NumberTypeCode = numberTypeCode;
            RelatedEventId = relatedEventId;
        }

        public NumberType(int id, string numberTypeCode, string name, int? relatedEventId) : this (numberTypeCode, name, relatedEventId)
        {
            Id = id;
        }

        public NumberType(string numberTypeCode, string name, int? relatedEventId, bool issuedByIpOffice) : this(numberTypeCode, name, relatedEventId)
        {
            IssuedByIpOffice = issuedByIpOffice;
        }

        [Column("NUMBERTYPEID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Key]
        [Column("NUMBERTYPE")]
        [MaxLength(3)]
        public string NumberTypeCode { get; internal set; }

        [MaxLength(30)]
        [Column("DESCRIPTION")]
        public string Name { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? NameTId { get; set; }

        [Column("DISPLAYPRIORITY")]
        public short DisplayPriority { get; set; }

        [Column("RELATEDEVENTNO")]
        public int? RelatedEventId { get; set; }

        [ForeignKey("RelatedEventId")]
        public Events.Event RelatedEvent { get; set; }

        [Column("ISSUEDBYIPOFFICE")]
        public bool IssuedByIpOffice { get; set; }

        [Column("DOCITEMID")]
        public int? DocItemId { get; set; }

        [ForeignKey("DocItemId")]
        public DocItem DocItem { get; set; }
    }
}