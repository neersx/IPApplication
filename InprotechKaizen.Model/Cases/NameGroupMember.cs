using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("GROUPMEMBERS")]
    public class NameGroupMember
    {
        [Obsolete("For Persistence Only")]
        public NameGroupMember()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameGroupMember(NameGroup nameGroup, NameType nameType)
        {
            if(nameGroup == null) throw new ArgumentNullException("nameGroup");
            if(nameType == null) throw new ArgumentNullException("nameType");

            NameGroupId = nameGroup.Id;
            NameTypeCode = nameType.NameTypeCode;

            NameGroup = nameGroup;
            NameType = nameType;
        }

        [Key]
        [Column("NAMEGROUP", Order = 1)]
        [ForeignKey("NameGroup")]
        public short NameGroupId { get; private set; }

        [Key]
        [MaxLength(3)]
        [Column("NAMETYPE", Order = 2)]
        [ForeignKey("NameType")]
        public string NameTypeCode { get; private set; }

        public virtual NameType NameType { get; protected set; }

        public virtual NameGroup NameGroup { get; protected set; }
    }
}