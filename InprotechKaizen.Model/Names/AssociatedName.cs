using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Names
{
    [Table("ASSOCIATEDNAME")]
    public class AssociatedName
    {
        [Obsolete("For persistence only.")]
        public AssociatedName()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public AssociatedName(Name name, Name relatedName, string relationship, short sequence)
        {
            if(name == null) throw new ArgumentNullException("name");
            if(relatedName == null) throw new ArgumentNullException("relatedName");
            if(relationship == null) throw new ArgumentNullException("relationship");

            Name = name;
            Id = name.Id;
            Sequence = sequence;
            RelatedName = relatedName;
            RelatedNameId = relatedName.Id;
            Relationship = relationship;
        }

        [Key]
        [Column("NAMENO")]
        public int Id { get; set; }

        [Key]
        [MaxLength(3)]
        [Column("RELATIONSHIP")]
        public string Relationship { get; set; }

        [Key]
        [Column("SEQUENCE")]
        public short Sequence { get; set; }

        [Key]
        [Column("RELATEDNAME")]
        public int RelatedNameId { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryCode { get; protected set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        
        public string PropertyTypeId { get; protected set; }

        [Column("POSTALADDRESS")]
        public int? PostalAddressId { get; set; }

        [Column("CONTACT")]
        public int? ContactId { get; set; }

        public virtual Name Name { get; protected set; }

        public virtual Name RelatedName { get; protected set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; protected set; }

        public virtual Address PostalAddress { get; protected set; }

        public virtual TableCode JobTitle { get; protected set; }

        public virtual TableCode PositionCategory { get; protected set; }

        public void SetPostalAddress(Address address)
        {
            PostalAddress = address;
            PostalAddressId = PostalAddress == null ? (int?)null : PostalAddress.Id;
        }

        public void SetPropertyType(PropertyType propertyType)
        {
            PropertyType = propertyType;
            PropertyTypeId = PropertyType == null ? null : PropertyType.Code;
        }

        public void SetPositionCategory(TableCode positionCategory)
        {
            PositionCategory = positionCategory;
        }
    }
}