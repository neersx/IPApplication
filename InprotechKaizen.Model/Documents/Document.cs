using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Documents
{
    [Table("LETTER")]
    public class Document
    {
        [Obsolete("For persistence only.")]
        public Document()
        {
        }

        public Document(string name, string code)
        {
            Name = name;
            Code = code;
        }

        public Document(short id, string name, short documentType)
        {
            Id = id;
            Name = name;
            DocumentType = documentType;
        }

        public Document(short id, string name, string code, short documentType)
        {
            Id = id;
            Name = name;
            DocumentType = documentType;
            Code = code;
        }

        public Document(short id, string name, short documentType, string countryCode)
        {
            Id = id;
            Name = name;
            DocumentType = documentType;
            CountryCode = countryCode;
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("LETTERNO")]
        public short Id { get; set; }

        [MaxLength(254)]
        [Column("LETTERNAME")]
        public string Name { get; internal set; }

        [Column("LETTERNAME_TID")]
        public int? NameTId { get; protected set; }

        [MaxLength(10)]
        [Column("DOCUMENTCODE")]
        public string Code { get; protected set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; protected set; }

        [MaxLength(254)]
        [Column("MACRO")]
        public string Template { get; internal set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyType { get; set; }

        [Column("DOCUMENTTYPE")]
        public short DocumentType { get; internal set; }

        [Column("USEDBY")]
        public int ConsumersMask { get; set; }

        [Column("HOLDFLAG")]
        public decimal HoldFlag { get; set; }

        [Column("DELIVERYID")]
        public short? DeliveryMethodId { get; set; }

        [Column("DELIVERLETTER")]
        public short? DeliverLetterId { get; set; }

        [Column("FORPRIMECASESONLY")]
        public bool IsForPrimeCasesOnly { get; set; }

        [Column("CORRESPONDTYPE")]
        public short? CorrespondType { get; set; }

        [MaxLength(40)]
        [Column("DOCITEMMAILBOX")]
        public string DocItemMailbox { get; set; }

        [MaxLength(40)]
        [Column("DOCITEMSUBJECT")]
        public string DocItemSubject { get; set; }

        [MaxLength(40)]
        [Column("DOCITEMBODY")]
        public string DocItemBody { get; set; }

        [Column("ADDATTACHMENTFLAG")]
        public bool? AddAttachment { get; set; }

        [Column("ACTIVITYTYPE")]
        public int? ActivityType { get; set; }

        [Column("ACTIVITYCATEGORY")]
        public int? ActivityCategory { get; set; }
    }
}