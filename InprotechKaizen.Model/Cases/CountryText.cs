using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Cases
{
    [Table("COUNTRYTEXT")]
    public class CountryText
    {
        [Obsolete("For persistence only...")]
        public CountryText()
        {
        }

        public CountryText(string countryCode, TableCode textType, PropertyType propertyType)
        {
            if (countryCode == null) throw new ArgumentNullException("countryCode");
            if (textType == null) throw new ArgumentNullException("textType");

            CountryId = countryCode;
            TextType = textType;
            TextId = textType.Id;

            if (propertyType != null)
            {
                Property = propertyType;
                PropertyType = Property.Code;
            }
        }

        [Key]
        [MaxLength(3)]
        [Column("COUNTRYCODE", Order = 0)]
        public string CountryId { get; set; }

        [Key]
        [Column("TEXTID", Order = 1)]
        public int TextId { get; set; }

        [Key]
        [Column("SEQUENCE", Order = 2)]
        public short SequenceId { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyType{ get; set; }

        [Column("MODIFIEDDATE")]
        public DateTime? ModifiedDate { get; set; }

        [Column("LANGUAGE")]
        public int? Language { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("USEFLAG")]
        public int? UseFlag { get; set; }

        [Column("COUNTRYTEXT")]
        public string Text { get; set; }

        [ForeignKey("TextId")]
        public TableCode TextType { get; set; }

        [ForeignKey("PropertyType")]
        public PropertyType Property { get; set; }
    }
}
