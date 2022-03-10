using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMETYPECLASSIFICATION ")]
    public class NameTypeClassification
    {
        [Obsolete("For persistence only.")]
        public NameTypeClassification()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameTypeClassification(Name name, NameType nameType)
        {
            if(name == null) throw new ArgumentNullException("name");
            if(nameType == null) throw new ArgumentNullException("nameType");

            Name = name;
            NameId = name.Id;

            NameType = nameType;
            NameTypeId = nameType.NameTypeCode;
        }

        [Key]
        [Column("NAMENO", Order = 1)]
        public int NameId { get; set; }

        [Key]
        [MaxLength(3)]
        [Column("NAMETYPE", Order = 2)]
        public string NameTypeId { get; set; }

        [Column("ALLOW")]
        public int? IsAllowed { get; set; }

        public virtual Name Name { get; protected set; }

        public virtual NameType NameType { get; protected set; }
    }
}