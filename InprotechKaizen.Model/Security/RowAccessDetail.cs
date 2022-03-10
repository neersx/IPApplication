using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Security
{
    [Table("ROWACCESSDETAIL")]
    public class RowAccessDetail
    {
        [Obsolete("For persistence only.")]
        public RowAccessDetail()
        {
        }

        public RowAccessDetail(string accessName)
        {
            if(accessName == null) throw new ArgumentNullException("accessName");

            Name = accessName;
        }

        [Key]
        [MaxLength(30)]
        [Column("ACCESSNAME")]
        public string Name { get; private set; }

        [Key]
        [Column("SEQUENCENO")]
        public int SequenceNo { get; set; }

        [MaxLength(1)]
        [Column("RECORDTYPE")]
        public string AccessType { get; set; }

        [Column("CASETYPE")]
        public virtual CaseType CaseType { get; set; }

        [Column("PROPERTYTYPE")]
        public virtual PropertyType PropertyType { get; set; }

        [Column("SECURITYFLAG")]
        public short AccessLevel { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }

        [Column("CRM")]
        public bool? IsCrm { get; protected set; }

        [Column("OFFICE")]
        public virtual Office Office { get; set; }

        [Column("NAMETYPE")]
        public virtual NameType NameType { get; set; }
    }
}