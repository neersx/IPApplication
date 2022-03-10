using InprotechKaizen.Model.Cases;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDRELATIONSHIPS")]
    public class ValidRelationship
    {
        public ValidRelationship()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidRelationship(
            Country country,
            PropertyType propertyType, CaseRelation relation)
        {
            Country = country ?? throw new ArgumentNullException(nameof(country));
            PropertyType = propertyType ?? throw new ArgumentNullException(nameof(propertyType));
            Relationship = relation ?? throw new ArgumentNullException(nameof(relation));

            CountryId = country.Id;
            PropertyTypeId = propertyType.Code;
            RelationshipCode = relation.Relationship;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ValidRelationship(
            Country country,
            PropertyType propertyType, CaseRelation relation, CaseRelation reciprocalRelation) : this (country, propertyType, relation)
        {
            ReciprocalRelationship = reciprocalRelation ?? throw new ArgumentNullException(nameof(reciprocalRelation));
            ReciprocalRelationshipCode = reciprocalRelation.Relationship;
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
        [MaxLength(3)]
        [Column("RELATIONSHIP")]
        public string RelationshipCode { get; set; }

        [MaxLength(3)]
        [Column("RECIPRELATIONSHIP")]
        public string ReciprocalRelationshipCode { get; set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; protected set; }

        [ForeignKey("CountryId")]
        public virtual Country Country { get; protected set; }

        [ForeignKey("RelationshipCode")]
        public virtual CaseRelation Relationship { get; protected set; }

        [ForeignKey("ReciprocalRelationshipCode")]
        public virtual CaseRelation ReciprocalRelationship { get; protected set; }
    }
}
