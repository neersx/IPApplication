using InprotechKaizen.Model.Cases;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDBASIS")]
    public class ValidBasis
    {
        [Obsolete("For persistence only.")]
        public ValidBasis()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidBasis(
            Country country,
            PropertyType propertyType,
            ApplicationBasis basis)
        {
            if(country == null) throw new ArgumentNullException(nameof(country));
            if (basis == null) throw new ArgumentNullException(nameof(basis));
            if(propertyType == null) throw new ArgumentNullException(nameof(propertyType));
           
            CountryId = country.Id;
            PropertyTypeId = propertyType.Code;
            BasisId = basis.Code;
            Country = country;
            PropertyType = propertyType;
            Basis = basis;
        }

        [Key]
        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [Key]
        [MaxLength(2)]
        [Column("BASIS")]
        public string BasisId { get; set; }

        [MaxLength(50)]
        [Column("BASISDESCRIPTION")]
        public string BasisDescription { get; set; }

        [Column("BASISDESCRIPTION_TID")]
        public int? BasisDescriptionTId { get; set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; protected set; }

        [ForeignKey("CountryId")]
        public virtual Country Country { get; protected set; }

        [ForeignKey("BasisId")]
        public virtual ApplicationBasis Basis { get; protected set; }
    }
}
