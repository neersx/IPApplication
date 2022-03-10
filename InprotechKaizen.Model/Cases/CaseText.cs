using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASETEXT")]
    public class CaseText
    {
        [Obsolete("For persistence only.")]
        public CaseText()
        {

        }

        public CaseText(int caseId, string type, short? number, string @class)
        {
            CaseId = caseId;
            Type = type;
            Number = number;
            Class = @class;
        }

        [Key]
        [Column("CASEID", Order = 0)]
        public int CaseId { get; protected set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1721:PropertyNamesShouldNotMatchGetMethods")]
        [Key]
        [MaxLength(2)]
        [Column("TEXTTYPE", Order = 1)]
        public string Type { get; protected set; }

        [Key]
        [Column("TEXTNO", Order = 2)]
        public short? Number { get; protected set; }

        [MaxLength(100)]
        [Column("CLASS")]
        public string Class { get; set; }

        [MaxLength(254)]
        [Column("SHORTTEXT")]
        public string ShortText { get; set; }

        [Column("TEXT")]
        public string LongText { get; set; }

        [Column("LONGFLAG")]
        public decimal? IsLongText { get; set; }

        [Column("LANGUAGE")]
        public int? Language { get; set; }

        [Column("MODIFIEDDATE")]
        public DateTime? ModifiedDate { get; set; }
        
        [Column("SHORTTEXT_TID")]
        public int? ShortTextTId { get; set; }

        [Column("TEXT_TID")]
        public int? LongTextTId { get; set; }

        public virtual TextType TextType { get; set; }

        [NotMapped]
        public ClassFirstUse FirstUse { get; set; }

        public virtual TableCode LanguageValue { get; set; }

        [NotMapped]
        public string Text
        {
            get { return IsLongText == 1 ? LongText : ShortText; }
            set
            {
                if (value?.Length > 254)
                {
                    IsLongText = 1;
                    LongText = value;
                    return;
                }
                IsLongText = 0;
                ShortText = value;
            }
        }
    }
}
