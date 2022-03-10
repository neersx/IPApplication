using InprotechKaizen.Model.Cases;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDSTATUS")]
    public class ValidStatus
    {
        public ValidStatus()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidStatus(
            Country country,
            PropertyType propertyType, CaseType caseType, Status status)
        {
            if(country == null) throw new ArgumentNullException("country");
            if(caseType == null) throw new ArgumentNullException("caseType");
            if(propertyType == null) throw new ArgumentNullException("propertyType");
            if (status == null) throw new ArgumentNullException("status");

            CountryId = country.Id;
            PropertyTypeId = propertyType.Code;
            CaseTypeId = caseType.Code;
            StatusCode = status.Id;
            Country = country;
            PropertyType = propertyType;
            CaseType = caseType;
            Status = status;
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
        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [Key]
        [Column("STATUSCODE")]
        public short StatusCode { get; set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; protected set; }

        [ForeignKey("CountryId")]
        public virtual Country Country { get; protected set; }

        [ForeignKey("CaseTypeId")]
        public virtual CaseType CaseType { get; protected set; }

        [ForeignKey("StatusCode")]
        public virtual Status Status { get; protected set; } 
    }
}
