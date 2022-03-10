using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEVARIANT")]
    public class NameVariant
    {
        [Obsolete("For persistence only.")]
        public NameVariant()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameVariant(int id, string desc, PropertyType propertyType, Name name)
        {
            if(name == null) throw new ArgumentNullException("name");

            Id = id;
            NameVariantDesc = desc;

            Name = name;
            NameId = name.Id;

            if(propertyType == null) return;
            PropertyTypeId = propertyType.Code;
            PropertyType = propertyType;
        }

        [Key]
        [Column("NAMEVARIANTNO")]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(254)]
        [Column("NAMEVARIANT")]
        public string NameVariantDesc { get; set; }

        [MaxLength(50)]
        [Column("FIRSTNAMEVARIANT")]
        public string FirstNameVariant { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        [ForeignKey("PropertyType")]
        public string PropertyTypeId { get; protected set; }

        [Column("NAMENO")]
        public int NameId { get; set; }

        [ForeignKey("NameId")]
        public virtual Name Name { get; protected set; }

        public virtual PropertyType PropertyType { get; protected set; }
    }
}