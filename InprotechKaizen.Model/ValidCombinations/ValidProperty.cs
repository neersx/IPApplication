using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDPROPERTY")]
    public class ValidProperty
    {
        [Key]
        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [MaxLength(50)]
        [Column("PROPERTYNAME")]
        public string PropertyName { get; set; }

        [Column("OFFSET")]
        public int? Offset { get; set; }

        [Column("CYCLEOFFSET")]
        public byte? CycleOffset { get; set; }

        [Column("ANNUITYTYPE")]
        public byte? AnnuityType { get; set; }

        [Column("PROPERTYNAME_TID")]
        public int? PropertyNameTId { get; set; }

        [ForeignKey("CountryId")]
        public virtual Country Country { get; set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; set; }
    }
}
